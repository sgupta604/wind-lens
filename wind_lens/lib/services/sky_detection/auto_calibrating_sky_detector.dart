import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../models/hsv.dart';
import '../../utils/color_utils.dart';
import 'hsv_histogram.dart';
import 'pitch_based_sky_mask.dart';
import 'sky_mask.dart';

/// Level 2a sky detection using auto-calibrating color-based detection.
///
/// This detector learns the sky color profile by sampling pixels when the
/// user points their phone upward (pitch > 45 degrees). It then uses this
/// learned profile to detect sky regions in subsequent frames.
///
/// ## Calibration Flow:
/// 1. User points phone up (pitch > calibrationPitchThreshold)
/// 2. Detector samples top 10-40% of camera frame
/// 3. Converts samples to HSV and builds statistical profile
/// 4. Uses profile for per-pixel sky detection
///
/// ## Fallback Behavior:
/// When not calibrated, falls back to [PitchBasedSkyMask] for basic detection.
///
/// ## Performance:
/// - Processes frames at 128x96 resolution for speed
/// - Target: < 16ms per frame for 60 FPS
/// - Caches mask for isPointInSky queries
///
/// ## Usage:
/// ```dart
/// final detector = AutoCalibratingSkyDetector();
/// detector.updatePitch(currentPitch);
/// detector.processFrame(cameraImage);
/// final isSky = detector.isPointInSky(x, y);
/// ```
class AutoCalibratingSkyDetector implements SkyMask {
  // ============= Configuration Constants =============

  /// Time between automatic recalibrations.
  static const Duration recalibrationInterval = Duration(minutes: 5);

  /// Minimum pitch (degrees) required to trigger calibration.
  static const double calibrationPitchThreshold = 45.0;

  /// Top of the sampling region (as fraction of frame height).
  static const double sampleRegionTop = 0.1;

  /// Bottom of the sampling region (as fraction of frame height).
  static const double sampleRegionBottom = 0.4;

  /// Threshold for classifying a pixel as sky (0.0-1.0).
  static const double detectionThreshold = 0.4;

  /// Minimum position weight to process a pixel.
  /// Pixels below this threshold (bottom of frame) are skipped.
  static const double minPositionWeight = 0.2;

  /// Width of the downscaled mask for processing.
  static const int maskWidth = 128;

  /// Height of the downscaled mask for processing.
  static const int maskHeight = 96;

  // ============= State Fields =============

  /// Learned sky color profile (null until calibrated).
  HSVHistogram? _skyHistogram;

  /// Timestamp of last calibration.
  DateTime? _lastCalibration;

  /// Current device pitch in degrees.
  double _pitch = 0;

  /// Fallback detector for uncalibrated state.
  final PitchBasedSkyMask _fallback = PitchBasedSkyMask();

  /// Cached sky mask at reduced resolution.
  /// Each byte is 0 (not sky) or 255 (sky).
  Uint8List? _cachedMask;

  /// Cached sky fraction (0.0-1.0).
  double _cachedSkyFraction = 0.0;

  /// Creates a new auto-calibrating sky detector.
  AutoCalibratingSkyDetector();

  // ============= Calibration State =============

  /// Returns true if the detector has been calibrated.
  bool get isCalibrated => _skyHistogram != null;

  /// Returns true if calibration is needed.
  ///
  /// Calibration is needed when:
  /// - Never calibrated
  /// - Last calibration was more than [recalibrationInterval] ago
  bool get needsCalibration {
    if (_skyHistogram == null) return true;
    if (_lastCalibration == null) return true;

    final elapsed = DateTime.now().difference(_lastCalibration!);
    return elapsed > recalibrationInterval;
  }

  // ============= Pitch Updates =============

  /// Updates the current device pitch angle.
  ///
  /// Call this whenever the compass/accelerometer provides new pitch data.
  /// The pitch affects both the fallback sky mask and calibration triggering.
  void updatePitch(double pitchDegrees) {
    _pitch = pitchDegrees;
    _fallback.updatePitch(pitchDegrees);
  }

  // ============= SkyMask Interface =============

  @override
  double get skyFraction {
    if (!isCalibrated || _cachedMask == null) {
      return _fallback.skyFraction;
    }
    return _cachedSkyFraction;
  }

  @override
  bool isPointInSky(double normalizedX, double normalizedY) {
    if (!isCalibrated || _cachedMask == null) {
      return _fallback.isPointInSky(normalizedX, normalizedY);
    }

    // Clamp coordinates to valid range
    final clampedX = normalizedX.clamp(0.0, 0.999);
    final clampedY = normalizedY.clamp(0.0, 0.999);

    // Convert normalized coordinates to mask indices
    final maskX = (clampedX * maskWidth).floor();
    final maskY = (clampedY * maskHeight).floor();
    final index = maskY * maskWidth + maskX;

    // Check bounds (safety check)
    if (index < 0 || index >= _cachedMask!.length) {
      return _fallback.isPointInSky(normalizedX, normalizedY);
    }

    return _cachedMask![index] > 127;
  }

