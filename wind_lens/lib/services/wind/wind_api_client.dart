import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'wind_api_constants.dart';
import 'wind_models.dart';

/// Shared API client for OGC EDR wind data.
///
/// Handles HTTP requests and response parsing for both Shyft (primary)
/// and Folkweather (fallback) weather APIs. Designed as a reusable
/// service layer:
///
/// - [OgcEdrWindDataSource] uses [fetchPointWind] for single-point queries
/// - Future DomeWindFetcher will use [fetchWindGrid] for spatial grids
///
/// Constructor accepts an optional [http.Client] for testability.
/// Tests inject a mock client; production uses the default.
///
/// Graceful degradation: if both APIs fail, methods return zero values
/// instead of throwing. The caller constructs valid (but zero-wind)
/// domain objects so the app continues running.
class WindApiClient {
  final http.Client _client;

  /// Creates a WindApiClient.
  ///
  /// If [client] is null, creates a default [http.Client] that will be
  /// closed on [dispose]. If provided, the caller is responsible for
  /// closing it (unless [dispose] is called).
  WindApiClient({http.Client? client})
      : _client = client ?? http.Client();

  // ─── Point Wind Query ────────────────────────────────────────

  /// Fetches wind at a single geographic point.
  ///
  /// Tries Shyft first, falls back to Folkweather on failure.
  /// Returns `(u, v, source)` where source is 'shyft', 'folkweather',
  /// or 'none' if both APIs fail.
  ///
  /// [pressureLevel]: 0 for surface (10m AGL), otherwise hPa (e.g., 850, 300).
  ///
  /// On both-APIs-fail, returns `(0.0, 0.0, 'none')` instead of throwing.
  Future<(double u, double v, String source)> fetchPointWind({
    required double lat,
    required double lng,
    required int pressureLevel,
  }) async {
    // Try Shyft primary
    try {
      final (u, v) = await _fetchShyftPoint(lat, lng, pressureLevel);
      return (u, v, 'shyft');
    } catch (_) {
      // Fall through to Folkweather
    }

    // Try Folkweather fallback
    try {
      final (u, v) = await _fetchFolkPoint(lat, lng, pressureLevel);
      return (u, v, 'folkweather');
    } catch (_) {
      // Both APIs failed
    }

    return (0.0, 0.0, 'none');
  }

  // ─── Wind Grid Query ─────────────────────────────────────────

  /// Fetches a wind grid around a geographic point.
  ///
  /// Returns a [WindField] with bilinear interpolation support.
  /// Tries Shyft first, falls back to Folkweather.
  ///
  /// [radiusKm]: Half-width of the bounding box in kilometers.
  /// [pressureLevel]: 0 for surface, otherwise hPa.
  ///
  /// Throws on both-APIs-fail (grid queries are for Wind Dome which
  /// requires actual data, unlike the AR view which degrades gracefully).
  Future<WindField> fetchWindGrid({
    required double lat,
    required double lng,
    double radiusKm = 40,
    required int pressureLevel,
  }) async {
    final bbox = _makeBbox(lat, lng, radiusKm);
    final poly = _bboxToPoly(bbox);
    final encodedPoly = Uri.encodeComponent(poly);

    // Try Shyft primary
    try {
      return await _fetchShyftArea(encodedPoly, pressureLevel);
    } catch (_) {
      // Fall through to Folkweather
    }

    // Folkweather fallback
    return _fetchFolkArea(encodedPoly, pressureLevel);
  }

  // ─── Shyft Point Methods ──────────────────────────────────────

  Future<(double, double)> _fetchShyftPoint(
    double lat,
    double lng,
    int pressureLevel,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.shyftSurfaceCollection
        : WindApiConstants.shyftIsobaricCollection;

    final coordsParam = 'POINT($lng $lat)';

    final queryParams = <String, String>{
      'coords': coordsParam,
      'parameter-name':
          '${WindApiConstants.shyftUParam},${WindApiConstants.shyftVParam}',
      'apikey': WindApiConstants.shyftApiKey,
      'f': WindApiConstants.shyftPositionFormat,
      'datetime': _nearestHourUtc(),
    };

    // Add z parameter for isobaric levels (not for surface)
    if (pressureLevel > 0) {
      queryParams['z'] = pressureLevel.toString();
    }

    final uri = Uri.parse(
      '${WindApiConstants.shyftBaseUrl}/$collection/position',
    ).replace(queryParameters: queryParams);

    final response =
        await _client.get(uri).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Shyft HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseShyftPositionResponse(json);
  }

