import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/hsv.dart';

void main() {
  group('HSV', () {
    group('constructor', () {
      test('creates instance with valid values', () {
        const hsv = HSV(180.0, 0.5, 0.75);

        expect(hsv.h, 180.0);
        expect(hsv.s, 0.5);
        expect(hsv.v, 0.75);
      });

      test('creates instance with hue 0 (red)', () {
        const hsv = HSV(0.0, 1.0, 1.0);

        expect(hsv.h, 0.0);
        expect(hsv.s, 1.0);
        expect(hsv.v, 1.0);
      });

      test('creates instance with hue 360 (red, full circle)', () {
        const hsv = HSV(360.0, 1.0, 1.0);

        expect(hsv.h, 360.0);
      });

      test('creates instance with saturation 0 (grayscale)', () {
        const hsv = HSV(120.0, 0.0, 0.5);

        expect(hsv.s, 0.0);
      });

      test('creates instance with value 0 (black)', () {
        const hsv = HSV(240.0, 1.0, 0.0);

        expect(hsv.v, 0.0);
      });

      test('creates instance with all zeros', () {
        const hsv = HSV(0.0, 0.0, 0.0);

        expect(hsv.h, 0.0);
        expect(hsv.s, 0.0);
        expect(hsv.v, 0.0);
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const hsv = HSV(197.5, 0.43, 0.92);

        final str = hsv.toString();

        expect(str, contains('HSV'));
        expect(str, contains('197.5'));
        expect(str, contains('0.43'));
        expect(str, contains('0.92'));
      });

      test('formats hue with one decimal', () {
        const hsv = HSV(120.123, 0.5, 0.5);

        expect(hsv.toString(), contains('120.1'));
      });

      test('formats saturation and value with two decimals', () {
        const hsv = HSV(0.0, 0.1234, 0.5678);

        final str = hsv.toString();
        expect(str, contains('0.12'));
        expect(str, contains('0.57'));
      });
    });

    group('equality', () {
      test('equal HSV values are equal', () {
        const hsv1 = HSV(180.0, 0.5, 0.75);
        const hsv2 = HSV(180.0, 0.5, 0.75);

        expect(hsv1, equals(hsv2));
        expect(hsv1.hashCode, equals(hsv2.hashCode));
      });

      test('different hue values are not equal', () {
        const hsv1 = HSV(180.0, 0.5, 0.75);
        const hsv2 = HSV(181.0, 0.5, 0.75);

        expect(hsv1, isNot(equals(hsv2)));
      });

      test('different saturation values are not equal', () {
        const hsv1 = HSV(180.0, 0.5, 0.75);
        const hsv2 = HSV(180.0, 0.6, 0.75);

        expect(hsv1, isNot(equals(hsv2)));
      });

      test('different value values are not equal', () {
        const hsv1 = HSV(180.0, 0.5, 0.75);
        const hsv2 = HSV(180.0, 0.5, 0.85);

        expect(hsv1, isNot(equals(hsv2)));
      });
    });
  });
}