  // ============= Frame Processing =============

  /// Processes a camera frame for sky detection.
  ///
  /// This method:
  /// 1. Checks if calibration is needed and pitch is high enough
  /// 2. If so, performs calibration from frame
  /// 3. If calibrated, generates sky mask from frame
  ///
  /// Call this for each camera frame. The method is optimized to
  /// complete in < 16ms on typical mobile devices.
  void processFrame(CameraImage image) {
    // Check if we should calibrate
    if (needsCalibration && _pitch >= calibrationPitchThreshold) {
      _calibrateFromFrame(image);
    }

    // If calibrated, generate detection mask
    if (isCalibrated) {
      _generateMask(image);
    }
  }

  // ============= Calibration Logic =============

  /// Calibrates the detector from a camera frame.
  ///
  /// Samples pixels from the top 10-40% of the frame and builds
  /// an HSV histogram for sky color matching.
  void _calibrateFromFrame(CameraImage image) {
    final samples = <HSV>[];
    final width = image.width;
    final height = image.height;

    // Determine image format and extract pixels
    final isIOS = !kIsWeb && Platform.isIOS;

    if (isIOS) {
      // iOS: BGRA8888 format
      _samplePixelsBGRA(image, width, height, samples);
    } else {
      // Android: YUV420 format
      _samplePixelsYUV(image, width, height, samples);
    }

    if (samples.length < 10) {
      debugPrint('Sky calibration: insufficient samples (${samples.length})');
      return;
    }

    // Build histogram from samples
    _skyHistogram = HSVHistogram.fromSamples(samples);
    _lastCalibration = DateTime.now();

    debugPrint('Sky calibrated: ${samples.length} samples, profile=$_skyHistogram');
  }

  /// Samples pixels from BGRA8888 format (iOS).
  void _samplePixelsBGRA(
    CameraImage image,
    int width,
    int height,
    List<HSV> samples,
  ) {
    final bytes = image.planes[0].bytes;
    final bytesPerRow = image.planes[0].bytesPerRow;

    // Sample from top 10-40% of frame
    final startY = (height * sampleRegionTop).floor();
    final endY = (height * sampleRegionBottom).floor();

    // Sample every 10th pixel for speed
    const stride = 10;

    for (int y = startY; y < endY; y += stride) {
      for (int x = 0; x < width; x += stride) {
        final idx = y * bytesPerRow + x * 4;
        if (idx + 3 >= bytes.length) continue;

        // BGRA format
        final b = bytes[idx];
        final g = bytes[idx + 1];
        final r = bytes[idx + 2];
        // final a = bytes[idx + 3]; // Alpha not needed

        samples.add(ColorUtils.rgbToHsv(r, g, b));
      }
    }
  }

  /// Samples pixels from YUV420 format (Android).
  void _samplePixelsYUV(
    CameraImage image,
    int width,
    int height,
    List<HSV> samples,
  ) {
    if (image.planes.length < 3) return;

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    // Sample from top 10-40% of frame
    final startY = (height * sampleRegionTop).floor();
    final endY = (height * sampleRegionBottom).floor();

    // Sample every 10th pixel for speed
    const stride = 10;

    for (int imgY = startY; imgY < endY; imgY += stride) {
      for (int imgX = 0; imgX < width; imgX += stride) {
        final yIndex = imgY * yRowStride + imgX;
        if (yIndex >= yPlane.length) continue;

        // U and V are subsampled 2x2
        final uvY = imgY ~/ 2;
        final uvX = imgX ~/ 2;
        final uvIndex = uvY * uvRowStride + uvX * uvPixelStride;

        if (uvIndex >= uPlane.length || uvIndex >= vPlane.length) continue;

        final y = yPlane[yIndex];
        final u = uPlane[uvIndex];
        final v = vPlane[uvIndex];

        final rgb = ColorUtils.yuvToRgb(y, u, v);
        samples.add(ColorUtils.rgbToHsv(rgb[0], rgb[1], rgb[2]));
      }
    }
  }

  // ============= Mask Generation =============

