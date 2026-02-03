import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('AltitudeLevel', () {
    group('displayName', () {
      test('surface has displayName "Surface"', () {
        expect(AltitudeLevel.surface.displayName, 'Surface');
      });

      test('midLevel has displayName "Cloud Level"', () {
        expect(AltitudeLevel.midLevel.displayName, 'Cloud Level');
      });

      test('jetStream has displayName "Jet Stream"', () {
        expect(AltitudeLevel.jetStream.displayName, 'Jet Stream');
      });
    });

    group('metersAGL', () {
      test('metersAGL values are correct for all levels', () {
        expect(AltitudeLevel.surface.metersAGL, 10.0);
        expect(AltitudeLevel.midLevel.metersAGL, 1500.0);
        expect(AltitudeLevel.jetStream.metersAGL, 10500.0);
      });
    });

    group('particleColor', () {
      test('particleColor values are correct for all levels', () {
        // Surface: White with alpha 0xAA
        expect(AltitudeLevel.surface.particleColor, const Color(0xAAFFFFFF));
        // Mid-level: Cyan with alpha 0xAA
        expect(AltitudeLevel.midLevel.particleColor, const Color(0xAA00DDFF));
        // Jet Stream: Purple with alpha 0xAA
        expect(AltitudeLevel.jetStream.particleColor, const Color(0xAADD00FF));
      });
    });

    group('parallaxFactor', () {
      test('parallaxFactor decreases with altitude (1.0 > 0.6 > 0.3)', () {
        expect(AltitudeLevel.surface.parallaxFactor, 1.0);
        expect(AltitudeLevel.midLevel.parallaxFactor, 0.6);
        expect(AltitudeLevel.jetStream.parallaxFactor, 0.3);

        // Verify the ordering relationship
        expect(
          AltitudeLevel.surface.parallaxFactor,
          greaterThan(AltitudeLevel.midLevel.parallaxFactor),
        );
        expect(
          AltitudeLevel.midLevel.parallaxFactor,
          greaterThan(AltitudeLevel.jetStream.parallaxFactor),
        );
      });
    });

    group('trailScale', () {
      test('trailScale decreases with altitude (1.0 > 0.7 > 0.5)', () {
        expect(AltitudeLevel.surface.trailScale, 1.0);
        expect(AltitudeLevel.midLevel.trailScale, 0.7);
        expect(AltitudeLevel.jetStream.trailScale, 0.5);

        // Verify the ordering relationship
        expect(
          AltitudeLevel.surface.trailScale,
          greaterThan(AltitudeLevel.midLevel.trailScale),
        );
        expect(
          AltitudeLevel.midLevel.trailScale,
          greaterThan(AltitudeLevel.jetStream.trailScale),
        );
      });
    });

    group('particleSpeedMultiplier', () {
      test('particleSpeedMultiplier increases with altitude (1.0 < 1.5 < 3.0)',
          () {
        expect(AltitudeLevel.surface.particleSpeedMultiplier, 1.0);
        expect(AltitudeLevel.midLevel.particleSpeedMultiplier, 1.5);
        expect(AltitudeLevel.jetStream.particleSpeedMultiplier, 3.0);

        // Verify the ordering relationship
        expect(
          AltitudeLevel.surface.particleSpeedMultiplier,
          lessThan(AltitudeLevel.midLevel.particleSpeedMultiplier),
        );
        expect(
          AltitudeLevel.midLevel.particleSpeedMultiplier,
          lessThan(AltitudeLevel.jetStream.particleSpeedMultiplier),
        );
      });
    });

    group('enum values', () {
      test('has exactly three values', () {
        expect(AltitudeLevel.values.length, 3);
      });

      test('values are in order: surface, midLevel, jetStream', () {
        expect(AltitudeLevel.values[0], AltitudeLevel.surface);
        expect(AltitudeLevel.values[1], AltitudeLevel.midLevel);
        expect(AltitudeLevel.values[2], AltitudeLevel.jetStream);
      });
    });

    group('streamlineTrailPoints', () {
      test('surface has streamlineTrailPoints of 12', () {
        expect(AltitudeLevel.surface.streamlineTrailPoints, 12);
      });

      test('midLevel has streamlineTrailPoints of 18', () {
        expect(AltitudeLevel.midLevel.streamlineTrailPoints, 18);
      });

      test('jetStream has streamlineTrailPoints of 25', () {
        expect(AltitudeLevel.jetStream.streamlineTrailPoints, 25);
      });

      test('streamlineTrailPoints increases with altitude', () {
        expect(
          AltitudeLevel.surface.streamlineTrailPoints,
          lessThan(AltitudeLevel.midLevel.streamlineTrailPoints),
        );
        expect(
          AltitudeLevel.midLevel.streamlineTrailPoints,
          lessThan(AltitudeLevel.jetStream.streamlineTrailPoints),
        );
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
