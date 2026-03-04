import 'dart:developer' show log;

import 'wind_api_client.dart';
import '../../features/wind_dome/models/dome_constants.dart';
import '../../features/wind_dome/models/dome_wind_field.dart';
import '../../features/wind_dome/models/dome_wind_layer.dart';
import '../../features/wind_dome/models/dome_wind_profile.dart';

/// Fetches and caches dome wind data from the OGC EDR API.
///
/// Wraps [WindApiClient] to fetch time-series wind data at 3 pressure levels
/// (surface, 850hPa, 700hPa) and assembles them into a [DomeWindProfile].
///
/// When [radiusMeters] >= [DomeConstants.gridFetchThresholdMeters] (15km),
/// uses spatial grid fetching via [fetchWindGridSeries]. Otherwise uses
/// point-based fetching via [fetchPointWindSeries].
///
/// Cache is **static** so it survives fetcher recreation across provider
/// dispose/rebuild cycles. Cache key includes grid/point distinction to
/// prevent stale data when switching dome sizes.
///
/// Pattern follows [CachedWindDataSource]: constructor-injected client
/// for testability.
class DomeWindFetcher {
  final WindApiClient _apiClient;

  /// Cache: stores the most recent profile.
  /// Static to survive provider lifecycle (dispose/rebuild).
  static DomeWindProfile? _cached;
  static String? _cachedKey;
  static DateTime? _cachedAt;

  /// Cache TTL: 10 minutes.
  static const _cacheTtl = Duration(minutes: 10);

  /// Pressure levels to fetch and their corresponding altitudes.
  /// Format: (pressureLevel for API, altitudeMeters for DomeWindLayer).
  static const _levelMapping = [
    (0, 10.0),      // Surface (10m AGL)
    (850, 1500.0),   // 850 hPa (~1500m)
    (700, 3000.0),   // 700 hPa (~3000m)
  ];

  /// Creates a DomeWindFetcher with the given API client.
  DomeWindFetcher({required WindApiClient apiClient})
      : _apiClient = apiClient;

  /// Fetches a 72-hour wind profile for the given location.
  ///
  /// When [radiusMeters] >= [DomeConstants.gridFetchThresholdMeters],
  /// fetches spatial grid data. Otherwise fetches point data.
  ///
  /// Returns cached data if available and fresh. Otherwise fetches
  /// 3 pressure levels in parallel via [Future.wait], assembles into
  /// a [DomeWindProfile], and caches the result.
  ///
  /// On all-fail: returns a zero-wind profile (graceful degradation).
  Future<DomeWindProfile> fetch(
    double lat,
    double lng, {
    double radiusMeters = 1000.0,
  }) async {
    final isGrid =
        radiusMeters >= DomeConstants.gridFetchThresholdMeters;
    final radiusKey = (radiusMeters / 1000).toStringAsFixed(1);
    final key =
        'dome_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}'
        '_${isGrid ? 'grid' : 'point'}_r${radiusKey}km';

    // Check cache
    if (_cachedKey == key &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cached!;
    }

    DomeWindProfile profile;
    if (isGrid) {
      profile = await _fetchGrid(lat, lng, radiusMeters);
    } else {
      profile = await _fetchPoint(lat, lng);
    }

    // Cache result
    _cached = profile;
    _cachedKey = key;
    _cachedAt = DateTime.now();

    return profile;
  }

