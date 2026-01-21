import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/wind_data.dart';

void main() {
  group('WindData', () {
    group('constructor', () {
      test('creates instance with u, v, altitude, and timestamp', () {
        final timestamp = DateTime.now();
        final windData = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: 10.0,
          timestamp: timestamp,
        );

        expect(windData.uComponent, 3.0);
        expect(windData.vComponent, 4.0);
        expect(windData.altitude, 10.0);
        expect(windData.timestamp, timestamp);
      });
    });

    group('speed', () {
      test('computed correctly as sqrt(u^2 + v^2)', () {
        // Classic 3-4-5 Pythagorean triple
        final windData = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );

        expect(windData.speed, 5.0);
      });

      test('handles zero wind', () {
        final windData = WindData(
          uComponent: 0.0,
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );

        expect(windData.speed, 0.0);
      });

      test('handles negative components', () {
        final windData = WindData(
          uComponent: -3.0,
          vComponent: -4.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );

        // Speed should still be positive (magnitude)
        expect(windData.speed, 5.0);
      });
    });

    group('directionRadians', () {
      test('computed correctly using atan2(-u, -v) meteorological convention',
          () {
        // Wind blowing southward (v positive means moving toward north,
        // but in wind convention: u,v components show where wind GOES TO)
        // For wind coming FROM north (blowing southward), v < 0
        // Let's use clear cases:

        // Wind from south (blowing northward): u=0, v=1
        // direction = atan2(0, -1) = pi (or -pi, equivalent for 180 degrees)
        final southWind = WindData(
          uComponent: 0.0,
          vComponent: 1.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // The absolute value should be pi (representing 180 degrees)
        expect(southWind.directionRadians.abs(), closeTo(pi, 0.001));

        // Wind from east (u positive = wind blowing westward)
        // direction = atan2(-1, 0) = -pi/2
        final eastWind = WindData(
          uComponent: 1.0,
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        expect(eastWind.directionRadians, closeTo(-pi / 2, 0.001));

        // Wind from west (u negative = wind blowing eastward)
        // direction = atan2(1, 0) = pi/2
        final westWind = WindData(
          uComponent: -1.0,
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        expect(westWind.directionRadians, closeTo(pi / 2, 0.001));
      });

      test('handles zero wind with well-defined direction', () {
        final windData = WindData(
          uComponent: 0.0,
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );

        // atan2(0, 0) behavior is implementation-defined
        // Just verify it returns a finite value
        expect(windData.directionRadians.isFinite, true);
      });
    });

    group('directionDegrees', () {
      test('computed correctly and normalized to 0-360', () {
        // Wind coming from south (v negative, blowing northward)
        final southWind = WindData(
          uComponent: 0.0,
          vComponent: -1.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // atan2(0, 1) = 0 radians = 0 degrees
        expect(southWind.directionDegrees, closeTo(0.0, 0.1));

        // Wind coming from north (v positive, blowing southward)
        final northWind = WindData(
          uComponent: 0.0,
          vComponent: 1.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // atan2(0, -1) = pi radians = 180 degrees
        expect(northWind.directionDegrees, closeTo(180.0, 0.1));
      });

      test('handles negative direction by adding 360', () {
        // Wind from west (u negative, blowing eastward)
        final westWind = WindData(
          uComponent: -1.0,
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // atan2(1, 0) = pi/2 = 90 degrees
        expect(westWind.directionDegrees, closeTo(90.0, 0.1));

        // Wind from east (u positive, blowing westward)
        final eastWind = WindData(
          uComponent: 1.0,
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // atan2(-1, 0) = -pi/2 -> (-90 + 360) % 360 = 270
        expect(eastWind.directionDegrees, closeTo(270.0, 0.1));
      });
    });

    group('zero() factory', () {
      test('creates zero-wind instance', () {
        final windData = WindData.zero();

        expect(windData.uComponent, 0.0);
        expect(windData.vComponent, 0.0);
        expect(windData.altitude, 0.0);
        expect(windData.speed, 0.0);
      });

      test('has valid timestamp', () {
        final before = DateTime.now();
        final windData = WindData.zero();
        final after = DateTime.now();

        expect(windData.timestamp.isAfter(before.subtract(const Duration(milliseconds: 1))), true);
        expect(windData.timestamp.isBefore(after.add(const Duration(milliseconds: 1))), true);
      });
    });

    group('meteorological convention verification', () {
      test('north wind (coming from north) has direction 180 degrees', () {
        // North wind: blowing from N to S, so air moves southward
        // In meteorological convention: wind coming FROM north
        // u=0 (no east-west component), v>0 (air moves toward north in u/v convention... wait)
        // Actually in meteorological:
        // u = eastward component of where wind is GOING
        // v = northward component of where wind is GOING
        // So north wind (coming FROM north) goes TO south: v < 0
        // Let me verify with the formula: direction = atan2(-u, -v)
        // For south wind (coming from south, going north): u=0, v=1
        //   direction = atan2(0, -1) = pi = 180 degrees
        // That's wrong - should be 0 degrees for north wind
        //
        // Actually the convention is confusing. Let me just verify the math:
        // direction = atan2(-u, -v) gives the direction wind is COMING FROM
        // If wind is blowing TO the north (v=1), then atan2(-0, -1) = pi = 180 deg
        // So a wind with v=1 is coming FROM the south (180 deg)
        // Which means for north wind (coming FROM north = 0 degrees):
        // We want wind blowing TO the south, so v=-1
        // atan2(-0, -(-1)) = atan2(0, 1) = 0 degrees. Correct!

        // North wind: coming FROM north, so blowing southward (v < 0)
        final northWind = WindData(
          uComponent: 0.0,
          vComponent: -1.0, // blowing southward
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // direction = atan2(-0, -(-1)) = atan2(0, 1) = 0
        expect(northWind.directionDegrees, closeTo(0.0, 0.1));
      });

      test('east wind (coming from east) has direction 90 degrees', () {
        // East wind: coming FROM east, blowing westward (u < 0)
        final eastWind = WindData(
          uComponent: -1.0, // blowing westward
          vComponent: 0.0,
          altitude: 10.0,
          timestamp: DateTime.now(),
        );
        // direction = atan2(-(-1), -0) = atan2(1, 0) = pi/2 = 90 degrees
        expect(eastWind.directionDegrees, closeTo(90.0, 0.1));
      });
    });
  });
}
