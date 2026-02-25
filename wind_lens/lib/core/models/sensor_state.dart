import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_state.freezed.dart';

/// Immutable data class representing a compass/pitch sensor reading.
///
/// Replaces the mutable [CompassData] class with Freezed-generated
/// equality and copyWith. No JSON serialization needed (not cached).
///
/// Fields:
/// - [compassHeading]: Degrees from magnetic north (0-360)
/// - [pitch]: Device tilt angle in degrees (positive = tilted up)
/// - [timestamp]: When this reading was taken
@freezed
class SensorState with _$SensorState {
  const factory SensorState({
    required double compassHeading,
    required double pitch,
    required DateTime timestamp,
  }) = _SensorState;
}
