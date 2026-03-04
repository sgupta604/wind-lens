import '../../../services/wind/wind_models.dart';

/// A single altitude layer of wind data for the dome visualization.
///
/// Represents wind conditions at a specific altitude, with u/v components
/// directly from OGC EDR API data. Optionally carries a [WindField] grid
/// for spatially-varying wind at large dome sizes.
///
/// Plain Dart class, NOT Freezed -- used in the wind field sampling path.
class DomeWindLayer {
  /// Real-world altitude in meters (e.g. 10, 1500, 3000).
  final double altitudeMeters;

  /// Eastward wind component in m/s (positive = blowing toward east).
  ///
  /// When [grid] is present, this holds the center-point value for display
  /// and fallback purposes.
  final double u;

  /// Northward wind component in m/s (positive = blowing toward north).
  ///
  /// When [grid] is present, this holds the center-point value for display
  /// and fallback purposes.
  final double v;

  /// Spatial wind grid for this altitude layer, or null for point-data layers.
  ///
  /// When present, [DomeWindField.sample] uses bilinear interpolation on
  /// the grid instead of the scalar [u]/[v] values. This enables spatially-
  /// varying wind for large dome sizes (>= 15km radius).
  final WindField? grid;

  /// Creates a wind layer with the given altitude and wind components.
  const DomeWindLayer({
    required this.altitudeMeters,
    required this.u,
    required this.v,
    this.grid,
  });

  @override
  String toString() =>
      'DomeWindLayer(alt=${altitudeMeters}m, u=${u.toStringAsFixed(2)}, '
      'v=${v.toStringAsFixed(2)}, grid=${grid != null ? 'yes' : 'no'})';
}
