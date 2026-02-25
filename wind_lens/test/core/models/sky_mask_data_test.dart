import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';

void main() {
  group('SkyMaskData', () {
    group('construction', () {
      test('creates instance with all fields', () {
        final mask = SkyMaskData(
          width: 4,
          height: 3,
          pixels: List.filled(12, true),
          method: SkyDetectionMethod.hsv,
        );

        expect(mask.width, 4);
        expect(mask.height, 3);
        expect(mask.pixels.length, 12);
        expect(mask.method, SkyDetectionMethod.hsv);
      });
    });

    // Note: SkyMaskData is NOT Freezed (hot-path per-frame object).
    // No value equality tests — identity equality is fine for this use case.

    group('isPointInSky', () {
      // Create a 4x4 mask where top half is sky, bottom half is not
      late SkyMaskData mask;

      setUp(() {
        // 4x4 grid: rows 0-1 are sky (true), rows 2-3 are not sky (false)
        final pixels = <bool>[];
        for (int y = 0; y < 4; y++) {
          for (int x = 0; x < 4; x++) {
            pixels.add(y < 2); // top half is sky
          }
        }
        mask = SkyMaskData(
          width: 4,
          height: 4,
          pixels: pixels,
          method: SkyDetectionMethod.hsv,
        );
      });

      test('returns true for sky pixels (top half)', () {
        // Top-left corner
        expect(mask.isPointInSky(0.0, 0.0), true);
        // Top-right area
        expect(mask.isPointInSky(0.9, 0.1), true);
        // Just above midpoint
        expect(mask.isPointInSky(0.5, 0.4), true);
      });

      test('returns false for non-sky pixels (bottom half)', () {
        // Bottom-left area
        expect(mask.isPointInSky(0.0, 0.7), false);
        // Bottom-right area
        expect(mask.isPointInSky(0.9, 0.9), false);
        // Just below midpoint
        expect(mask.isPointInSky(0.5, 0.6), false);
      });

      test('handles edge coordinates (0,0)', () {
        expect(mask.isPointInSky(0.0, 0.0), true);
      });

      test('handles edge coordinates near (1,1)', () {
        // 0.999 should map to the last row/column
        expect(mask.isPointInSky(0.999, 0.999), false); // bottom-right is not sky
      });

      test('clamps out-of-range coordinates', () {
        // Negative values should clamp to 0
        expect(mask.isPointInSky(-0.1, -0.1), true); // top-left is sky
        // Values > 1 should clamp to 0.999
        expect(mask.isPointInSky(1.5, 1.5), false); // bottom-right is not sky
      });
    });

    group('skyFraction', () {
      test('computes correctly for 50% sky', () {
        // 4x4 grid: top half sky, bottom half not
        final pixels = <bool>[];
        for (int y = 0; y < 4; y++) {
          for (int x = 0; x < 4; x++) {
            pixels.add(y < 2);
          }
        }
        final mask = SkyMaskData(
          width: 4,
          height: 4,
          pixels: pixels,
          method: SkyDetectionMethod.hsv,
        );

        expect(mask.skyFraction, closeTo(0.5, 0.01));
      });

      test('returns 1.0 for all-sky mask', () {
        final mask = SkyMaskData(
          width: 2,
          height: 2,
          pixels: [true, true, true, true],
          method: SkyDetectionMethod.hsv,
        );

        expect(mask.skyFraction, 1.0);
      });

      test('returns 0.0 for no-sky mask', () {
        final mask = SkyMaskData(
          width: 2,
          height: 2,
          pixels: [false, false, false, false],
          method: SkyDetectionMethod.hsv,
        );

        expect(mask.skyFraction, 0.0);
      });

      test('returns 0.0 for empty pixel list', () {
        final mask = SkyMaskData(
          width: 0,
          height: 0,
          pixels: [],
          method: SkyDetectionMethod.hsv,
        );

        expect(mask.skyFraction, 0.0);
      });
    });

    group('fullSky() factory', () {
      test('skyFraction is 1.0', () {
        final mask = SkyMaskData.fullSky();

        expect(mask.skyFraction, 1.0);
      });

      test('all points are sky', () {
        final mask = SkyMaskData.fullSky();

        expect(mask.isPointInSky(0.0, 0.0), true);
        expect(mask.isPointInSky(0.5, 0.5), true);
        expect(mask.isPointInSky(0.9, 0.9), true);
      });

      test('has default dimensions 128x96', () {
        final mask = SkyMaskData.fullSky();

        expect(mask.width, 128);
        expect(mask.height, 96);
        expect(mask.pixels.length, 128 * 96);
      });

      test('accepts custom dimensions', () {
        final mask = SkyMaskData.fullSky(width: 64, height: 48);

        expect(mask.width, 64);
        expect(mask.height, 48);
        expect(mask.pixels.length, 64 * 48);
      });

      test('uses hsv method', () {
        final mask = SkyMaskData.fullSky();

        expect(mask.method, SkyDetectionMethod.hsv);
      });
    });
  });
}
