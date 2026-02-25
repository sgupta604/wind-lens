import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_data.freezed.dart';
part 'position_data.g.dart';

/// Immutable data class representing a GPS position reading.
///
/// Replaces the mutable [LocationData] class with Freezed-generated
/// equality, copyWith, and JSON serialization.
///
/// Fields:
/// - [latitude]: Degrees north/south of the equator (-90 to 90)
/// - [longitude]: Degrees east/west of the prime meridian (-180 to 180)
/// - [altitude]: Meters above sea level (0.0 placeholder until Phase 2)
/// - [accuracy]: Horizontal accuracy in meters
/// - [timestamp]: When this reading was taken
@freezed
class PositionData with _$PositionData {
  const factory PositionData({
    required double latitude,
    required double longitude,
    required double altitude,
    required double accuracy,
    required DateTime timestamp,
  }) = _PositionData;

  factory PositionData.fromJson(Map<String, dynamic> json) =>
      _$PositionDataFromJson(json);
}
