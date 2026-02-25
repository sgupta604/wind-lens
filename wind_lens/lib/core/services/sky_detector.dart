import 'package:camera/camera.dart';

import '../models/horizon_profile.dart';
import '../models/sensor_state.dart';
import '../models/sky_mask_data.dart';

/// Abstract interface for sky detection implementations.
///
/// Produces a [SkyMaskData] from a camera frame and sensor readings.
/// Implementations decide HOW to detect sky (color, terrain, ML, combined).
///
/// Implementations:
/// - `HsvSkyDetector` -- wraps existing auto-calibrating HSV logic
/// - `TerrainSkyDetector` -- uses HorizonProfile + heading + pitch (Phase 2b)
/// - `CombinedSkyDetector` -- terrain sets horizon, HSV catches obstacles (Phase 2b)
///
/// Note: Uses [CameraImage] from the camera package directly for pragmatism.
/// This couples the interface to the camera package but avoids creating a
/// wrapper type that adds no value right now.
abstract class SkyDetector {
  /// Detects sky regions in the given camera frame.
  ///
  /// [frame]: The camera image to analyze.
  /// [sensors]: Current compass heading and pitch.
  /// [horizon]: Optional terrain horizon profile (only terrain/combined need this).
  ///
  /// Returns a [SkyMaskData] with per-pixel sky/not-sky classification.
  Future<SkyMaskData> detect({
    required CameraImage frame,
    required SensorState sensors,
    HorizonProfile? horizon,
  });

  /// Human-readable name for debug overlay display.
  String get name;
}
