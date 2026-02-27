/// A single altitude layer of wind data for the dome visualization.
///
/// Represents wind conditions at a specific altitude, with u/v components
/// directly from OGC EDR API data.
///
/// Plain Dart class, NOT Freezed -- used in the wind field sampling path.
class DomeWindLayer {
  /// Real-world altitude in meters (e.g. 10, 1500, 3000).
  final double altitudeMeters;

  /// Eastward wind component in m/s (positive = blowing toward east).
  final double u;

  /// Northward wind component in m/s (positive = blowing toward north).
  final double v;

  /// Creates a wind layer with the given altitude and wind components.
  const DomeWindLayer({
    required this.altitudeMeters,
    required this.u,
    required this.v,
  });

  @override
  String toString() =>
      'DomeWindLayer(alt=${altitudeMeters}m, u=${u.toStringAsFixed(2)}, '
      'v=${v.toStringAsFixed(2)})';
}