  /// Parses Shyft CoverageCollection position response.
  ///
  /// Shyft returns separate Coverage objects for U and V within a
  /// CoverageCollection. We iterate through coverages to find each
  /// parameter by name.
  (double, double) _parseShyftPositionResponse(Map<String, dynamic> json) {
    final coverages = json['coverages'] as List<dynamic>?;
    if (coverages == null || coverages.isEmpty) {
      throw Exception('Shyft: missing or empty coverages');
    }

    double? u;
    double? v;

    for (final coverage in coverages) {
      final ranges = coverage['ranges'] as Map<String, dynamic>?;
      if (ranges == null) continue;

      if (ranges.containsKey(WindApiConstants.shyftUParam)) {
        final values = ranges[WindApiConstants.shyftUParam]['values'] as List?;
        if (values != null && values.isNotEmpty) {
          u = (values[0] as num).toDouble();
        }
      }
      if (ranges.containsKey(WindApiConstants.shyftVParam)) {
        final values = ranges[WindApiConstants.shyftVParam]['values'] as List?;
        if (values != null && values.isNotEmpty) {
          v = (values[0] as num).toDouble();
        }
      }
    }

    if (u == null || v == null) {
      throw Exception('Shyft: could not extract U/V from coverages');
    }

    return (u, v);
  }

  // ─── Folkweather Point Methods ─────────────────────────────────

  Future<(double, double)> _fetchFolkPoint(
    double lat,
    double lng,
    int pressureLevel,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.folkSurfaceCollection
        : _folkCollection(pressureLevel);

    final coordsParam = 'POINT($lng $lat)';

    final queryParams = <String, String>{
      'coords': coordsParam,
      'parameter-name':
          '${WindApiConstants.folkUParam},${WindApiConstants.folkVParam}',
      'f': WindApiConstants.folkFormat,
    };

    // Surface uses z=10 (10m AGL), isobaric uses the pressure level
    if (pressureLevel == 0) {
      queryParams['z'] = '10';
    } else {
      queryParams['z'] = pressureLevel.toString();
    }

    final uri = Uri.parse(
      '${WindApiConstants.folkBaseUrl}/$collection/position',
    ).replace(queryParameters: queryParams);

    final response =
        await _client.get(uri).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Folkweather HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseFolkPositionResponse(json);
  }

  /// Parses Folkweather single Coverage position response.
  ///
  /// Folkweather returns both UGRD and VGRD in the same Coverage's
  /// ranges map.
  (double, double) _parseFolkPositionResponse(Map<String, dynamic> json) {
    final ranges = json['ranges'] as Map<String, dynamic>?;
    if (ranges == null) {
      throw Exception('Folkweather: missing ranges');
    }

    final uValues =
        (ranges[WindApiConstants.folkUParam] as Map<String, dynamic>?)?['values']
            as List?;
    final vValues =
        (ranges[WindApiConstants.folkVParam] as Map<String, dynamic>?)?['values']
            as List?;

    if (uValues == null ||
        uValues.isEmpty ||
        vValues == null ||
        vValues.isEmpty) {
      throw Exception('Folkweather: missing UGRD/VGRD values');
    }

    return (
      (uValues[0] as num).toDouble(),
      (vValues[0] as num).toDouble(),
    );
  }

  // ─── Shyft Area Methods ───────────────────────────────────────

  Future<WindField> _fetchShyftArea(
    String encodedPoly,
    int pressureLevel,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.shyftSurfaceCollection
        : WindApiConstants.shyftIsobaricCollection;

    var url = '${WindApiConstants.shyftBaseUrl}/$collection/area'
        '?coords=$encodedPoly'
        '&parameter-name=${WindApiConstants.shyftUParam},${WindApiConstants.shyftVParam}'
        '&datetime=${_nearestHourUtc()}'
        '&apikey=${WindApiConstants.shyftApiKey}'
        '&f=${WindApiConstants.shyftAreaFormat}';

    if (pressureLevel > 0) {
      url += '&z=$pressureLevel';
    }

    final response =
        await _client.get(Uri.parse(url)).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Shyft area HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseShyftMultiPoint(json, 'Shyft ${pressureLevel == 0 ? 'surface' : '${pressureLevel}hPa'}');
  }

