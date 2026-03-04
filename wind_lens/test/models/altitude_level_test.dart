import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('AltitudeLevel', () {
    group('displayName', () {
      test('surface has displayName "Surface"', () {
        expect(AltitudeLevel.surface.displayName, 'Surface');
      });

      test('midLevel has displayName "850 hPa"', () {
        expect(AltitudeLevel.midLevel.displayName, '850 hPa');
      });

      test('level700 has displayName "700 hPa"', () {
        expect(AltitudeLevel.level700.displayName, '700 hPa');
      });

      test('level500 has displayName "500 hPa"', () {
        expect(AltitudeLevel.level500.displayName, '500 hPa');
      });

      test('level300 has displayName "300 hPa"', () {
        expect(AltitudeLevel.level300.displayName, '300 hPa');
      });

      test('jetStream has displayName "250 hPa"', () {
        expect(AltitudeLevel.jetStream.displayName, '250 hPa');
      });
    });

    group('metersAGL', () {
      test('metersAGL values are correct for all levels', () {
        expect(AltitudeLevel.surface.metersAGL, 10.0);
        expect(AltitudeLevel.midLevel.metersAGL, 1500.0);
        expect(AltitudeLevel.level700.metersAGL, 3000.0);
        expect(AltitudeLevel.level500.metersAGL, 5500.0);
        expect(AltitudeLevel.level300.metersAGL, 9000.0);
        expect(AltitudeLevel.jetStream.metersAGL, 10500.0);
      });

      test('metersAGL increases with altitude level', () {
        final values = AltitudeLevel.values.map((l) => l.metersAGL).toList();
        for (int i = 1; i < values.length; i++) {
          expect(values[i], greaterThan(values[i - 1]));
        }
      });
    });

    group('particleColor', () {
      test('particleColor values are correct for all levels', () {
        // Surface: White with alpha 0xAA
        expect(AltitudeLevel.surface.particleColor, const Color(0xAAFFFFFF));
        // Mid-level: Cyan with alpha 0xAA
        expect(AltitudeLevel.midLevel.particleColor, const Color(0xAA00DDFF));
        // 700 hPa: Blue with alpha 0xAA
        expect(AltitudeLevel.level700.particleColor, const Color(0xAA00AAFF));
        // 500 hPa: Violet with alpha 0xAA
        expect(AltitudeLevel.level500.particleColor, const Color(0xAA8855FF));
        // 300 hPa: Magenta with alpha 0xAA
        expect(AltitudeLevel.level300.particleColor, const Color(0xAABB33FF));
        // Jet Stream: Purple with alpha 0xAA
        expect(AltitudeLevel.jetStream.particleColor, const Color(0xAADD00FF));
      });
    });

    group('parallaxFactor', () {
      test('parallaxFactor values are correct for all levels', () {
        expect(AltitudeLevel.surface.parallaxFactor, 1.0);
        expect(AltitudeLevel.midLevel.parallaxFactor, 0.6);
        expect(AltitudeLevel.level700.parallaxFactor, 0.5);
        expect(AltitudeLevel.level500.parallaxFactor, 0.4);
        expect(AltitudeLevel.level300.parallaxFactor, 0.35);
        expect(AltitudeLevel.jetStream.parallaxFactor, 0.3);
      });

      test('parallaxFactor decreases with altitude', () {
        final values =
            AltitudeLevel.values.map((l) => l.parallaxFactor).toList();
        for (int i = 1; i < values.length; i++) {
          expect(values[i], lessThan(values[i - 1]));
        }
      });
    });

    group('trailScale', () {
      test('trailScale values are correct for all levels', () {
        expect(AltitudeLevel.surface.trailScale, 1.0);
        expect(AltitudeLevel.midLevel.trailScale, 0.7);
        expect(AltitudeLevel.level700.trailScale, 0.65);
        expect(AltitudeLevel.level500.trailScale, 0.6);
        expect(AltitudeLevel.level300.trailScale, 0.55);
        expect(AltitudeLevel.jetStream.trailScale, 0.5);
      });

      test('trailScale decreases with altitude', () {
        final values = AltitudeLevel.values.map((l) => l.trailScale).toList();
        for (int i = 1; i < values.length; i++) {
          expect(values[i], lessThan(values[i - 1]));
        }
      });
    });

    group('particleSpeedMultiplier', () {
      test('particleSpeedMultiplier values are correct for all levels', () {
        expect(AltitudeLevel.surface.particleSpeedMultiplier, 1.0);
        expect(AltitudeLevel.midLevel.particleSpeedMultiplier, 1.5);
        expect(AltitudeLevel.level700.particleSpeedMultiplier, 1.8);
        expect(AltitudeLevel.level500.particleSpeedMultiplier, 2.2);
        expect(AltitudeLevel.level300.particleSpeedMultiplier, 2.7);
        expect(AltitudeLevel.jetStream.particleSpeedMultiplier, 3.0);
      });

      test('particleSpeedMultiplier increases with altitude', () {
        final values =
            AltitudeLevel.values.map((l) => l.particleSpeedMultiplier).toList();
        for (int i = 1; i < values.length; i++) {
          expect(values[i], greaterThan(values[i - 1]));
        }
      });
    });

    group('enum values', () {
      test('has exactly six values', () {
        expect(AltitudeLevel.values.length, 6);
      });

      test(
          'values are in order: surface, midLevel, level700, level500, level300, jetStream',
          () {
        expect(AltitudeLevel.values[0], AltitudeLevel.surface);
        expect(AltitudeLevel.values[1], AltitudeLevel.midLevel);
        expect(AltitudeLevel.values[2], AltitudeLevel.level700);
        expect(AltitudeLevel.values[3], AltitudeLevel.level500);
        expect(AltitudeLevel.values[4], AltitudeLevel.level300);
        expect(AltitudeLevel.values[5], AltitudeLevel.jetStream);
      });
    });

    group('streamlineTrailPoints', () {
      test('surface has streamlineTrailPoints of 12', () {
        expect(AltitudeLevel.surface.streamlineTrailPoints, 12);
      });

      test('midLevel has streamlineTrailPoints of 18', () {
        expect(AltitudeLevel.midLevel.streamlineTrailPoints, 18);
      });

      test('level700 has streamlineTrailPoints of 20', () {
        expect(AltitudeLevel.level700.streamlineTrailPoints, 20);
      });

      test('level500 has streamlineTrailPoints of 22', () {
        expect(AltitudeLevel.level500.streamlineTrailPoints, 22);
      });

      test('level300 has streamlineTrailPoints of 24', () {
        expect(AltitudeLevel.level300.streamlineTrailPoints, 24);
      });

      test('jetStream has streamlineTrailPoints of 25', () {
        expect(AltitudeLevel.jetStream.streamlineTrailPoints, 25);
      });

      test('streamlineTrailPoints increases with altitude', () {
        final values =
            AltitudeLevel.values.map((l) => l.streamlineTrailPoints).toList();
        for (int i = 1; i < values.length; i++) {
          expect(values[i], greaterThanOrEqualTo(values[i - 1]));
        }
      });

      test('all trail points are within maxTrailPoints limit (30)', () {
        for (final level in AltitudeLevel.values) {
          expect(level.streamlineTrailPoints, lessThanOrEqualTo(30));
          expect(level.streamlineTrailPoints, greaterThan(0));
        }
      });
    });
  });
}
