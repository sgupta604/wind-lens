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
      test('does not calibrate when pitch < 25 degrees', () {
        detector.updatePitch(20.0);

        // Simulate frame processing - can't actually test without CameraImage
        // But we can verify the detector is still uncalibrated
        expect(detector.isCalibrated, false);
      });

      test('calibration threshold is 25 degrees', () {
        // This test verifies the constant value
        // Lowered from 45 to 25 for BUG-002.5 fix - natural viewing angle
        expect(AutoCalibratingSkyDetector.calibrationPitchThreshold, 25.0);
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
      test('sample region top is 5%', () {
        // Changed from 10% to 5% for BUG-002.5 fix - safer sky sampling at lower angles
        expect(AutoCalibratingSkyDetector.sampleRegionTop, 0.05);
      });

      test('sample region bottom base is 40% (but now dynamic)', () {
        // sampleRegionBottom is deprecated/reference - actual bottom is calculated
        // by _getSampleRegionBottom() based on pitch
        // ignore: deprecated_member_use_from_same_package
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

    group('dynamic sample region', () {
      // Tests for _getSampleRegionBottom() dynamic behavior based on pitch
      // This feature was added for BUG-002.5 fix to avoid sampling buildings
      // at lower pitch angles.

      test('getSampleRegionBottom returns 0.20 for pitch 25-34', () {
        // At lower pitch angles, sample conservatively (5-20% of frame)
        detector.updatePitch(25.0);
        expect(detector.getSampleRegionBottom(), 0.20);

        detector.updatePitch(30.0);
        expect(detector.getSampleRegionBottom(), 0.20);

        detector.updatePitch(34.0);
        expect(detector.getSampleRegionBottom(), 0.20);
      });

      test('getSampleRegionBottom returns 0.30 for pitch 35-44', () {
        // At moderate pitch angles, sample moderately (5-30% of frame)
        detector.updatePitch(35.0);
        expect(detector.getSampleRegionBottom(), 0.30);

        detector.updatePitch(40.0);
        expect(detector.getSampleRegionBottom(), 0.30);

        detector.updatePitch(44.0);
        expect(detector.getSampleRegionBottom(), 0.30);
      });

      test('getSampleRegionBottom returns 0.40 for pitch 45-59', () {
        // At higher pitch angles, use original behavior (5-40% of frame)
        detector.updatePitch(45.0);
        expect(detector.getSampleRegionBottom(), 0.40);

        detector.updatePitch(50.0);
        expect(detector.getSampleRegionBottom(), 0.40);

        detector.updatePitch(59.0);
        expect(detector.getSampleRegionBottom(), 0.40);
      });

      test('getSampleRegionBottom returns 0.50 for pitch 60+', () {
        // Looking quite high - sample aggressively (5-50% of frame)
        detector.updatePitch(60.0);
        expect(detector.getSampleRegionBottom(), 0.50);

        detector.updatePitch(70.0);
        expect(detector.getSampleRegionBottom(), 0.50);

        detector.updatePitch(90.0);
        expect(detector.getSampleRegionBottom(), 0.50);
      });

      test('getSampleRegionBottom returns 0.15 for pitch below 25', () {
        // Very low pitch - very conservative sampling (5-15% of frame)
        detector.updatePitch(24.0);
        expect(detector.getSampleRegionBottom(), 0.15);

        detector.updatePitch(10.0);
        expect(detector.getSampleRegionBottom(), 0.15);

        detector.updatePitch(0.0);
        expect(detector.getSampleRegionBottom(), 0.15);
      });

      test('sample region boundary conditions', () {
        // Test exact boundary values
        detector.updatePitch(24.999);
        expect(detector.getSampleRegionBottom(), 0.15); // < 25

        detector.updatePitch(25.0);
        expect(detector.getSampleRegionBottom(), 0.20); // >= 25

        detector.updatePitch(34.999);
        expect(detector.getSampleRegionBottom(), 0.20); // < 35

        detector.updatePitch(35.0);
        expect(detector.getSampleRegionBottom(), 0.30); // >= 35

        detector.updatePitch(44.999);
        expect(detector.getSampleRegionBottom(), 0.30); // < 45

        detector.updatePitch(45.0);
        expect(detector.getSampleRegionBottom(), 0.40); // >= 45

        detector.updatePitch(59.999);
        expect(detector.getSampleRegionBottom(), 0.40); // < 60

        detector.updatePitch(60.0);
        expect(detector.getSampleRegionBottom(), 0.50); // >= 60
      });
    });

    group('calibration at lower pitch', () {
      test('calibration can be attempted at 25 degree pitch', () {
        // With lowered threshold, calibration should be possible at 25 degrees
        detector.updatePitch(25.0);

        // Cannot actually trigger calibration without CameraImage,
        // but we verify the pitch threshold allows it
        expect(
          AutoCalibratingSkyDetector.calibrationPitchThreshold,
          lessThanOrEqualTo(25.0),
        );
      });

      test('calibration uses smaller sample region at lower pitch', () {
        // At 25-degree pitch, should sample conservatively
        detector.updatePitch(25.0);
        final lowPitchRegion = detector.getSampleRegionBottom();

        // At 60-degree pitch, should sample more aggressively
        detector.updatePitch(60.0);
        final highPitchRegion = detector.getSampleRegionBottom();

        expect(lowPitchRegion, lessThan(highPitchRegion));
        expect(lowPitchRegion, 0.20); // Conservative at 25 degrees
        expect(highPitchRegion, 0.50); // Aggressive at 60 degrees
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

    group('position weight (for testing)', () {
      // Tests for position weight calculation
      // Added as part of BUG-006 fix: reduced top bias to rely more on color matching

      test('getPositionWeight at top (0.0) returns 0.85 (not 1.0)', () {
        // Reduced from 1.0 to 0.85 to rely more on color matching
        final weight = detector.getPositionWeight(0.0);
        expect(weight, closeTo(0.85, 0.01));
      });

      test('getPositionWeight at y=0.1 returns 0.85', () {
        // Still in the top region (< 0.2)
        final weight = detector.getPositionWeight(0.1);
        expect(weight, closeTo(0.85, 0.01));
      });

      test('getPositionWeight at y=0.19 returns 0.85', () {
        // Just below the 0.2 threshold
        final weight = detector.getPositionWeight(0.19);
        expect(weight, closeTo(0.85, 0.01));
      });

      test('getPositionWeight at y=0.5 returns moderate value', () {
        // Middle of frame should have moderate weight
        final weight = detector.getPositionWeight(0.5);
        expect(weight, greaterThan(0.2));
        expect(weight, lessThan(0.7));
      });

      test('getPositionWeight at y=0.85 returns near zero', () {
        // Bottom threshold returns zero
        final weight = detector.getPositionWeight(0.85);
        expect(weight, closeTo(0.0, 0.01));
      });

      test('getPositionWeight at y=0.9 returns zero', () {
        // Below bottom threshold
        final weight = detector.getPositionWeight(0.9);
        expect(weight, closeTo(0.0, 0.01));
      });

      test('position weight decreases from top to bottom', () {
        // Weight should monotonically decrease
        final top = detector.getPositionWeight(0.0);
        final middle = detector.getPositionWeight(0.5);
        final bottom = detector.getPositionWeight(0.85);

        expect(top, greaterThan(middle));
        expect(middle, greaterThan(bottom));
      });
    });

    group('forceRecalibrate', () {
      // Tests for manual recalibration feature
      // Added as part of BUG-006 fix to allow users to trigger recalibration

      test('forceRecalibrate clears calibrated state', () {
        // First calibrate the detector
        detector.calibrateManually([
          _TestHSV(200.0, 0.4, 0.9),
          _TestHSV(198.0, 0.42, 0.88),
          _TestHSV(202.0, 0.38, 0.92),
        ]);
        expect(detector.isCalibrated, isTrue);

        // Force recalibration
        detector.forceRecalibrate();

        // Should no longer be calibrated
        expect(detector.isCalibrated, isFalse);
      });

      test('forceRecalibrate sets needsCalibration to true', () {
        // First calibrate the detector
        detector.calibrateManually([
          _TestHSV(200.0, 0.4, 0.9),
        ]);
        expect(detector.needsCalibration, isFalse);

        // Force recalibration
        detector.forceRecalibrate();

        // Should need recalibration
        expect(detector.needsCalibration, isTrue);
      });

      test('forceRecalibrate on uncalibrated detector does not throw', () {
        // Calling forceRecalibrate when not calibrated should be safe
        expect(() => detector.forceRecalibrate(), returnsNormally);
        expect(detector.isCalibrated, isFalse);
      });

      test('can recalibrate after forceRecalibrate', () {
        // Calibrate
        detector.calibrateManually([_TestHSV(200.0, 0.4, 0.9)]);
        expect(detector.isCalibrated, isTrue);

        // Force recalibrate
        detector.forceRecalibrate();
        expect(detector.isCalibrated, isFalse);

        // Calibrate again
        detector.calibrateManually([_TestHSV(210.0, 0.5, 0.85)]);
        expect(detector.isCalibrated, isTrue);
      });
    });

    group('sampling regions', () {
      // Tests for multi-region sampling constants and behavior
      // Added as part of BUG-006 fix (sky detection regression under overhangs)

      test('sampling regions list is not empty', () {
        // The detector should have multiple sampling regions defined
        expect(
          AutoCalibratingSkyDetector.samplingRegions.isNotEmpty,
          isTrue,
        );
      });

      test('sampling regions includes top center region', () {
        // Original sampling region should still be present
        final regions = AutoCalibratingSkyDetector.samplingRegions;
        final hasTopCenter = regions.any((r) =>
            r[0] >= 0.15 && // startX around 0.20
            r[1] <= 0.85 && // endX around 0.80
            r[2] <= 0.10 && // startY near top (0.05)
            r[3] <= 0.25); // endY in top portion (0.20)
        expect(hasTopCenter, isTrue);
      });

      test('sampling regions includes middle center region', () {
        // New region to sample from center of frame
        final regions = AutoCalibratingSkyDetector.samplingRegions;
        final hasMiddleCenter = regions.any((r) =>
            r[2] >= 0.25 && // startY in middle (0.30)
            r[3] <= 0.55); // endY before bottom half (0.50)
        expect(hasMiddleCenter, isTrue);
      });

      test('sampling regions covers multiple vertical positions', () {
        // Regions should sample from different Y positions
        final regions = AutoCalibratingSkyDetector.samplingRegions;
        final minYs = regions.map((r) => r[2]).toList();
        final uniqueRanges = minYs.toSet().length;
        // Should have at least 2 different vertical starting positions
        expect(uniqueRanges, greaterThanOrEqualTo(2));
      });

      test('all sampling regions have valid boundaries', () {
        // Each region should have valid [startX, endX, startY, endY]
        final regions = AutoCalibratingSkyDetector.samplingRegions;
        for (final region in regions) {
          expect(region.length, 4);
          expect(region[0], greaterThanOrEqualTo(0.0)); // startX >= 0
          expect(region[1], lessThanOrEqualTo(1.0)); // endX <= 1
          expect(region[0], lessThan(region[1])); // startX < endX
          expect(region[2], greaterThanOrEqualTo(0.0)); // startY >= 0
          expect(region[3], lessThanOrEqualTo(1.0)); // endY <= 1
          expect(region[2], lessThan(region[3])); // startY < endY
        }
      });

      test('sampling regions has at least 4 regions', () {
        // Per the plan: top center, middle center, top left, top right
        expect(
          AutoCalibratingSkyDetector.samplingRegions.length,
          greaterThanOrEqualTo(4),
        );
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
