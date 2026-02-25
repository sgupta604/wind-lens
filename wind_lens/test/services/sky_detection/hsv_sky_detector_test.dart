import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';
import 'package:wind_lens/core/services/sky_detector.dart';
import 'package:wind_lens/services/sky_detection/auto_calibrating_sky_detector.dart';
import 'package:wind_lens/services/sky_detection/hsv_sky_detector.dart';

void main() {
  group('HsvSkyDetector', () {
    late HsvSkyDetector detector;

    setUp(() {
      detector = HsvSkyDetector();
    });

    test('implements SkyDetector interface', () {
      expect(detector, isA<SkyDetector>());
    });

    test('name returns expected string', () {
      expect(detector.name, 'HSV Auto-Calibrating');
    });

    test('isCalibrated is false initially', () {
      expect(detector.isCalibrated, false);
    });

    test('accepts custom AutoCalibratingSkyDetector', () {
      final custom = AutoCalibratingSkyDetector();
      final customDetector = HsvSkyDetector(detector: custom);
      expect(customDetector, isA<SkyDetector>());
      expect(customDetector.name, 'HSV Auto-Calibrating');
    });

    test('mask dimensions match AutoCalibratingSkyDetector constants', () {
      // Verify that the dimensions used match the underlying detector's
      // constants (128x96)
      expect(AutoCalibratingSkyDetector.maskWidth, 128);
      expect(AutoCalibratingSkyDetector.maskHeight, 96);
    });

    test('SkyMaskData.fullSky default dimensions match detector dimensions',
        () {
      // Verify that the fullSky factory defaults match the detector dimensions
      final fullSky = SkyMaskData.fullSky();
      expect(fullSky.width, AutoCalibratingSkyDetector.maskWidth);
      expect(fullSky.height, AutoCalibratingSkyDetector.maskHeight);
    });

    // NOTE: Full detection testing (calling detect() with a CameraImage)
    // requires platform channels and is not possible in unit tests.
    // Integration tests on a real device would cover the full detect() flow.
    // The wrapper's logic is straightforward:
    //   1. updatePitch -> processFrame -> extract mask via isPointInSky loop
    //   2. Always returns SkyDetectionMethod.hsv
    //   3. Dimensions always 128x96
  });
}
