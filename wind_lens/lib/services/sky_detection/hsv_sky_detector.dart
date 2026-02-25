import 'package:camera/camera.dart';

import '../../core/models/horizon_profile.dart';
import '../../core/models/sensor_state.dart';
import '../../core/models/sky_mask_data.dart';
import '../../core/services/sky_detector.dart';
import 'auto_calibrating_sky_detector.dart';

/// Implementation of [SkyDetector] that wraps [AutoCalibratingSkyDetector].
///
/// Delegates sky detection to the existing HSV-based auto-calibrating detector
/// and converts its output to the new [SkyMaskData] Freezed model.
///
/// The internal detector processes frames at 128x96 resolution. This wrapper
/// reads the cached mask directly from [AutoCalibratingSkyDetector.cachedMask]
/// and converts the Uint8List (0/255 bytes) to [List<bool>] for [SkyMaskData.pixels].
///
/// ## Usage
/// ```dart
/// final detector = HsvSkyDetector();
/// final skyMask = await detector.detect(
///   frame: cameraImage,
///   sensors: sensorState,
/// );
/// // skyMask.isPointInSky(0.5, 0.3) -> true if that point is sky
/// ```
class HsvSkyDetector implements SkyDetector {
  /// The underlying auto-calibrating detector.
  final AutoCalibratingSkyDetector _detector;

  /// Creates an HsvSkyDetector.
  ///
  /// Optionally accepts a pre-created [AutoCalibratingSkyDetector] for testing.
  HsvSkyDetector({AutoCalibratingSkyDetector? detector})
      : _detector = detector ?? AutoCalibratingSkyDetector();

  @override
  String get name => 'HSV Auto-Calibrating';

  /// Whether the underlying detector has been calibrated.
  bool get isCalibrated => _detector.isCalibrated;

  /// Current sky fraction (0.0 to 1.0) from the underlying detector.
  double get skyFraction => _detector.skyFraction;

  /// Forces the underlying detector to recalibrate on the next frame.
  void forceRecalibrate() => _detector.forceRecalibrate();

  /// Synchronous, zero-allocation frame processing for the hot path.
  ///
  /// Calls updatePitch + processFrame on the underlying detector directly.
  /// The cached mask is updated in-place (Uint8List, pre-allocated).
  /// Use [buildSkyMaskData] only when you need a SkyMaskData snapshot.
  void updatePitchAndProcess(CameraImage image, double pitch) {
    _detector.updatePitch(pitch);
    _detector.processFrame(image);
  }

  /// Builds a SkyMaskData snapshot from the current cached mask.
  ///
  /// Call this infrequently (e.g., when sky fraction changes) — NOT every frame.
  /// The List<bool> allocation happens here, so avoid calling in the hot path.
  SkyMaskData buildSkyMaskData() {
    final w = AutoCalibratingSkyDetector.maskWidth;
    final h = AutoCalibratingSkyDetector.maskHeight;
    final rawMask = _detector.cachedMask;

    final List<bool> pixels;
    if (rawMask != null && rawMask.length == w * h) {
      pixels = List<bool>.generate(w * h, (i) => rawMask[i] > 127);
    } else {
      pixels = List<bool>.filled(w * h, false);
    }

    return SkyMaskData(
      width: w,
      height: h,
      pixels: pixels,
      method: SkyDetectionMethod.hsv,
    );
  }

  @override
  Future<SkyMaskData> detect({
    required CameraImage frame,
    required SensorState sensors,
    HorizonProfile? horizon,
  }) async {
    // 1. Update pitch from sensor data
    _detector.updatePitch(sensors.pitch);

    // 2. Process the frame (calibrates if needed, then generates mask)
    _detector.processFrame(frame);

    // 3. Extract mask data directly from the cached mask (Uint8List).
    //    Each byte is 0 (not sky) or 255 (sky). Convert to List<bool>.
    //    This replaces 12,288 isPointInSky() method calls with a single
    //    array traversal — major performance win for 60 FPS rendering.
    final w = AutoCalibratingSkyDetector.maskWidth;
    final h = AutoCalibratingSkyDetector.maskHeight;
    final rawMask = _detector.cachedMask;
    final List<bool> pixels;

    if (rawMask != null && rawMask.length == w * h) {
      pixels = List<bool>.generate(w * h, (i) => rawMask[i] > 127);
    } else {
      pixels = List<bool>.filled(w * h, false);
    }

    return SkyMaskData(
      width: w,
      height: h,
      pixels: pixels,
      method: SkyDetectionMethod.hsv,
    );
  }
}
