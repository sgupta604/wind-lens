import 'package:freezed_annotation/freezed_annotation.dart';

part 'horizon_profile.freezed.dart';
part 'horizon_profile.g.dart';

/// JSON converter for `Map<double, double>` since JSON map keys must be strings.
///
/// Converts double keys to/from string representation for JSON serialization.
class DoubleMapConverter
    implements JsonConverter<Map<double, double>, Map<String, dynamic>> {
  const DoubleMapConverter();

  @override
  Map<double, double> fromJson(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(
          double.parse(key),
          (value as num).toDouble(),
        ));
  }

  @override
  Map<String, dynamic> toJson(Map<double, double> data) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
}

/// Immutable data class representing a terrain horizon profile.
///
/// A horizon profile maps compass bearings (0-360 degrees) to elevation
/// angles (degrees above horizontal) where terrain meets the sky. This
/// is used by terrain-based sky detection to determine where the sky
/// boundary is at any compass direction.
///
/// The [elevationAngles] map contains discrete bearing->elevation pairs.
/// Use [getElevationAtBearing] for interpolated lookups at any bearing.
///
/// Fields:
/// - [latitude]: Location latitude for this profile
/// - [longitude]: Location longitude for this profile
/// - [elevationAngles]: Map of bearing (degrees) to elevation angle (degrees)
/// - [fetchedAt]: When this profile was fetched/computed
@freezed
class HorizonProfile with _$HorizonProfile {
  const HorizonProfile._();

  const factory HorizonProfile({
    required double latitude,
    required double longitude,
    /// Map of bearing (0-360) to elevation angle in degrees.
    /// Elevation angle = how many degrees above horizontal the terrain reaches.
    @DoubleMapConverter() required Map<double, double> elevationAngles,
    required DateTime fetchedAt,

    /// Magnetic declination in degrees from HeyWhatsThat API.
    ///
    /// Used for compass correction: trueBearing = magneticBearing + declination.
    /// Positive means magnetic north is east of true north.
    /// Stored here for future use by terrain-based sky detection (P2B-004).
    @Default(0.0) double declination,

    /// HeyWhatsThat panorama ID that produced this profile.
    ///
    /// Stored for potential re-fetch or diagnostic purposes.
    /// Null for flat/mock profiles or profiles from other sources.
    String? panoramaId,
  }) = _HorizonProfile;

  factory HorizonProfile.fromJson(Map<String, dynamic> json) =>
      _$HorizonProfileFromJson(json);

  /// Creates a flat horizon profile (0 degrees elevation at every bearing).
  ///
  /// Useful for testing and indoor use where no terrain data is available.
  /// Generates entries at every 1-degree interval from 0 to 359.
  factory HorizonProfile.flat(double lat, double lng) {
    final angles = <double, double>{};
    for (int i = 0; i < 360; i++) {
      angles[i.toDouble()] = 0.0;
    }
    return HorizonProfile(
      latitude: lat,
      longitude: lng,
      elevationAngles: angles,
      fetchedAt: DateTime.now(),
    );
  }

  /// Gets the interpolated elevation angle at a given bearing.
  ///
  /// If the exact bearing exists in the map, returns it directly.
  /// Otherwise, interpolates linearly between the two nearest bearings.
  /// Handles wraparound at 0/360 degrees correctly.
  ///
  /// [bearing] should be in degrees (0-360). Values outside this range
  /// are normalized.
  double getElevationAtBearing(double bearing) {
    // Normalize bearing to 0-360
    final normalizedBearing = ((bearing % 360) + 360) % 360;

    // Check for exact match
    if (elevationAngles.containsKey(normalizedBearing)) {
      return elevationAngles[normalizedBearing]!;
    }

    // If map is empty, return 0
    if (elevationAngles.isEmpty) return 0.0;

    // Sort bearings for interpolation
    final sortedBearings = elevationAngles.keys.toList()..sort();

    // Find the two nearest bearings (lower and upper)
    double? lowerBearing;
    double? upperBearing;

    for (final b in sortedBearings) {
      if (b <= normalizedBearing) {
        lowerBearing = b;
      }
      if (b >= normalizedBearing && upperBearing == null) {
        upperBearing = b;
      }
    }

    // Handle wraparound: if no lower bearing, wrap to the last one
    lowerBearing ??= sortedBearings.last;
    // Handle wraparound: if no upper bearing, wrap to the first one
    upperBearing ??= sortedBearings.first;

    // If both are the same, return that value
    if (lowerBearing == upperBearing) {
      return elevationAngles[lowerBearing]!;
    }

    // Interpolate between the two nearest bearings
    final lowerElevation = elevationAngles[lowerBearing]!;
    final upperElevation = elevationAngles[upperBearing]!;

    // Calculate interpolation factor, handling wraparound
    double range;
    double position;

    if (lowerBearing > upperBearing) {
      // Wraparound case (e.g., lower=350, upper=10)
      range = (360 - lowerBearing) + upperBearing;
      if (normalizedBearing >= lowerBearing) {
        position = normalizedBearing - lowerBearing;
      } else {
        position = (360 - lowerBearing) + normalizedBearing;
      }
    } else {
      range = upperBearing - lowerBearing;
      position = normalizedBearing - lowerBearing;
    }

    final t = range > 0 ? position / range : 0.0;
    return lowerElevation + (upperElevation - lowerElevation) * t;
  }
}