  /// Fetches point-based wind data (existing behavior).
  Future<DomeWindProfile> _fetchPoint(double lat, double lng) async {
    try {
      // Fetch 3 pressure levels in parallel
      final seriesList = await Future.wait(
        _levelMapping.map(
          (entry) => _apiClient.fetchPointWindSeries(
            lat: lat,
            lng: lng,
            pressureLevel: entry.$1,
            hours: 72,
          ),
        ),
      );

      log('DomeWindFetcher: ${seriesList[0].length} surface, '
          '${seriesList[1].length} 850hPa, '
          '${seriesList[2].length} 700hPa timesteps',
          name: 'DomeWindFetcher');

      // Determine the max number of timesteps across all levels
      int maxSteps = 0;
      for (final series in seriesList) {
        if (series.length > maxSteps) maxSteps = series.length;
      }

      if (maxSteps == 0) {
        // All APIs returned empty -- degrade to zero wind
        return _zeroProfile(lat, lng);
      }

      // Assemble: zip 3 series by time index into DomeWindFields
      final hourlyFields = <DomeWindField>[];
      for (int t = 0; t < maxSteps; t++) {
        final layers = <DomeWindLayer>[];
        for (int lvl = 0; lvl < _levelMapping.length; lvl++) {
          final series = seriesList[lvl];
          if (t < series.length) {
            layers.add(DomeWindLayer(
              altitudeMeters: _levelMapping[lvl].$2,
              u: series[t].u,
              v: series[t].v,
            ));
          } else {
            // Pad with zero if this level has fewer timesteps
            layers.add(DomeWindLayer(
              altitudeMeters: _levelMapping[lvl].$2,
              u: 0,
              v: 0,
            ));
          }
        }

        // Sort layers by altitude ascending
        layers.sort((a, b) => a.altitudeMeters.compareTo(b.altitudeMeters));

        hourlyFields.add(DomeWindField(
          validTime: seriesList
                  .where((s) => s.length > t)
                  .firstOrNull
                  ?[t]
                  .time ??
              DateTime.now().toUtc().add(Duration(hours: t)),
          layers: layers,
        ));
      }

      if (hourlyFields.length > 1) {
        final first = hourlyFields.first.layers.first;
        final last = hourlyFields.last.layers.first;
        log('DomeWindFetcher: hour0 u=${first.u.toStringAsFixed(2)} v=${first.v.toStringAsFixed(2)}, '
            'hourN u=${last.u.toStringAsFixed(2)} v=${last.v.toStringAsFixed(2)}',
            name: 'DomeWindFetcher');
      }

      return DomeWindProfile(
        hourly: hourlyFields,
        fetchedAt: DateTime.now(),
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return _zeroProfile(lat, lng);
    }
  }

  /// Fetches grid-based wind data for large dome sizes.
  ///
  /// Calls [WindApiClient.fetchWindGridSeries] for each pressure level
  /// in parallel, then assembles into a [DomeWindProfile] where each
  /// [DomeWindLayer] carries a [WindField] grid for spatial interpolation.
  ///
  /// On grid fetch failure, falls back to point-based data.
  Future<DomeWindProfile> _fetchGrid(
    double lat,
    double lng,
    double radiusMeters,
  ) async {
    final radiusKm = radiusMeters / 1000.0;
    // Use the base metersPerRenderUnit that matches the screen's geometry.
    // The screen scales dome radius (computedDomeR = size / baseRate), keeping
    // the base rate constant. The field must use the same rate.
    final metersPerRenderUnit = DomeConstants.metersPerRenderUnit;

    try {
      // Fetch 3 pressure levels in parallel (grid time-series)
      final gridSeriesList = await Future.wait(
        _levelMapping.map(
          (entry) => _apiClient.fetchWindGridSeries(
            lat: lat,
            lng: lng,
            radiusKm: radiusKm,
            pressureLevel: entry.$1,
            hours: 72,
          ),
        ),
      );

      log('DomeWindFetcher grid: ${gridSeriesList[0].length} surface, '
          '${gridSeriesList[1].length} 850hPa, '
          '${gridSeriesList[2].length} 700hPa timesteps',
          name: 'DomeWindFetcher');

      // Determine the max number of timesteps across all levels
      int maxSteps = 0;
      for (final series in gridSeriesList) {
        if (series.length > maxSteps) maxSteps = series.length;
      }

      if (maxSteps == 0) {
        // Grid returned empty -- fall back to point
        return _fetchPoint(lat, lng);
      }

      // Assemble: zip 3 grid series by time index into DomeWindFields
      final hourlyFields = <DomeWindField>[];
      for (int t = 0; t < maxSteps; t++) {
        final layers = <DomeWindLayer>[];
        for (int lvl = 0; lvl < _levelMapping.length; lvl++) {
          final series = gridSeriesList[lvl];
          if (t < series.length) {
            final grid = series[t].grid;
            final center = grid.centerWind();
            layers.add(DomeWindLayer(
              altitudeMeters: _levelMapping[lvl].$2,
              u: center.u,
              v: center.v,
              grid: grid,
            ));
          } else {
            // Pad with zero if this level has fewer timesteps
            layers.add(DomeWindLayer(
              altitudeMeters: _levelMapping[lvl].$2,
              u: 0,
              v: 0,
            ));
          }
        }

        // Sort layers by altitude ascending
        layers.sort((a, b) => a.altitudeMeters.compareTo(b.altitudeMeters));

        hourlyFields.add(DomeWindField(
          validTime: gridSeriesList
                  .where((s) => s.length > t)
                  .firstOrNull
                  ?[t]
                  .time ??
              DateTime.now().toUtc().add(Duration(hours: t)),
          layers: layers,
          centerLat: lat,
          centerLng: lng,
          metersPerRenderUnit: metersPerRenderUnit,
        ));
      }

      // Log center wind from grid data for on-device debugging.
      // Compares grid center with the scalar (u, v) to verify consistency.
      if (hourlyFields.isNotEmpty) {
        final first = hourlyFields.first;
        for (final layer in first.layers) {
          final gridCenter = layer.grid?.centerWind();
          log('DomeWindFetcher grid center: ${layer.altitudeMeters}m '
              'scalar=(${layer.u.toStringAsFixed(2)}, ${layer.v.toStringAsFixed(2)}) '
              'grid=${gridCenter != null ? "(${gridCenter.u.toStringAsFixed(2)}, ${gridCenter.v.toStringAsFixed(2)})" : "none"}',
              name: 'DomeWindFetcher');
        }
      }

      return DomeWindProfile(
        hourly: hourlyFields,
        fetchedAt: DateTime.now(),
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      log('DomeWindFetcher: grid fetch failed ($e), falling back to point',
          name: 'DomeWindFetcher');
      return _fetchPoint(lat, lng);
    }
  }

  /// Creates a zero-wind profile for graceful degradation.
  DomeWindProfile _zeroProfile(double lat, double lng) {
    final now = DateTime.now().toUtc();
    return DomeWindProfile(
      hourly: List.generate(
        72,
        (i) => DomeWindField.zero(
          validTime: now.add(Duration(hours: i)),
        ),
      ),
      fetchedAt: now,
      lat: lat,
      lng: lng,
    );
  }

  /// Clears the static cache. Primarily for testing.
  static void clearCache() {
    _cached = null;
    _cachedKey = null;
    _cachedAt = null;
  }
}