  /// Generates a sky mask from the current frame.
  void _generateMask(CameraImage image) {
    // Allocate mask if needed
    _cachedMask ??= Uint8List(maskWidth * maskHeight);

    final width = image.width;
    final height = image.height;

    // Determine image format
    final isIOS = !kIsWeb && Platform.isIOS;

    int skyPixelCount = 0;
    int totalProcessed = 0;

    // Process at reduced resolution
    for (int maskY = 0; maskY < maskHeight; maskY++) {
      // Calculate position weight (sky prior based on position)
      final normalizedY = maskY / maskHeight;
      final positionWeight = _calculatePositionWeight(normalizedY);

      // Skip bottom of frame (position weight too low)
      if (positionWeight < minPositionWeight) {
        // Mark as not sky
        for (int maskX = 0; maskX < maskWidth; maskX++) {
          _cachedMask![maskY * maskWidth + maskX] = 0;
        }
        continue;
      }

      for (int maskX = 0; maskX < maskWidth; maskX++) {
        // Map mask coordinates to image coordinates
        final imgX = (maskX * width / maskWidth).floor();
        final imgY = (maskY * height / maskHeight).floor();

        // Get pixel HSV
        final hsv = isIOS
            ? _getPixelHsvBGRA(image, imgX, imgY)
            : _getPixelHsvYUV(image, imgX, imgY);

        if (hsv == null) {
          _cachedMask![maskY * maskWidth + maskX] = 0;
          continue;
        }

        // Calculate combined score
        final colorScore = _skyHistogram!.matchScore(hsv);
        final combinedScore = colorScore * positionWeight;

        // Apply threshold
        final isSky = combinedScore >= detectionThreshold;
        _cachedMask![maskY * maskWidth + maskX] = isSky ? 255 : 0;

        if (isSky) skyPixelCount++;
        totalProcessed++;
      }
    }

    // Update cached sky fraction
    _cachedSkyFraction = totalProcessed > 0
        ? skyPixelCount / totalProcessed
        : _fallback.skyFraction;

    debugPrint('Sky fraction: ${(_cachedSkyFraction * 100).toStringAsFixed(1)}%');
  }

  /// Calculates position-based sky prior.
  ///
  /// Returns higher weight for top of frame, lower for bottom.
  double _calculatePositionWeight(double normalizedY) {
    // Linear ramp: 1.0 at top, 0.0 at bottom
    // With adjustment for typical sky distribution
    if (normalizedY < 0.2) return 1.0;
    if (normalizedY > 0.9) return 0.0;

    return 1.0 - (normalizedY - 0.2) / 0.7;
  }

  /// Gets pixel HSV from BGRA image.
  HSV? _getPixelHsvBGRA(CameraImage image, int x, int y) {
    final bytes = image.planes[0].bytes;
    final bytesPerRow = image.planes[0].bytesPerRow;

    final idx = y * bytesPerRow + x * 4;
    if (idx + 3 >= bytes.length) return null;

    final b = bytes[idx];
    final g = bytes[idx + 1];
    final r = bytes[idx + 2];

    return ColorUtils.rgbToHsv(r, g, b);
  }

  /// Gets pixel HSV from YUV420 image.
  HSV? _getPixelHsvYUV(CameraImage image, int x, int y) {
    if (image.planes.length < 3) return null;

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final yIndex = y * yRowStride + x;
    if (yIndex >= yPlane.length) return null;

    final uvY = y ~/ 2;
    final uvX = x ~/ 2;
    final uvIndex = uvY * uvRowStride + uvX * uvPixelStride;

    if (uvIndex >= uPlane.length || uvIndex >= vPlane.length) return null;

    final yVal = yPlane[yIndex];
    final uVal = uPlane[uvIndex];
    final vVal = vPlane[uvIndex];

    final rgb = ColorUtils.yuvToRgb(yVal, uVal, vVal);
    return ColorUtils.rgbToHsv(rgb[0], rgb[1], rgb[2]);
  }

  // ============= Testing Support =============

  /// Manually calibrates the detector with provided HSV samples.
  ///
  /// This method is primarily for testing purposes, allowing calibration
  /// without a real camera image.
  void calibrateManually(List<dynamic> samples) {
    final hsvSamples = samples.map((s) {
      if (s is HSV) return s;
      // Handle test HSV-like objects
      return HSV(
        (s as dynamic).h as double,
        (s as dynamic).s as double,
        (s as dynamic).v as double,
      );
    }).toList();

    if (hsvSamples.isEmpty) return;

    _skyHistogram = HSVHistogram.fromSamples(hsvSamples);
    _lastCalibration = DateTime.now();

    // Create a default mask (all sky for top, no sky for bottom)
    _cachedMask = Uint8List(maskWidth * maskHeight);
    for (int y = 0; y < maskHeight; y++) {
      final normalizedY = y / maskHeight;
      final isSky = normalizedY < 0.6; // Top 60% is sky
      for (int x = 0; x < maskWidth; x++) {
        _cachedMask![y * maskWidth + x] = isSky ? 255 : 0;
      }
    }
    _cachedSkyFraction = 0.6;

    debugPrint('Sky calibrated manually: ${hsvSamples.length} samples');
  }
}
