import 'dart:math';

/// Wind vector at a single point (U/V components in m/s).
///
/// Plain mutable class, NOT Freezed. Used in hot-path interpolation
/// for the future Wind Dome feature where bilinear interpolation
/// runs per-particle per-frame.
///
/// Fields:
/// - [u]: Eastward wind component (positive = blowing toward east)
/// - [v]: Northward wind component (positive = blowing toward north)
class WindVector {
  /// Eastward wind component in m/s.
  final double u;

  /// Northward wind component in m/s.
  final double v;

  /// Creates a wind vector with the given U/V components.
  const WindVector({required this.u, required this.v});

  /// Zero-wind vector (no wind).
  static const zero = WindVector(u: 0, v: 0);

  /// Wind speed in m/s (magnitude of the wind vector).
  double get speed => sqrt(u * u + v * v);

  /// Meteorological direction: where wind is coming FROM (0=N, 90=E).
  double get directionFrom => (atan2(-u, -v) * 180 / pi + 360) % 360;

  @override
  String toString() =>
      'Wind(U=${u.toStringAsFixed(2)}, V=${v.toStringAsFixed(2)}, '
      '${speed.toStringAsFixed(1)}m/s from ${directionFrom.toStringAsFixed(0)}deg)';
}

/// Grid of wind vectors with bilinear interpolation.
///
/// Represents a rectangular grid of wind data points at a single altitude.
/// Supports geographic coordinate-based interpolation for smooth wind field
/// sampling between grid points.
///
/// Plain mutable class, NOT Freezed. Designed for reuse by both
/// [OgcEdrWindDataSource] (center-point extraction) and the future
/// Wind Dome feature (full-grid interpolation per particle per frame).
///
/// Grid values are stored in row-major order: `us[row * width + col]`.
class WindField {
  /// Longitudes of grid columns, sorted ascending.
  final List<double> xs;

  /// Latitudes of grid rows, sorted ascending.
  final List<double> ys;

  /// U (eastward) wind components in row-major order.
  final List<double> us;

  /// V (northward) wind components in row-major order.
  final List<double> vs;

  /// Data source identifier (e.g., 'Shyft 850hPa', 'Folkweather surface').
  final String source;

  /// When this data was fetched from the API.
  final DateTime fetchedAt;

  /// Creates a wind field grid.
  WindField({
    required this.xs,
    required this.ys,
    required this.us,
    required this.vs,
    required this.source,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// Number of grid columns (longitude points).
  int get width => xs.length;

  /// Number of grid rows (latitude points).
  int get height => ys.length;

  /// Gets the wind vector at exact grid coordinates [row], [col].
  ///
  /// Returns [WindVector.zero] if indices are out of bounds.
  WindVector getAt(int row, int col) {
    if (row < 0 || col < 0) return WindVector.zero;
    final idx = row * width + col;
    if (idx < 0 || idx >= us.length) return WindVector.zero;
    return WindVector(u: us[idx], v: vs[idx]);
  }

  /// Bilinear interpolation at normalized [0,1] position within the grid.
  ///
  /// [normX] and [normY] are clamped to [0, 1]. Returns [WindVector.zero]
  /// if the grid has fewer than 2 points in either dimension.
  WindVector interpolate(double normX, double normY) {
    if (width < 2 || height < 2) {
      if (width == 1 && height == 1) return getAt(0, 0);
      return WindVector.zero;
    }

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

  /// Interpolates the wind vector at a geographic coordinate.
  ///
  /// Converts [lng] and [lat] to normalized grid coordinates and
  /// performs bilinear interpolation. Coordinates outside the grid
  /// are clamped to the nearest edge.
  ///
  /// Returns [WindVector.zero] if the grid is empty.
  WindVector interpolateAtCoord(double lng, double lat) {
    if (xs.isEmpty || ys.isEmpty) return WindVector.zero;
    if (xs.length == 1 && ys.length == 1) return getAt(0, 0);

    final xRange = xs.last - xs.first;
    final yRange = ys.last - ys.first;

    final normX = xRange == 0 ? 0.5 : (lng - xs.first) / xRange;
    final normY = yRange == 0 ? 0.5 : (lat - ys.first) / yRange;

    return interpolate(normX.clamp(0, 1).toDouble(), normY.clamp(0, 1).toDouble());
  }

  /// Returns the wind vector at the center of the grid.
  ///
  /// Used by [OgcEdrWindDataSource] to extract a single wind value
  /// from a grid response, providing the most representative point.
  WindVector centerWind() {
    if (xs.isEmpty || ys.isEmpty) return WindVector.zero;
    return interpolate(0.5, 0.5);
  }

  /// Maximum wind speed across all grid points.
  double get maxSpeed {
    double m = 0;
    for (int i = 0; i < us.length; i++) {
      final s = sqrt(us[i] * us[i] + vs[i] * vs[i]);
      if (s > m) m = s;
    }
    return m;
  }

  /// Whether this data is older than [maxAge].
  ///
  /// Defaults to 30 minutes. Used to decide when to refetch.
  bool isStale([Duration maxAge = const Duration(minutes: 30)]) {
    return DateTime.now().difference(fetchedAt) > maxAge;
  }
}
