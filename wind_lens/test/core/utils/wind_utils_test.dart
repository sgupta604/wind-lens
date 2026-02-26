import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/utils/wind_utils.dart';

void main() {
  group('degreesToCardinal', () {
    test('0 degrees returns N', () {
      expect(degreesToCardinal(0), 'N');
    });

    test('90 degrees returns E', () {
      expect(degreesToCardinal(90), 'E');
    });

    test('180 degrees returns S', () {
      expect(degreesToCardinal(180), 'S');
    });

    test('270 degrees returns W', () {
      expect(degreesToCardinal(270), 'W');
    });

    test('202 degrees returns SSW', () {
      expect(degreesToCardinal(202), 'SSW');
    });

    test('handles boundary and overflow degrees', () {
      expect(degreesToCardinal(360), 'N');
      expect(degreesToCardinal(361), 'N');
      expect(degreesToCardinal(-10), 'N');
      expect(degreesToCardinal(-90), 'W');
      expect(degreesToCardinal(720), 'N');
    });
  });
}
