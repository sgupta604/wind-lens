import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/utils/wind_colors.dart';

void main() {
  group('WindColors', () {
    group('getSpeedColor', () {
      // Color constants from spec
      const blue = Color(0xFF3B82F6);
      const cyan = Color(0xFF06B6D4);
      const green = Color(0xFF22C55E);
      const yellow = Color(0xFFEAB308);
      const orange = Color(0xFFF97316);
      const red = Color(0xFFEF4444);
      const purple = Color(0xFFA855F7);

      test('returns blue for 0 m/s', () {
        expect(WindColors.getSpeedColor(0), blue);
      });

      test('returns blue for negative speeds', () {
        expect(WindColors.getSpeedColor(-5), blue);
        expect(WindColors.getSpeedColor(-100), blue);
      });

      test('returns blue for speeds less than 5 m/s', () {
        expect(WindColors.getSpeedColor(1), blue);
        expect(WindColors.getSpeedColor(4.9), blue);
      });

      test('starts transition from blue at 5 m/s', () {
        // At exactly 5 m/s, should start transitioning from blue to cyan
        final color = WindColors.getSpeedColor(5);
        // Should be at the start of the transition (blue end)
        expect(color.red, closeTo(blue.red, 5));
        expect(color.green, closeTo(blue.green, 5));
        expect(color.blue, closeTo(blue.blue, 5));
      });

      test('interpolates between blue and cyan for 5-10 m/s range', () {
        final color = WindColors.getSpeedColor(7.5);
        // Should be between blue and cyan
        // Blue: (59, 130, 246), Cyan: (6, 182, 212)
        expect(color.red, lessThan(blue.red));
        expect(color.green, greaterThan(blue.green));
      });

      test('reaches cyan at 10 m/s (end of first range)', () {
        final color = WindColors.getSpeedColor(10);
        // At 10 m/s, the 5-10 range ends, so should be at cyan
        expect(color.red, closeTo(cyan.red, 5));
        expect(color.green, closeTo(cyan.green, 5));
        expect(color.blue, closeTo(cyan.blue, 5));
      });

      test('interpolates between cyan and green for 10-20 m/s', () {
        final color = WindColors.getSpeedColor(15);
        // Should be between cyan and green values
        expect(color, isA<Color>());
        // Green channel should be higher than cyan's
        expect(color.green, greaterThan(cyan.green));
      });

      test('interpolates between green and yellow for 15-20 m/s', () {
        final color = WindColors.getSpeedColor(17);
        // Should be between cyan/green and yellow
        expect(color, isA<Color>());
      });

      test('reaches green at 20 m/s (end of second range)', () {
        final color = WindColors.getSpeedColor(20);
        // At 20 m/s, the 10-20 range ends, so should be at green
        expect(color.red, closeTo(green.red, 5));
        expect(color.green, closeTo(green.green, 5));
        expect(color.blue, closeTo(green.blue, 5));
      });

      test('interpolates between green and yellow for 20-35 m/s', () {
        final color = WindColors.getSpeedColor(27.5);
        // Should be between green and yellow
        // Green: (34, 197, 94), Yellow: (234, 179, 8)
        // Red component increases, blue decreases
        expect(color.red, greaterThan(green.red));
        expect(color.blue, lessThan(green.blue));
      });

      test('reaches yellow at 35 m/s (end of third range)', () {
        final color = WindColors.getSpeedColor(35);
        // At 35 m/s, the 20-35 range ends, so should be at yellow
        expect(color.red, closeTo(yellow.red, 5));
        expect(color.green, closeTo(yellow.green, 5));
        expect(color.blue, closeTo(yellow.blue, 5));
      });

      test('interpolates between yellow and orange for 35-50 m/s', () {
        final color = WindColors.getSpeedColor(42.5);
        // Should be between yellow and orange
        expect(color.red, greaterThanOrEqualTo(yellow.red - 10));
      });

      test('reaches orange at 50 m/s (end of fourth range)', () {
        final color = WindColors.getSpeedColor(50);
        // At 50 m/s, the 35-50 range ends, so should be at orange
        expect(color.red, closeTo(orange.red, 5));
        expect(color.green, closeTo(orange.green, 5));
        expect(color.blue, closeTo(orange.blue, 5));
      });

      test('interpolates towards purple for speeds above 50 m/s', () {
        final color = WindColors.getSpeedColor(75);
        // Should be between orange/red and purple
        // At 75 m/s, should have moved towards purple (more blue)
        expect(color.blue, greaterThan(orange.blue));
      });

      test('returns purple for very high speeds (100+ m/s)', () {
        final color = WindColors.getSpeedColor(100);
        expect(color.red, closeTo(purple.red, 10));
        expect(color.green, closeTo(purple.green, 10));
        expect(color.blue, closeTo(purple.blue, 10));
      });

      test('clamps to purple for extremely high speeds', () {
        final color1 = WindColors.getSpeedColor(150);
        final color2 = WindColors.getSpeedColor(200);
        // Should both be purple (clamped)
        expect(color1, equals(color2));
        expect(color1.blue, closeTo(purple.blue, 10));
      });
    });

    group('getSpeedColorWithOpacity', () {
      test('returns color with specified opacity', () {
        final color = WindColors.getSpeedColorWithOpacity(10, 0.5);
        expect(color.alpha, equals((255 * 0.5).round()));
      });

      test('clamps opacity to valid range', () {
        final color1 = WindColors.getSpeedColorWithOpacity(10, -0.5);
        expect(color1.alpha, equals(0));

        final color2 = WindColors.getSpeedColorWithOpacity(10, 1.5);
        expect(color2.alpha, equals(255));
      });

      test('preserves base color RGB values', () {
        final baseColor = WindColors.getSpeedColor(10);
        final withOpacity = WindColors.getSpeedColorWithOpacity(10, 0.7);

        expect(withOpacity.red, equals(baseColor.red));
        expect(withOpacity.green, equals(baseColor.green));
        expect(withOpacity.blue, equals(baseColor.blue));
      });
    });

    group('color constants', () {
      test('lowSpeedColor is blue', () {
        expect(WindColors.lowSpeedColor, const Color(0xFF3B82F6));
      });

      test('highSpeedColor is purple', () {
        expect(WindColors.highSpeedColor, const Color(0xFFA855F7));
      });
    });
  });
}
