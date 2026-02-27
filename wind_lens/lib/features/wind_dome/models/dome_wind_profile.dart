import 'dome_wind_field.dart';

/// A 72-hour wind forecast profile for the dome visualization.
///
/// Contains one [DomeWindField] per hour, allowing instant time-travel
/// via the forecast slider without additional network calls.
///
/// Plain Dart class, NOT Freezed -- constructed once from API response
/// and cached for 10 minutes.
class DomeWindProfile {
  /// Hourly wind fields, index 0 = now, index N = +N hours.
  /// Typically 72 entries for a 72-hour GFS forecast.
  final List<DomeWindField> hourly;

  /// When this profile was fetched from the API.
  final DateTime fetchedAt;

  /// Latitude of the fetch point (for cache key).
  final double lat;

  /// Longitude of the fetch point (for cache key).
  final double lng;

  /// Creates a wind profile with the given hourly fields.
  DomeWindProfile({
    required this.hourly,
    required this.fetchedAt,
    required this.lat,
    required this.lng,
  });

  /// Returns the wind field for [hoursAhead] with clamping.
  ///
  /// [hoursAhead] is clamped to [0, hourly.length - 1].
  /// Returns the first entry for negative values, the last for overflow.
  DomeWindField fieldAt(int hoursAhead) {
    if (hourly.isEmpty) {
      return DomeWindField.zero();
    }
    return hourly[hoursAhead.clamp(0, hourly.length - 1)];
  }

  @override
  String toString() =>
      'DomeWindProfile(hours=${hourly.length}, lat=$lat, lng=$lng)';
}
