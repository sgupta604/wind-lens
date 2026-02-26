import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Wind vector at a point (U/V in m/s)
class WindVector {
  final double u; // east component (positive = eastward)
  final double v; // north component (positive = northward)

  const WindVector({required this.u, required this.v});
  static const zero = WindVector(u: 0, v: 0);

  double get speed => sqrt(u * u + v * v);

  /// Meteorological direction: where wind is coming FROM (0°=N, 90°=E)
  double get directionFrom => (atan2(-u, -v) * 180 / pi + 360) % 360;

  @override
  String toString() => 'Wind(U=${u.toStringAsFixed(2)}, V=${v.toStringAsFixed(2)}, '
      '${speed.toStringAsFixed(1)}m/s from ${directionFrom.toStringAsFixed(0)}°)';
}

/// Grid of wind vectors with bilinear interpolation
class WindField {
  final List<double> xs; // longitudes (sorted ascending)
  final List<double> ys; // latitudes (sorted ascending)
  final List<double> us; // U components, flattened row-major [row * width + col]
  final List<double> vs; // V components
  final String source;
  final DateTime fetchedAt;

  WindField({
    required this.xs,
    required this.ys,
    required this.us,
    required this.vs,
    required this.source,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  int get width => xs.length;
  int get height => ys.length;

  /// Get wind at exact grid point
  WindVector getAt(int row, int col) {
    final idx = row * width + col;
    if (idx < 0 || idx >= us.length) return WindVector.zero;
    return WindVector(u: us[idx], v: vs[idx]);
  }

  /// Bilinear interpolation at normalized [0,1] position
  WindVector interpolate(double normX, double normY) {
    final x = (normX * (width - 1)).clamp(0.0, width - 1.001);
    final y = (normY * (height - 1)).clamp(0.0, height - 1.001);
    final x0 = x.floor().clamp(0, width - 2);
    final y0 = y.floor().clamp(0, height - 2);
    final fx = x - x0;
    final fy = y - y0;

    final p00 = getAt(y0, x0);
    final p10 = getAt(y0, x0 + 1);
    final p01 = getAt(y0 + 1, x0);
    final p11 = getAt(y0 + 1, x0 + 1);

    return WindVector(
      u: p00.u * (1 - fx) * (1 - fy) +
          p10.u * fx * (1 - fy) +
          p01.u * (1 - fx) * fy +
          p11.u * fx * fy,
      v: p00.v * (1 - fx) * (1 - fy) +
          p10.v * fx * (1 - fy) +
          p01.v * (1 - fx) * fy +
          p11.v * fx * fy,
    );
  }

  /// Interpolate at a geographic coordinate
  WindVector interpolateAtCoord(double lng, double lat) {
    if (xs.isEmpty || ys.isEmpty) return WindVector.zero;
    final normX = (lng - xs.first) / (xs.last - xs.first);
    final normY = (lat - ys.first) / (ys.last - ys.first);
    return interpolate(normX.clamp(0, 1), normY.clamp(0, 1));
  }

  double get maxSpeed {
    double m = 0;
    for (int i = 0; i < us.length; i++) {
      final s = sqrt(us[i] * us[i] + vs[i] * vs[i]);
      if (s > m) m = s;
    }
    return m;
  }

  /// Check if data is stale (older than given duration)
  bool isStale([Duration maxAge = const Duration(minutes: 30)]) {
    return DateTime.now().difference(fetchedAt) > maxAge;
  }
}

/// Result of a wind data fetch, with source tracking
class WindFetchResult {
  final Map<int, WindField> layers; // pressure level → WindField
  final String source;
  final String? fallbackReason; // set if primary failed

  WindFetchResult({
    required this.layers,
    required this.source,
    this.fallbackReason,
  });
}

// ═══════════════════════════════════════════════════════════════
//  Wind Data Service: Shyft primary → Folkweather fallback
// ═══════════════════════════════════════════════════════════════

class WindDataService {
  static const _shyftBase = 'https://ogc.shyftwx.com/ogc/edr/collections';
  static const _shyftKey = 'owp_BARNLCP72sszCKXxNp6OCPEhdvmklVDt';

  static const _folkBase = 'https://folkweather.com/edr/collections';

  static const _timeout = Duration(seconds: 12);

  /// Default altitude layers for Wind Lens
  /// Surface (10m AGL), 850 hPa (~1.5km), 700 hPa (~3km), 500 hPa (~5.6km)
  static const defaultLevels = [0, 850, 700, 500]; // 0 = surface

  // ─── Public API ────────────────────────────────────────────

  /// Fetch wind grids at multiple altitudes around a center point.
  /// Returns a map of pressure level → WindField.
  /// Level 0 = surface (10m above ground).
  Future<WindFetchResult> fetchMultiAltitude({
    required double lat,
    required double lng,
    double radiusKm = 40,
    List<int> levels = const [0, 850, 700, 500],
  }) async {
    String? fallbackReason;

    // Try Shyft first
    try {
      final results = await _fetchShyftMultiAltitude(lat, lng, radiusKm, levels);
      return WindFetchResult(layers: results, source: 'Shyft');
    } catch (e) {
      fallbackReason = e.toString();
    }

    // Fallback to Folkweather
    final results = await _fetchFolkMultiAltitude(lat, lng, radiusKm, levels);
    return WindFetchResult(
      layers: results,
      source: 'Folkweather',
      fallbackReason: fallbackReason,
    );
  }

  /// Fetch wind grid at a single altitude
  Future<WindField> fetchWindGrid({
    required double lat,
    required double lng,
    double radiusKm = 40,
    int level = 850,
  }) async {
    final bbox = _makeBbox(lat, lng, radiusKm);
    final poly = _bboxToPoly(bbox);
    final encodedPoly = Uri.encodeComponent(poly);

    // ── Try Shyft ──
    try {
      if (level == 0) {
        return await _fetchShyftSurface(encodedPoly);
      }
      return await _fetchShyftIsobaric(encodedPoly, level);
    } catch (e) {
      // Fall through to Folkweather
    }

    // ── Fallback: Folkweather ──
    if (level == 0) {
      return await _fetchFolkSurface(encodedPoly);
    }
    return await _fetchFolkIsobaric(encodedPoly, level);
  }

  // ─── Shyft Fetchers ───────────────────────────────────────

  Future<Map<int, WindField>> _fetchShyftMultiAltitude(
    double lat, double lng, double radiusKm, List<int> levels,
  ) async {
    final bbox = _makeBbox(lat, lng, radiusKm);
    final poly = _bboxToPoly(bbox);
    final enc = Uri.encodeComponent(poly);

    final results = <int, WindField>{};
    await Future.wait(levels.map((level) async {
      if (level == 0) {
        results[level] = await _fetchShyftSurface(enc);
      } else {
        results[level] = await _fetchShyftIsobaric(enc, level);
      }
    }));
    return results;
  }

  Future<WindField> _fetchShyftIsobaric(String encodedPoly, int level) async {
    final url = '$_shyftBase/GFS_isobaric/area'
        '?coords=$encodedPoly'
        '&parameter-name=u-component-of-wind,v-component-of-wind'
        '&z=$level'
        '&apikey=$_shyftKey'
        '&f=CoverageJSON_MultiPointSeries';

    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Shyft HTTP ${res.statusCode}');
    return _parseShyftMultiPoint(jsonDecode(res.body), 'Shyft ${level}hPa');
  }

  Future<WindField> _fetchShyftSurface(String encodedPoly) async {
    final url = '$_shyftBase/GFS_height-above-ground_10/area'
        '?coords=$encodedPoly'
        '&parameter-name=u-component-of-wind,v-component-of-wind'
        '&apikey=$_shyftKey'
        '&f=CoverageJSON_MultiPointSeries';

    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Shyft surface HTTP ${res.statusCode}');
    return _parseShyftMultiPoint(jsonDecode(res.body), 'Shyft surface');
  }

  /// Parse Shyft CoverageJSON_MultiPointSeries format.
  ///
  /// Structure:
  /// ```json
  /// {
  ///   "type": "Coverage",
  ///   "domain": {
  ///     "axes": {
  ///       "composite": { "values": [[-122.75, 37.5, 850.0], ...] },
  ///       "t": { "values": ["2026-02-25T18:00:00Z"] }
  ///     }
  ///   },
  ///   "ranges": {
  ///     "u-component-of-wind": { "values": [3.38, ...] },
  ///     "v-component-of-wind": { "values": [-0.28, ...] }
  ///   }
  /// }
  /// ```
  ///
  /// The composite axis contains [lng, lat, z] tuples in scan order,
  /// NOT necessarily in grid order. We extract unique x/y, sort them,
  /// and reindex into row-major grid order.
  WindField _parseShyftMultiPoint(Map<String, dynamic> json, String source) {
    final composites = (json['domain']['axes']['composite']['values'] as List)
        .map((c) => (c as List).cast<num>())
        .toList();

    if (composites.isEmpty) throw Exception('Shyft: empty composite axis');

    final us = (json['ranges']['u-component-of-wind']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final vs = (json['ranges']['v-component-of-wind']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();

    // Extract unique sorted grid coordinates
    final xSet = composites.map((c) => c[0].toDouble()).toSet().toList()..sort();
    final ySet = composites.map((c) => c[1].toDouble()).toSet().toList()..sort();

    // Map composite-ordered values → row-major grid [row * width + col]
    final gridU = List<double>.filled(xSet.length * ySet.length, 0.0);
    final gridV = List<double>.filled(xSet.length * ySet.length, 0.0);

    for (int i = 0; i < composites.length; i++) {
      final col = xSet.indexOf(composites[i][0].toDouble());
      final row = ySet.indexOf(composites[i][1].toDouble());
      final idx = row * xSet.length + col;
      gridU[idx] = us[i];
      gridV[idx] = vs[i];
    }

    return WindField(
      xs: xSet,
      ys: ySet,
      us: gridU,
      vs: gridV,
      source: source,
    );
  }

  // ─── Folkweather Fetchers ──────────────────────────────────

  Future<Map<int, WindField>> _fetchFolkMultiAltitude(
    double lat, double lng, double radiusKm, List<int> levels,
  ) async {
    final bbox = _makeBbox(lat, lng, radiusKm);
    final poly = _bboxToPoly(bbox);
    final enc = Uri.encodeComponent(poly);

    final results = <int, WindField>{};
    await Future.wait(levels.map((level) async {
      if (level == 0) {
        results[level] = await _fetchFolkSurface(enc);
      } else {
        results[level] = await _fetchFolkIsobaric(enc, level);
      }
    }));
    return results;
  }

  Future<WindField> _fetchFolkIsobaric(String encodedPoly, int level) async {
    // HRRR has 850/925 at 3km res; GFS has 700/500/300 at 25km
    // NOTE: GFS does NOT have 850 — use HRRR for it
    final collection = [850, 925, 1000].contains(level)
        ? 'hrrr-isobaric'
        : 'gfs-isobaric-latest';

    final url = '$_folkBase/$collection/area'
        '?coords=$encodedPoly'
        '&parameter-name=UGRD,VGRD'
        '&z=$level'
        '&f=CoverageJSON';

    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Folk HTTP ${res.statusCode}');
    return _parseFolkArea(jsonDecode(res.body), 'Folkweather ${level}hPa');
  }

  Future<WindField> _fetchFolkSurface(String encodedPoly) async {
    final url = '$_folkBase/hrrr-height-agl/area'
        '?coords=$encodedPoly'
        '&parameter-name=UGRD,VGRD'
        '&z=10'
        '&f=CoverageJSON';

    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Folk surface HTTP ${res.statusCode}');
    return _parseFolkArea(jsonDecode(res.body), 'Folkweather surface');
  }

  /// Parse Folkweather CoverageJSON format.
  ///
  /// Structure:
  /// ```json
  /// {
  ///   "type": "Coverage",
  ///   "domain": {
  ///     "axes": {
  ///       "x": { "values": [237.25, 237.5, ...] },  // NOTE: 0-360 longitude!
  ///       "y": { "values": [37.5, 37.75, ...] }
  ///     }
  ///   },
  ///   "ranges": {
  ///     "UGRD": { "values": [2.1, 3.5, ...] },
  ///     "VGRD": { "values": [-1.2, 0.8, ...] }
  ///   }
  /// }
  /// ```
  WindField _parseFolkArea(Map<String, dynamic> json, String source) {
    final axes = json['domain']['axes'];
    List<double> xs = (axes['x']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final ys = (axes['y']['values'] as List)
        .map((v) => (v as num).toDouble())
        .toList();

    // Convert 0-360 longitude to -180/180
    xs = xs.map((x) => x > 180 ? x - 360 : x).toList();

    final us = (json['ranges']['UGRD']['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();
    final vs = (json['ranges']['VGRD']['values'] as List)
        .map((v) => v != null ? (v as num).toDouble() : 0.0)
        .toList();

    return WindField(xs: xs, ys: ys, us: us, vs: vs, source: source);
  }

  // ─── Geometry helpers ──────────────────────────────────────

  List<double> _makeBbox(double lat, double lng, double radiusKm) {
    final dLat = radiusKm / 111.32;
    final dLng = radiusKm / (111.32 * cos(lat * pi / 180));
    return [lng - dLng, lat - dLat, lng + dLng, lat + dLat];
  }

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
}
