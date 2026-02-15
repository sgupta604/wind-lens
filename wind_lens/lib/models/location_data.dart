/// Immutable data class holding GPS location readings.
///
/// This class contains position data from the device's GPS sensor,
/// provided by the [LocationService].
///
/// - [latitude]: Degrees north/south of the equator (-90 to 90)
/// - [longitude]: Degrees east/west of the prime meridian (-180 to 180)
/// - [accuracy]: Horizontal accuracy in meters
/// - [timestamp]: When the reading was taken
class LocationData {
  /// Latitude in degrees (-90 to 90).
  /// Positive values are north of the equator.
  final double latitude;

  /// Longitude in degrees (-180 to 180).
  /// Positive values are east of the prime meridian.
  final double longitude;

  /// Horizontal accuracy in meters.
  /// Lower values indicate more precise readings.
  final double accuracy;

  /// When this position reading was taken.
  final DateTime timestamp;

  /// Creates a [LocationData] instance with the given position fields.
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });
}
