import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/horizon_profile.dart';
import '../models/scene_state.dart';
import '../models/sky_mask_data.dart';
import 'data_providers.dart';
import 'sensor_providers.dart';

part 'scene_provider.g.dart';

/// Composes all data sources into a single [SceneState] snapshot.
///
/// Returns `null` while critical data is still loading:
/// - **Blocks on:** position, wind, sensor data (cannot render without these)
/// - **Falls back for:** horizon (uses flat), sky mask (uses full sky)
///
/// This means the camera feed appears immediately, and particles appear
/// as soon as wind data resolves. Particles refine to sky-only regions
/// once sky detection kicks in.
@riverpod
SceneState? sceneState(SceneStateRef ref) {
  final position = ref.watch(stablePositionProvider);
  final horizon = ref.watch(horizonProfileProvider);
  final wind = ref.watch(windDataProvider);
  final sensor = ref.watch(rawSensorProvider);
  final altitude = ref.watch(selectedAltitudeProvider);

  // Block on critical data
  if (position == null) return null;
  final windValue = wind.valueOrNull;
  if (windValue == null) return null;
  final sensorValue = sensor.valueOrNull;
  if (sensorValue == null) return null;

  return SceneState(
    position: position,
    horizon: horizon.valueOrNull ??
        HorizonProfile.flat(position.latitude, position.longitude),
    wind: windValue,
    compassHeading: sensorValue.compassHeading,
    pitch: sensorValue.pitch,
    skyMask: SkyMaskData.fullSky(), // Fallback until sky detection wired
    selectedAltitude: altitude,
    timestamp: DateTime.now(),
  );
}
