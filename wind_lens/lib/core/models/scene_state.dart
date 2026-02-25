import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/altitude_level.dart';
import 'horizon_profile.dart';
import 'position_data.dart';
import 'sky_mask_data.dart';
import 'wind_data.dart';

part 'scene_state.freezed.dart';

/// Immutable data class representing the complete composed scene state.
///
/// This is the "big one" -- it composes all sub-models into a single
/// snapshot that the renderer consumes. The `sceneStateProvider` (Phase 2)
/// will compose this from multiple individual providers.
///
/// Fields:
/// - [position]: GPS location
/// - [horizon]: Terrain horizon profile
/// - [wind]: Wind vector data
/// - [compassHeading]: Current compass heading in degrees
/// - [pitch]: Current device pitch in degrees
/// - [skyMask]: Sky detection mask
/// - [selectedAltitude]: User-selected altitude level
/// - [timestamp]: When this scene state was composed
///
/// No JSON serialization needed (this is a transient composed state).
@freezed
class SceneState with _$SceneState {
  const factory SceneState({
    required PositionData position,
    required HorizonProfile horizon,
    required WindData wind,
    required double compassHeading,
    required double pitch,
    required SkyMaskData skyMask,
    required AltitudeLevel selectedAltitude,
    required DateTime timestamp,
  }) = _SceneState;
}
