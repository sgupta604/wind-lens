import 'dart:math';

/// Represents wind data with u/v vector components.
///
/// Wind data uses meteorological conventions:
/// - u-component: Eastward component (positive = wind blowing toward east)
/// - v-component: Northward component (positive = wind blowing toward north)
///
/// The direction is the compass direction the wind is coming FROM,
/// following standard meteorological convention.
///
/// Example:
/// ```dart
/// final wind = WindData(
///   uComponent: -3.0, // wind blowing westward
///   vComponent: 4.0,  // wind blowing northward
///   altitude: 10.0,
///   timestamp: DateTime.now(),
/// );
/// print(wind.speed);           // 5.0 m/s
/// print(wind.directionDegrees); // Direction wind is coming FROM
/// ```
class WindData {
  /// Eastward wind component in m/s.
  ///
  /// Positive values indicate wind blowing toward the east.
  /// Negative values indicate wind blowing toward the west.
  final double uComponent;

  /// Northward wind component in m/s.
  ///
  /// Positive values indicate wind blowing toward the north.
  /// Negative values indicate wind blowing toward the south.
  final double vComponent;

  /// Altitude above sea level in meters.
  final double altitude;

  /// Timestamp when this wind data was recorded.
  final DateTime timestamp;

  /// Creates a new WindData instance.
  ///
  /// All parameters are required. Use [WindData.zero] for a default
  /// zero-wind instance.
  const WindData({
    required this.uComponent,
    required this.vComponent,
    required this.altitude,
    required this.timestamp,
  });

  /// Wind speed in m/s.
  ///
  /// Computed as the magnitude of the wind vector: sqrt(u^2 + v^2).
  /// This is always a positive value representing the wind's strength.
  double get speed => sqrt(uComponent * uComponent + vComponent * vComponent);

  /// Wind direction in radians.
  ///
  /// Uses the meteorological convention: direction wind is coming FROM.
  /// Computed as atan2(-u, -v) to get the "from" direction.
  ///
  /// - 0 radians = wind from south (blowing northward)
  /// - pi/2 radians = wind from west (blowing eastward)
  /// - pi radians = wind from north (blowing southward)
  /// - -pi/2 radians = wind from east (blowing westward)
  double get directionRadians => atan2(-uComponent, -vComponent);

  /// Wind direction in degrees (0-360).
  ///
  /// Uses the meteorological convention: direction wind is coming FROM.
  /// Normalized to 0-360 degrees where:
  /// - 0 degrees = wind from north
  /// - 90 degrees = wind from east
  /// - 180 degrees = wind from south
  /// - 270 degrees = wind from west
  double get directionDegrees => (directionRadians * 180 / pi + 360) % 360;

  /// Creates a zero-wind instance.
  ///
  /// Useful for initialization when no wind data is available yet.
  /// Returns wind with speed 0 at altitude 0.
  static WindData zero() => WindData(
        uComponent: 0,
        vComponent: 0,
        altitude: 0,
        timestamp: DateTime.now(),
      );
}
