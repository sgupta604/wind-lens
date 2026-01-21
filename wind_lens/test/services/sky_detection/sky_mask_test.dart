import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/services/sky_detection/sky_mask.dart';
import 'package:wind_lens/services/sky_detection/pitch_based_sky_mask.dart';

/// Tests for the SkyMask interface contract.
///
/// These tests verify the interface behavior using a concrete implementation
/// (PitchBasedSkyMask). Any SkyMask implementation should satisfy these tests.
void main() {
  group('SkyMask interface', () {
    test('skyFraction is between 0.0 and 1.0', () {
      final SkyMask skyMask = PitchBasedSkyMask();

      // skyFraction should always be in valid range
      expect(skyMask.skyFraction, greaterThanOrEqualTo(0.0));
      expect(skyMask.skyFraction, lessThanOrEqualTo(1.0));
    });

    test('isPointInSky accepts normalized coordinates', () {
      final SkyMask skyMask = PitchBasedSkyMask();

      // Should accept any normalized coordinates without throwing
      expect(() => skyMask.isPointInSky(0.0, 0.0), returnsNormally);
      expect(() => skyMask.isPointInSky(1.0, 1.0), returnsNormally);
      expect(() => skyMask.isPointInSky(0.5, 0.5), returnsNormally);
    });

    test('isPointInSky returns boolean', () {
      final SkyMask skyMask = PitchBasedSkyMask();

      final result = skyMask.isPointInSky(0.5, 0.5);
      expect(result, isA<bool>());
    });
  });
}
