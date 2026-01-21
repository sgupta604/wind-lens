import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/services/sky_detection/pitch_based_sky_mask.dart';

void main() {
  group('PitchBasedSkyMask', () {
    late PitchBasedSkyMask skyMask;

    setUp(() {
      skyMask = PitchBasedSkyMask();
    });

    group('skyFraction', () {
      test('returns 0 when pitch is below minimum (10 degrees)', () {
        // Pitch of 5 degrees is below the 10 degree minimum
        skyMask.updatePitch(5.0);

        expect(skyMask.skyFraction, equals(0.0));
      });

      test('returns 0 when pitch is exactly at minimum (10 degrees)', () {
        // At exactly 10 degrees, fraction should be 0
        skyMask.updatePitch(10.0);

        expect(skyMask.skyFraction, equals(0.0));
      });

      test('returns 0.95 when pitch is above maximum (70 degrees)', () {
        // Pitch above 70 degrees should return max sky fraction
        skyMask.updatePitch(80.0);

        expect(skyMask.skyFraction, equals(0.95));
      });

      test('returns 0.95 when pitch is exactly at maximum (70 degrees)', () {
        // At exactly 70 degrees, fraction should be 0.95
        skyMask.updatePitch(70.0);

        expect(skyMask.skyFraction, equals(0.95));
      });

      test('returns linearly interpolated value at midpoint (40 degrees)', () {
        // Midpoint between 10 and 70 is 40 degrees
        // Expected: (40 - 10) / (70 - 10) * 0.95 = 30/60 * 0.95 = 0.475
        skyMask.updatePitch(40.0);

        expect(skyMask.skyFraction, closeTo(0.475, 0.001));
      });

      test('clamps to valid range for negative pitch', () {
        // Negative pitch should return 0
        skyMask.updatePitch(-10.0);

        expect(skyMask.skyFraction, equals(0.0));
      });

      test('clamps to valid range for extreme positive pitch', () {
        // Very high pitch (e.g., 90 degrees) should still return max 0.95
        skyMask.updatePitch(90.0);

        expect(skyMask.skyFraction, equals(0.95));
      });
    });

    group('isPointInSky', () {
      test('returns true for points in top portion of screen', () {
        // Set pitch to 50 degrees
        // skyFraction = (50 - 10) / 60 * 0.95 = 40/60 * 0.95 ~= 0.633
        skyMask.updatePitch(50.0);
        final skyFraction = skyMask.skyFraction;

        // Point at Y=0.3 should be in sky (0.3 < 0.633)
        expect(skyMask.isPointInSky(0.5, 0.3), isTrue);
        expect(0.3, lessThan(skyFraction)); // Verify our test makes sense
      });

      test('returns false for points in bottom portion of screen', () {
        // Set pitch to 50 degrees (skyFraction ~= 0.633)
        skyMask.updatePitch(50.0);
        final skyFraction = skyMask.skyFraction;

        // Point at Y=0.8 should NOT be in sky (0.8 > 0.633)
        expect(skyMask.isPointInSky(0.5, 0.8), isFalse);
        expect(0.8, greaterThan(skyFraction)); // Verify our test makes sense
      });

      test('returns same value regardless of X coordinate', () {
        // Set up a mid-range pitch
        skyMask.updatePitch(50.0);

        // Points at same Y but different X should return same result
        final resultLeft = skyMask.isPointInSky(0.1, 0.3);
        final resultCenter = skyMask.isPointInSky(0.5, 0.3);
        final resultRight = skyMask.isPointInSky(0.9, 0.3);

        expect(resultLeft, equals(resultCenter));
        expect(resultCenter, equals(resultRight));
      });

      test('returns false when skyFraction is 0', () {
        // Pitch below minimum means no sky visible
        skyMask.updatePitch(5.0);

        expect(skyMask.skyFraction, equals(0.0));
        // Even the very top of screen (Y=0) should not be sky
        expect(skyMask.isPointInSky(0.5, 0.0), isFalse);
        expect(skyMask.isPointInSky(0.5, 0.01), isFalse);
      });

      test('returns true for almost entire screen when skyFraction is 0.95', () {
        // Pitch at maximum means 95% of screen is sky
        skyMask.updatePitch(80.0);

        expect(skyMask.skyFraction, equals(0.95));
        // Points in top 95% should be sky
        expect(skyMask.isPointInSky(0.5, 0.0), isTrue);
        expect(skyMask.isPointInSky(0.5, 0.5), isTrue);
        expect(skyMask.isPointInSky(0.5, 0.94), isTrue);
        // Points below 95% should NOT be sky
        expect(skyMask.isPointInSky(0.5, 0.96), isFalse);
      });
    });

    group('updatePitch', () {
      test('changes skyFraction value', () {
        // Initial sky fraction at pitch 10 (minimum)
        skyMask.updatePitch(10.0);
        final initialFraction = skyMask.skyFraction;

        // Update to pitch 70 (maximum)
        skyMask.updatePitch(70.0);
        final updatedFraction = skyMask.skyFraction;

        // Fractions should be different
        expect(initialFraction, equals(0.0));
        expect(updatedFraction, equals(0.95));
        expect(updatedFraction, isNot(equals(initialFraction)));
      });
    });
  });
}
