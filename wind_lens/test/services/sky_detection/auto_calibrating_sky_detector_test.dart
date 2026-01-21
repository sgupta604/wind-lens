import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/services/sky_detection/auto_calibrating_sky_detector.dart';
import 'package:wind_lens/services/sky_detection/sky_mask.dart';

void main() {
  group('AutoCalibratingSkyDetector', () {
    late AutoCalibratingSkyDetector detector;

    setUp(() {
      detector = AutoCalibratingSkyDetector();
    });

    group('initial state', () {
      test('implements SkyMask interface', () {
        expect(detector, isA<SkyMask>());
      });

      test('isCalibrated returns false initially', () {
        expect(detector.isCalibrated, false);
      });

      test('needsCalibration returns true initially', () {
        expect(detector.needsCalibration, true);
      });
    });

    group('fallback behavior (uncalibrated)', () {
      test('skyFraction uses fallback when not calibrated', () {
        // Update pitch to trigger fallback calculation
        detector.updatePitch(45.0);

        // Should return a value from PitchBasedSkyMask fallback
        final skyFraction = detector.skyFraction;

        expect(skyFraction, greaterThan(0.0));
        expect(skyFraction, lessThanOrEqualTo(1.0));
      });

      test('skyFraction returns 0 when pitch is below threshold', () {
        detector.updatePitch(5.0); // Below min pitch threshold

        expect(detector.skyFraction, closeTo(0.0, 0.01));
      });

      test('isPointInSky uses fallback when not calibrated', () {
        detector.updatePitch(45.0);
        final skyFraction = detector.skyFraction;

        // Point in upper part of screen (should be in sky based on pitch)
        final inSky = detector.isPointInSky(0.5, 0.1);

        // With pitch 45, skyFraction should be significant
        if (skyFraction > 0.1) {
          expect(inSky, true);
        }

        // Point at bottom should not be in sky
        final notInSky = detector.isPointInSky(0.5, 0.99);
        expect(notInSky, false);
      });

      test('isPointInSky returns false when no sky (low pitch)', () {
        detector.updatePitch(0.0);

        expect(detector.isPointInSky(0.5, 0.1), false);
        expect(detector.isPointInSky(0.5, 0.5), false);
        expect(detector.isPointInSky(0.5, 0.9), false);
      });
    });

    group('updatePitch', () {
      test('stores pitch value', () {
        detector.updatePitch(30.0);

        // We can verify through fallback behavior
        expect(detector.skyFraction, greaterThan(0.0));
      });

      test('updates sky fraction based on pitch', () {
        detector.updatePitch(20.0);
        final lowPitchFraction = detector.skyFraction;

        detector.updatePitch(60.0);
        final highPitchFraction = detector.skyFraction;

        expect(highPitchFraction, greaterThan(lowPitchFraction));
      });
    });

    group('calibration trigger', () {
      test('does not calibrate when pitch < 45 degrees', () {
        detector.updatePitch(30.0);

        // Simulate frame processing - can't actually test without CameraImage
        // But we can verify the detector is still uncalibrated
        expect(detector.isCalibrated, false);
      });

      test('calibration threshold is 45 degrees', () {
        // This test verifies the constant value
        expect(AutoCalibratingSkyDetector.calibrationPitchThreshold, 45.0);
      });
    });

    group('recalibration', () {
      test('recalibration interval is 5 minutes', () {
        expect(
          AutoCalibratingSkyDetector.recalibrationInterval,
          const Duration(minutes: 5),
        );
      });

      test('needsCalibration returns true when never calibrated', () {
        expect(detector.needsCalibration, true);
      });
    });

    group('configuration constants', () {
      test('sample region top is 10%', () {
        expect(AutoCalibratingSkyDetector.sampleRegionTop, 0.1);
      });

      test('sample region bottom is 40%', () {
        expect(AutoCalibratingSkyDetector.sampleRegionBottom, 0.4);
      });

      test('detection threshold is reasonable', () {
        expect(AutoCalibratingSkyDetector.detectionThreshold, greaterThan(0.0));
        expect(AutoCalibratingSkyDetector.detectionThreshold, lessThan(1.0));
      });

      test('minimum position weight is reasonable', () {
        expect(AutoCalibratingSkyDetector.minPositionWeight, greaterThan(0.0));
        expect(AutoCalibratingSkyDetector.minPositionWeight, lessThan(0.5));
      });
    });

    group('mask dimensions', () {
      test('mask width is 128', () {
        expect(AutoCalibratingSkyDetector.maskWidth, 128);
      });

      test('mask height is 96', () {
        expect(AutoCalibratingSkyDetector.maskHeight, 96);
      });
    });

    group('SkyMask interface compliance', () {
      test('skyFraction returns value in valid range', () {
        detector.updatePitch(45.0);

        final fraction = detector.skyFraction;

        expect(fraction, greaterThanOrEqualTo(0.0));
        expect(fraction, lessThanOrEqualTo(1.0));
      });

      test('isPointInSky handles edge coordinates', () {
        detector.updatePitch(60.0);

        // Test edge coordinates - should not crash
        detector.isPointInSky(0.0, 0.0); // Top-left
        detector.isPointInSky(1.0, 0.0); // Top-right
        detector.isPointInSky(0.0, 1.0); // Bottom-left
        detector.isPointInSky(1.0, 1.0); // Bottom-right

        // No exceptions means it handles edges correctly
        expect(true, true);
      });

      test('isPointInSky handles negative coordinates gracefully', () {
        detector.updatePitch(60.0);

        // Should not crash with slightly negative values
        final result = detector.isPointInSky(-0.01, -0.01);
        expect(result, isA<bool>());
      });

      test('isPointInSky handles coordinates > 1.0 gracefully', () {
        detector.updatePitch(60.0);

        // Should not crash with slightly over 1.0 values
        final result = detector.isPointInSky(1.01, 1.01);
        expect(result, isA<bool>());
      });
    });

    group('calibration state machine', () {
      test('transitions from uncalibrated state correctly', () {
        // Initially uncalibrated
        expect(detector.isCalibrated, false);
        expect(detector.needsCalibration, true);

        // After setting pitch high enough (but without frame processing)
        // Should still be uncalibrated
        detector.updatePitch(60.0);
        expect(detector.isCalibrated, false);
      });
    });

    group('manual calibration (for testing)', () {
      test('calibrateManually sets calibrated state', () {
        expect(detector.isCalibrated, false);

        // Use the test-only manual calibration method
        detector.calibrateManually([
          _TestHSV(200.0, 0.4, 0.9),
          _TestHSV(198.0, 0.42, 0.88),
          _TestHSV(202.0, 0.38, 0.92),
        ]);

        expect(detector.isCalibrated, true);
        expect(detector.needsCalibration, false);
      });

      test('isPointInSky uses calibrated mask after manual calibration', () {
        detector.updatePitch(60.0);

        // Calibrate with sky blue profile
        detector.calibrateManually(List.generate(
          100,
          (_) => _TestHSV(200.0, 0.4, 0.9),
        ));

        // After calibration, isPointInSky should use learned profile
        // The exact behavior depends on the mask, but it should not crash
        final result = detector.isPointInSky(0.5, 0.2);
        expect(result, isA<bool>());
      });

      test('needsCalibration returns false immediately after calibration', () {
        detector.calibrateManually([
          _TestHSV(200.0, 0.4, 0.9),
        ]);

        expect(detector.needsCalibration, false);
      });
    });
  });
}

/// Helper class to create HSV-like objects for testing calibrateManually
class _TestHSV {
  final double h;
  final double s;
  final double v;

  _TestHSV(this.h, this.s, this.v);
}