  /// Parses Shyft CoverageJSON_MultiPointSeries format.
  ///
  /// The composite axis contains `[longitude, latitude, pressure_level]`
  /// tuples. We extract unique sorted x/y values, then reindex the
  /// U/V arrays into row-major grid order.
  WindField _parseShyftMultiPoint(Map<String, dynamic> json, String source) {
    final composites =
        (json['domain']['axes']['composite']['values'] as List)
            .map((c) => (c as List).cast<num>())
            .toList();

    if (composites.isEmpty) throw Exception('Shyft: empty composite axis');

    final rawUs =
        (json['ranges'][WindApiConstants.shyftUParam]['values'] as List)
            .map((v) => (v as num).toDouble())
            .toList();
    final rawVs =
        (json['ranges'][WindApiConstants.shyftVParam]['values'] as List)
            .map((v) => (v as num).toDouble())
            .toList();

    // Extract unique sorted grid coordinates
    final xSet =
        composites.map((c) => c[0].toDouble()).toSet().toList()..sort();
    final ySet =
        composites.map((c) => c[1].toDouble()).toSet().toList()..sort();

    // Map composite-ordered values to row-major grid [row * width + col]
    final gridU = List<double>.filled(xSet.length * ySet.length, 0.0);
    final gridV = List<double>.filled(xSet.length * ySet.length, 0.0);

    for (int i = 0; i < composites.length; i++) {
      final col = xSet.indexOf(composites[i][0].toDouble());
      final row = ySet.indexOf(composites[i][1].toDouble());
      final idx = row * xSet.length + col;
      gridU[idx] = rawUs[i];
      gridV[idx] = rawVs[i];
    }

    return WindField(
      xs: xSet,
      ys: ySet,
      us: gridU,
      vs: gridV,
      source: source,
    );
  }

  // ─── Folkweather Area Methods ──────────────────────────────────

  Future<WindField> _fetchFolkArea(
    String encodedPoly,
    int pressureLevel,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.folkSurfaceCollection
        : _folkCollection(pressureLevel);

    var url = '${WindApiConstants.folkBaseUrl}/$collection/area'
        '?coords=$encodedPoly'
        '&parameter-name=${WindApiConstants.folkUParam},${WindApiConstants.folkVParam}'
        '&f=${WindApiConstants.folkFormat}';

    if (pressureLevel == 0) {
      url += '&z=10';
    } else {
      url += '&z=$pressureLevel';
    }

    final response =
        await _client.get(Uri.parse(url)).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Folkweather area HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseFolkArea(
      json,
      'Folkweather ${pressureLevel == 0 ? 'surface' : '${pressureLevel}hPa'}',
    );
  }

  /// Parses Folkweather CoverageJSON area format.
  ///
  /// Standard x/y axes with row-major values.
  /// Longitudes are in 0-360 format and must be normalized to -180/180.
  /// Null values (HRRR outside CONUS) are replaced with 0.0.
  WindField _parseFolkArea(Map<String, dynamic> json, String source) {
    final axes = json['domain']['axes'] as Map<String, dynamic>;
    List<double> xs = (axes['x']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final ys = (axes['y']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();

    // Convert 0-360 longitude to -180/180
    xs = xs.map((x) => x > 180 ? x - 360 : x).toList();

    final us = (json['ranges'][WindApiConstants.folkUParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();
    final vs = (json['ranges'][WindApiConstants.folkVParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();

    return WindField(xs: xs, ys: ys, us: us, vs: vs, source: source);
  }

  // ─── Helpers ──────────────────────────────────────────────────

  /// Returns the nearest hour in UTC as ISO 8601 string.
  ///
  /// Rounds to the nearest hour. Used to pin Shyft queries to a
  /// single forecast timestep (without this, Shyft returns 180+
  /// timesteps worth of data).
  String _nearestHourUtc() {
    final now = DateTime.now().toUtc();
    final rounded = now.minute >= 30
        ? DateTime.utc(now.year, now.month, now.day, now.hour + 1)
        : DateTime.utc(now.year, now.month, now.day, now.hour);
    return '${rounded.toIso8601String().split('.')[0]}Z';
  }

  /// Selects the correct Folkweather collection for a given pressure level.
  ///
  /// Routes 850/925/1000 hPa to HRRR (which has those levels at 3km
  /// resolution). All other levels go to GFS.
  String _folkCollection(int level) {
    return WindApiConstants.folkHrrrLevels.contains(level)
        ? WindApiConstants.folkHrrrIsobaricCollection
        : WindApiConstants.folkGfsIsobaricCollection;
  }

  /// Builds a bounding box from a center point and radius.
  List<double> _makeBbox(double lat, double lng, double radiusKm) {
    final dLat = radiusKm / 111.32;
    final dLng = radiusKm / (111.32 * cos(lat * pi / 180));
    return [lng - dLng, lat - dLat, lng + dLng, lat + dLat];
  }

  /// Converts a bounding box to a WKT POLYGON string.
  String _bboxToPoly(List<double> bbox) {
    final [minLng, minLat, maxLng, maxLat] = bbox;
    return 'POLYGON(('
        '$minLng $minLat,'
        '$minLng $maxLat,'
        '$maxLng $maxLat,'
        '$maxLng $minLat,'
        '$minLng $minLat'
        '))';
  }

  /// Closes the underlying HTTP client.
  ///
  /// Should be called when the client is no longer needed (e.g., via
  /// `ref.onDispose()` in the provider).
  void dispose() {
    _client.close();
  }
}
