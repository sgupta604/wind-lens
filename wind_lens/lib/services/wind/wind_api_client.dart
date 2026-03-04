import 'dart:convert';
import 'dart:developer' show log;
import 'dart:math' hide log;

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

  // ─── Wind Grid Time-Series Query ─────────────────────────────

  /// Fetches a time series of wind grids around a geographic point.
  ///
  /// Returns a list of [({DateTime time, WindField grid})] for [hours]
  /// forecast hours. Tries area + datetime range on Shyft first, then
  /// Folkweather. If both time-series area queries fail, falls back to
  /// a single-timestep area query via [fetchWindGrid].
  ///
  /// [radiusKm]: Half-width of the bounding box in kilometers.
  /// [pressureLevel]: 0 for surface, otherwise hPa.
  ///
  /// Throws on total failure (both APIs fail, including single-timestep
  /// fallback).
  Future<List<({DateTime time, WindField grid})>> fetchWindGridSeries({
    required double lat,
    required double lng,
    required double radiusKm,
    required int pressureLevel,
    int hours = 72,
  }) async {
    final bbox = _makeBbox(lat, lng, radiusKm);
    final poly = _bboxToPoly(bbox);
    final encodedPoly = Uri.encodeComponent(poly);
    final datetimeRange = _dateTimeRangeUtc(hours);

    // Try Shyft area time-series
    try {
      final results = await _fetchShyftAreaSeries(
        encodedPoly, pressureLevel, datetimeRange,
      );
      log('fetchWindGridSeries: Shyft area success for ${pressureLevel}hPa '
          '(${results.length} timesteps)',
          name: 'WindApiClient');
      return results;
    } catch (_) {
      // Fall through to Folkweather
    }

    // Try Folkweather area time-series
    try {
      final results = await _fetchFolkAreaSeries(
        encodedPoly, pressureLevel, datetimeRange,
      );
      log('fetchWindGridSeries: Folkweather area success for ${pressureLevel}hPa '
          '(${results.length} timesteps)',
          name: 'WindApiClient');
      return results;
    } catch (_) {
      // Fall through to single-timestep fallback
    }

    // Fallback: single-timestep grid via existing fetchWindGrid()
    try {
      final grid = await fetchWindGrid(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        pressureLevel: pressureLevel,
      );
      final now = DateTime.now().toUtc();
      final rounded = now.minute >= 30
          ? DateTime.utc(now.year, now.month, now.day, now.hour + 1)
          : DateTime.utc(now.year, now.month, now.day, now.hour);
      log('fetchWindGridSeries: single-timestep fallback for ${pressureLevel}hPa',
          name: 'WindApiClient');
      return [(time: rounded, grid: grid)];
    } catch (_) {
      // Total failure
    }

    throw Exception(
      'fetchWindGridSeries: all APIs failed for '
      '($lat, $lng) ${pressureLevel}hPa',
    );
  }

  /// Fetches Shyft area time-series (area query with datetime range).
  Future<List<({DateTime time, WindField grid})>> _fetchShyftAreaSeries(
    String encodedPoly,
    int pressureLevel,
    String datetimeRange,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.shyftSurfaceCollection
        : WindApiConstants.shyftIsobaricCollection;

    var url = '${WindApiConstants.shyftBaseUrl}/$collection/area'
        '?coords=$encodedPoly'
        '&parameter-name=${WindApiConstants.shyftUParam},${WindApiConstants.shyftVParam}'
        '&datetime=$datetimeRange'
        '&apikey=${WindApiConstants.shyftApiKey}'
        '&f=${WindApiConstants.shyftAreaFormat}';

    if (pressureLevel > 0) {
      url += '&z=$pressureLevel';
    }

    final response =
        await _client.get(Uri.parse(url)).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Shyft area series HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseShyftAreaSeries(json, pressureLevel);
  }

  /// Parses a Shyft MultiPointSeries area response with multiple timesteps.
  ///
  /// The composite axis contains [lng, lat, pressure] tuples.
  /// The t axis contains ISO timestamps.
  /// Values arrays are flattened: (numPoints * numTimesteps) in time-major
  /// order (all points for t0, all points for t1, ...).
  List<({DateTime time, WindField grid})> _parseShyftAreaSeries(
    Map<String, dynamic> json,
    int pressureLevel,
  ) {
    final domain = json['domain'] as Map<String, dynamic>;
    final axes = domain['axes'] as Map<String, dynamic>;

    // Extract composite points
    final composites = (axes['composite']['values'] as List)
        .map((c) => (c as List).cast<num>())
        .toList();

    if (composites.isEmpty) {
      throw Exception('Shyft area series: empty composite axis');
    }

    // Extract timestamps
    final tAxis = axes['t'] as Map<String, dynamic>?;
    final tValues = tAxis?['values'] as List?;
    if (tValues == null || tValues.isEmpty) {
      throw Exception('Shyft area series: missing t.values');
    }
    final timestamps = tValues.map((v) => DateTime.parse(v.toString())).toList();

    // Extract U/V values
    final rawUs = (json['ranges'][WindApiConstants.shyftUParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();
    final rawVs = (json['ranges'][WindApiConstants.shyftVParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();

    // Build grid coordinate arrays
    final xSet = composites.map((c) => c[0].toDouble()).toSet().toList()..sort();
    final ySet = composites.map((c) => c[1].toDouble()).toSet().toList()..sort();

    final numPoints = composites.length;
    final numTimesteps = timestamps.length;

    // Build index map: composite point index -> (row, col) in grid
    final pointIndices = <int, (int, int)>{};
    for (int i = 0; i < composites.length; i++) {
      final col = xSet.indexOf(composites[i][0].toDouble());
      final row = ySet.indexOf(composites[i][1].toDouble());
      pointIndices[i] = (row, col);
    }

    final results = <({DateTime time, WindField grid})>[];
    final gridSize = xSet.length * ySet.length;

    for (int t = 0; t < numTimesteps; t++) {
      final gridU = List<double>.filled(gridSize, 0.0);
      final gridV = List<double>.filled(gridSize, 0.0);

      for (int p = 0; p < numPoints; p++) {
        final valueIdx = t * numPoints + p;
        if (valueIdx >= rawUs.length) continue;

        final (row, col) = pointIndices[p]!;
        final gridIdx = row * xSet.length + col;
        gridU[gridIdx] = rawUs[valueIdx];
        gridV[gridIdx] = rawVs[valueIdx];
      }

      final source =
          'Shyft ${pressureLevel == 0 ? 'surface' : '${pressureLevel}hPa'} t$t';

      results.add((
        time: timestamps[t],
        grid: WindField(
          xs: List.of(xSet),
          ys: List.of(ySet),
          us: gridU,
          vs: gridV,
          source: source,
        ),
      ));
    }

    return results;
  }

  /// Fetches Folkweather area time-series (area query with datetime range).
  Future<List<({DateTime time, WindField grid})>> _fetchFolkAreaSeries(
    String encodedPoly,
    int pressureLevel,
    String datetimeRange,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.folkSurfaceCollection
        : _folkCollection(pressureLevel);

    var url = '${WindApiConstants.folkBaseUrl}/$collection/area'
        '?coords=$encodedPoly'
        '&parameter-name=${WindApiConstants.folkUParam},${WindApiConstants.folkVParam}'
        '&datetime=$datetimeRange'
        '&f=${WindApiConstants.folkFormat}';

    if (pressureLevel == 0) {
      url += '&z=10';
    } else {
      url += '&z=$pressureLevel';
    }

    final response =
        await _client.get(Uri.parse(url)).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Folkweather area series HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseFolkAreaSeries(json, pressureLevel);
  }

  /// Parses a Folkweather area response with multiple timesteps.
  ///
  /// Standard x/y/t axes with row-major values.
  /// Values are flattened: (numTimesteps * numRows * numCols).
  /// Longitudes in 0-360 format are normalized to -180/180.
  List<({DateTime time, WindField grid})> _parseFolkAreaSeries(
    Map<String, dynamic> json,
    int pressureLevel,
  ) {
    final domain = json['domain'] as Map<String, dynamic>;
    final axes = domain['axes'] as Map<String, dynamic>;

    // Extract grid coordinates
    List<double> rawXs = (axes['x']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final rawYs = (axes['y']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();

    // Normalize longitudes from 0-360 to -180/180
    rawXs = rawXs.map((x) => x > 180 ? x - 360 : x).toList();

    // Sort axes ascending and build sort-index arrays for reindexing.
    // This matches the Shyft parser pattern and fulfills the WindField
    // contract that xs and ys are sorted ascending.
    final xIndices = List.generate(rawXs.length, (i) => i);
    xIndices.sort((a, b) => rawXs[a].compareTo(rawXs[b]));
    final sortedXs = [for (final i in xIndices) rawXs[i]];

    final yIndices = List.generate(rawYs.length, (i) => i);
    yIndices.sort((a, b) => rawYs[a].compareTo(rawYs[b]));
    final sortedYs = [for (final i in yIndices) rawYs[i]];

    // Extract timestamps
    final tAxis = axes['t'] as Map<String, dynamic>?;
    final tValues = tAxis?['values'] as List?;
    if (tValues == null || tValues.isEmpty) {
      throw Exception('Folkweather area series: missing t.values');
    }
    final timestamps = tValues.map((v) => DateTime.parse(v.toString())).toList();

    // Extract U/V values
    final rawUs = (json['ranges'][WindApiConstants.folkUParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();
    final rawVs = (json['ranges'][WindApiConstants.folkVParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();

    final numTimesteps = timestamps.length;
    final numCols = rawXs.length;
    final numRows = rawYs.length;
    final pointsPerTimestep = numCols * numRows;

    final results = <({DateTime time, WindField grid})>[];

    for (int t = 0; t < numTimesteps; t++) {
      final offset = t * pointsPerTimestep;
      final gridU = List<double>.filled(pointsPerTimestep, 0.0);
      final gridV = List<double>.filled(pointsPerTimestep, 0.0);

      // Reindex from API order (rawYs x rawXs) to sorted order (sortedYs x sortedXs)
      for (int sortedRow = 0; sortedRow < numRows; sortedRow++) {
        final apiRow = yIndices[sortedRow];
        for (int sortedCol = 0; sortedCol < numCols; sortedCol++) {
          final apiCol = xIndices[sortedCol];
          final apiIdx = offset + apiRow * numCols + apiCol;
          final sortedIdx = sortedRow * numCols + sortedCol;
          if (apiIdx < rawUs.length) {
            gridU[sortedIdx] = rawUs[apiIdx];
            gridV[sortedIdx] = rawVs[apiIdx];
          }
        }
      }

      final source =
          'Folkweather ${pressureLevel == 0 ? 'surface' : '${pressureLevel}hPa'} t$t';

      results.add((
        time: timestamps[t],
        grid: WindField(
          xs: List.of(sortedXs),
          ys: List.of(sortedYs),
          us: gridU,
          vs: gridV,
          source: source,
        ),
      ));
    }

    return results;
  }

  // ─── Point Wind Time-Series Query ──────────────────────────────

  /// Fetches a time series of wind vectors at a single geographic point.
  ///
  /// Returns a list of (DateTime, double u, double v) records for [hours]
  /// forecast hours. Tries Shyft first, falls back to Folkweather.
  ///
  /// [pressureLevel]: 0 for surface (10m AGL), otherwise hPa (e.g., 850, 700).
  ///
  /// On both-APIs-fail, returns an empty list (graceful degradation).
  Future<List<({DateTime time, double u, double v})>> fetchPointWindSeries({
    required double lat,
    required double lng,
    required int pressureLevel,
    int hours = 72,
  }) async {
    // Try Shyft primary
    try {
      return await _fetchShyftPointSeries(lat, lng, pressureLevel, hours);
    } catch (_) {
      // Fall through to Folkweather
    }

    // Try Folkweather fallback
    try {
      return await _fetchFolkPointSeries(lat, lng, pressureLevel, hours);
    } catch (_) {
      // Both APIs failed
    }

    return [];
  }

  Future<List<({DateTime time, double u, double v})>> _fetchShyftPointSeries(
    double lat,
    double lng,
    int pressureLevel,
    int hours,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.shyftSurfaceCollection
        : WindApiConstants.shyftIsobaricCollection;

    final coordsParam = 'POINT($lng $lat)';
    final datetimeRange = _dateTimeRangeUtc(hours);

    final queryParams = <String, String>{
      'coords': coordsParam,
      'parameter-name':
          '${WindApiConstants.shyftUParam},${WindApiConstants.shyftVParam}',
      'apikey': WindApiConstants.shyftApiKey,
      'f': WindApiConstants.shyftPositionFormat,
      'datetime': datetimeRange,
    };

    if (pressureLevel > 0) {
      queryParams['z'] = pressureLevel.toString();
    }

    final uri = Uri.parse(
      '${WindApiConstants.shyftBaseUrl}/$collection/position',
    ).replace(queryParameters: queryParams);

    final response =
        await _client.get(uri).timeout(WindApiConstants.timeout);

    if (response.statusCode != 200) {
      throw Exception('Shyft series HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseShyftTimeSeriesResponse(json);
  }

  /// Parses Shyft CoverageCollection time-series response.
  ///
  /// Shyft returns separate Coverage objects for U and V, each containing
  /// a `t.values` array of ISO timestamps and matching `values` arrays.
  List<({DateTime time, double u, double v})> _parseShyftTimeSeriesResponse(
      Map<String, dynamic> json) {
    final coverages = json['coverages'] as List<dynamic>?;
    if (coverages == null || coverages.isEmpty) {
      throw Exception('Shyft series: missing or empty coverages');
    }

    List<String>? timestamps;
    List<double>? uValues;
    List<double>? vValues;

    for (final coverage in coverages) {
      final ranges = coverage['ranges'] as Map<String, dynamic>?;
      final domain = coverage['domain'] as Map<String, dynamic>?;
      if (ranges == null) continue;

      // Extract timestamps from the first coverage that has them
      if (timestamps == null && domain != null) {
        final axes = domain['axes'] as Map<String, dynamic>?;
        final tAxis = axes?['t'] as Map<String, dynamic>?;
        final tValues = tAxis?['values'] as List?;
        if (tValues != null) {
          timestamps = tValues.map((v) => v.toString()).toList();
        }
      }

      if (ranges.containsKey(WindApiConstants.shyftUParam)) {
        final values =
            ranges[WindApiConstants.shyftUParam]['values'] as List?;
        if (values != null) {
          uValues = values.map((v) => v != null ? (v as num).toDouble() : 0.0).toList();
        }
      }
      if (ranges.containsKey(WindApiConstants.shyftVParam)) {
        final values =
            ranges[WindApiConstants.shyftVParam]['values'] as List?;
        if (values != null) {
          vValues = values.map((v) => v != null ? (v as num).toDouble() : 0.0).toList();
        }
      }
    }

    if (timestamps == null || uValues == null || vValues == null) {
      throw Exception('Shyft series: could not extract time/U/V');
    }

    // Handle mismatched array lengths: use shortest
    final count = [timestamps.length, uValues.length, vValues.length]
        .reduce((a, b) => a < b ? a : b);

    final results = <({DateTime time, double u, double v})>[];
    for (int i = 0; i < count; i++) {
      results.add((
        time: DateTime.parse(timestamps[i]),
        u: uValues[i],
        v: vValues[i],
      ));
    }
    return results;
  }

  Future<List<({DateTime time, double u, double v})>> _fetchFolkPointSeries(
    double lat,
    double lng,
    int pressureLevel,
    int hours,
  ) async {
    final collection = pressureLevel == 0
        ? WindApiConstants.folkSurfaceCollection
        : _folkCollection(pressureLevel);

    final coordsParam = 'POINT($lng $lat)';
    final datetimeRange = _dateTimeRangeUtc(hours);

    final queryParams = <String, String>{
      'coords': coordsParam,
      'parameter-name':
          '${WindApiConstants.folkUParam},${WindApiConstants.folkVParam}',
      'f': WindApiConstants.folkFormat,
      'datetime': datetimeRange,
    };

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
      throw Exception('Folkweather series HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseFolkTimeSeriesResponse(json);
  }

  /// Parses Folkweather single Coverage time-series response.
  ///
  /// Folkweather returns both UGRD and VGRD in the same Coverage's ranges,
  /// with timestamps in `domain.axes.t.values`.
  List<({DateTime time, double u, double v})> _parseFolkTimeSeriesResponse(
      Map<String, dynamic> json) {
    final domain = json['domain'] as Map<String, dynamic>?;
    final ranges = json['ranges'] as Map<String, dynamic>?;

    if (domain == null || ranges == null) {
      throw Exception('Folkweather series: missing domain/ranges');
    }

    final axes = domain['axes'] as Map<String, dynamic>?;
    final tAxis = axes?['t'] as Map<String, dynamic>?;
    final tValues = tAxis?['values'] as List?;

    if (tValues == null || tValues.isEmpty) {
      throw Exception('Folkweather series: missing t.values');
    }

    final timestamps = tValues.map((v) => v.toString()).toList();

    final uValues = (ranges[WindApiConstants.folkUParam]
            as Map<String, dynamic>?)?['values'] as List?;
    final vValues = (ranges[WindApiConstants.folkVParam]
            as Map<String, dynamic>?)?['values'] as List?;

    if (uValues == null || vValues == null) {
      throw Exception('Folkweather series: missing UGRD/VGRD values');
    }

    // Handle mismatched array lengths: use shortest
    final count = [timestamps.length, uValues.length, vValues.length]
        .reduce((a, b) => a < b ? a : b);

    final results = <({DateTime time, double u, double v})>[];
    for (int i = 0; i < count; i++) {
      results.add((
        time: DateTime.parse(timestamps[i]),
        u: uValues[i] != null ? (uValues[i] as num).toDouble() : 0.0,
        v: vValues[i] != null ? (vValues[i] as num).toDouble() : 0.0,
      ));
    }
    return results;
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
    List<double> rawXs = (axes['x']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final rawYs = (axes['y']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();

    // Convert 0-360 longitude to -180/180
    rawXs = rawXs.map((x) => x > 180 ? x - 360 : x).toList();

    // Sort axes ascending and build sort-index arrays for reindexing.
    // This matches the Shyft parser pattern and fulfills the WindField
    // contract that xs and ys are sorted ascending.
    final xIndices = List.generate(rawXs.length, (i) => i);
    xIndices.sort((a, b) => rawXs[a].compareTo(rawXs[b]));
    final sortedXs = [for (final i in xIndices) rawXs[i]];

    final yIndices = List.generate(rawYs.length, (i) => i);
    yIndices.sort((a, b) => rawYs[a].compareTo(rawYs[b]));
    final sortedYs = [for (final i in yIndices) rawYs[i]];

    final rawUs = (json['ranges'][WindApiConstants.folkUParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();
    final rawVs = (json['ranges'][WindApiConstants.folkVParam]['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();

    final numCols = rawXs.length;
    final numRows = rawYs.length;
    final gridSize = numCols * numRows;
    final sortedUs = List<double>.filled(gridSize, 0.0);
    final sortedVs = List<double>.filled(gridSize, 0.0);

    // Reindex from API order (rawYs x rawXs) to sorted order (sortedYs x sortedXs)
    for (int sortedRow = 0; sortedRow < numRows; sortedRow++) {
      final apiRow = yIndices[sortedRow];
      for (int sortedCol = 0; sortedCol < numCols; sortedCol++) {
        final apiCol = xIndices[sortedCol];
        final apiIdx = apiRow * numCols + apiCol;
        final sortedIdx = sortedRow * numCols + sortedCol;
        if (apiIdx < rawUs.length) {
          sortedUs[sortedIdx] = rawUs[apiIdx];
          sortedVs[sortedIdx] = rawVs[apiIdx];
        }
      }
    }

    return WindField(
      xs: sortedXs,
      ys: sortedYs,
      us: sortedUs,
      vs: sortedVs,
      source: source,
    );
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

  /// Returns an ISO 8601 datetime range string for OGC EDR time-series queries.
  ///
  /// Format: "2026-02-27T12:00:00Z/2026-03-02T12:00:00Z"
  /// The range starts at the nearest hour and extends [hours] into the future.
  String _dateTimeRangeUtc(int hours) {
    final now = DateTime.now().toUtc();
    final start = now.minute >= 30
        ? DateTime.utc(now.year, now.month, now.day, now.hour + 1)
        : DateTime.utc(now.year, now.month, now.day, now.hour);
    final end = start.add(Duration(hours: hours));
    final startStr = '${start.toIso8601String().split('.')[0]}Z';
    final endStr = '${end.toIso8601String().split('.')[0]}Z';
    return '$startStr/$endStr';
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
