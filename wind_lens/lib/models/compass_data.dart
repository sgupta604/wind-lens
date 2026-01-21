/// Immutable data class holding compass readings.
///
/// This class contains smoothed heading and pitch values from the device's
/// magnetometer and accelerometer sensors.
///
/// - [heading]: Compass direction in degrees from magnetic north (0-360)
/// - [pitch]: Device tilt angle in degrees (positive when tilted up)
class CompassData {
  /// Compass direction in degrees from magnetic north (0-360).
  final double heading;

  /// Device tilt angle in degrees.
  /// Positive values indicate the phone is tilted up (looking at sky).
  /// Negative values indicate the phone is tilted down.
  final double pitch;

  /// Creates a [CompassData] instance with the given [heading] and [pitch].
  const CompassData({
    required this.heading,
    required this.pitch,
  });
}
