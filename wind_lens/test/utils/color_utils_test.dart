import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    group('rgbToHsv', () {
      // Primary colors
      test('converts pure red (255,0,0) to HSV(0, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(255, 0, 0);

        expect(hsv.h, closeTo(0.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      test('converts pure green (0,255,0) to HSV(120, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(0, 255, 0);

        expect(hsv.h, closeTo(120.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      test('converts pure blue (0,0,255) to HSV(240, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(0, 0, 255);

        expect(hsv.h, closeTo(240.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      // Achromatic colors
      test('converts white (255,255,255) to HSV(0, 0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(255, 255, 255);

        expect(hsv.h, closeTo(0.0, 0.1));
        expect(hsv.s, closeTo(0.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      test('converts black (0,0,0) to HSV(0, 0, 0)', () {
        final hsv = ColorUtils.rgbToHsv(0, 0, 0);

        expect(hsv.h, closeTo(0.0, 0.1));
        expect(hsv.s, closeTo(0.0, 0.01));
        expect(hsv.v, closeTo(0.0, 0.01));
      });

      test('converts gray (128,128,128) to HSV(0, 0, ~0.5)', () {
        final hsv = ColorUtils.rgbToHsv(128, 128, 128);

        expect(hsv.h, closeTo(0.0, 0.1));
        expect(hsv.s, closeTo(0.0, 0.01));
        expect(hsv.v, closeTo(0.5, 0.01));
      });

      // Secondary colors
      test('converts yellow (255,255,0) to HSV(60, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(255, 255, 0);

        expect(hsv.h, closeTo(60.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      test('converts cyan (0,255,255) to HSV(180, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(0, 255, 255);

        expect(hsv.h, closeTo(180.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      test('converts magenta (255,0,255) to HSV(300, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(255, 0, 255);

        expect(hsv.h, closeTo(300.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      // Typical sky blue
      test('converts sky blue (135,206,235) to HSV(~197, ~0.43, ~0.92)', () {
        final hsv = ColorUtils.rgbToHsv(135, 206, 235);

        // Sky blue: hue around 197, saturation around 0.43, value around 0.92
        expect(hsv.h, closeTo(197.0, 2.0));
        expect(hsv.s, closeTo(0.43, 0.05));
        expect(hsv.v, closeTo(0.92, 0.02));
      });

      // Additional edge cases
      test('converts dark blue (0,0,128) correctly', () {
        final hsv = ColorUtils.rgbToHsv(0, 0, 128);

        expect(hsv.h, closeTo(240.0, 0.1));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(0.5, 0.01));
      });

      test('converts orange (255,165,0) to HSV(~39, 1.0, 1.0)', () {
        final hsv = ColorUtils.rgbToHsv(255, 165, 0);

        expect(hsv.h, closeTo(39.0, 1.0));
        expect(hsv.s, closeTo(1.0, 0.01));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      // Hue wraparound (near red on the color wheel)
      test('converts pinkish red correctly (hue near 360)', () {
        final hsv = ColorUtils.rgbToHsv(255, 20, 147);

        // Hue should be in 300-360 range or 0-30 range (deep pink)
        expect(hsv.h, greaterThanOrEqualTo(0.0));
        expect(hsv.h, lessThanOrEqualTo(360.0));
        expect(hsv.s, greaterThan(0.5));
        expect(hsv.v, closeTo(1.0, 0.01));
      });

      test('handles minimum non-zero values', () {
        final hsv = ColorUtils.rgbToHsv(1, 1, 1);

        expect(hsv.s, closeTo(0.0, 0.01));
        expect(hsv.v, closeTo(1.0 / 255.0, 0.01));
      });
    });
  });
}
