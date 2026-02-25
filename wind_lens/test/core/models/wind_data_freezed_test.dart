import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('WindData (Freezed)', () {
    final timestamp = DateTime(2026, 2, 25, 12, 0, 0);

    group('construction', () {
      test('creates instance with all fields', () {
        final wind = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          gustSpeed: 8.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(wind.uComponent, 3.0);
        expect(wind.vComponent, 4.0);
        expect(wind.gustSpeed, 8.0);
        expect(wind.altitude, AltitudeLevel.surface);
        expect(wind.timestamp, timestamp);
      });

      test('gustSpeed defaults to 0.0', () {
        final wind = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(wind.gustSpeed, 0.0);
      });
    });

    group('equality', () {
      test('same data produces equal instances', () {
        final a = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        final b = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different data produces unequal instances', () {
        final a = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        final b = WindData(
          uComponent: 5.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('produces modified copy', () {
        final original = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        final modified = original.copyWith(altitude: AltitudeLevel.jetStream);

        expect(modified.uComponent, original.uComponent);
        expect(modified.vComponent, original.vComponent);
        expect(modified.altitude, AltitudeLevel.jetStream);
      });
    });

    group('speed getter', () {
      test('matches sqrt(u^2 + v^2)', () {
        final wind = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(wind.speed, closeTo(5.0, 0.001));
      });

      test('handles zero wind', () {
        final wind = WindData(
          uComponent: 0.0,
          vComponent: 0.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(wind.speed, 0.0);
      });
    });

    group('directionRadians getter', () {
      test('matches atan2(-u, -v)', () {
        final wind = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(wind.directionRadians, closeTo(atan2(-3.0, -4.0), 0.001));
      });
    });

    group('directionDegrees getter', () {
      test('matches radians * 180 / pi normalized to 0-360', () {
        // Wind from north (blowing southward): u=0, v=-1
        final northWind = WindData(
          uComponent: 0.0,
          vComponent: -1.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        expect(northWind.directionDegrees, closeTo(0.0, 0.1));

        // Wind from south (blowing northward): u=0, v=1
        final southWind = WindData(
          uComponent: 0.0,
          vComponent: 1.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        expect(southWind.directionDegrees, closeTo(180.0, 0.1));
      });
    });

    group('zero() factory', () {
      test('returns zero speed surface level wind', () {
        final wind = WindData.zero();

        expect(wind.uComponent, 0.0);
        expect(wind.vComponent, 0.0);
        expect(wind.speed, 0.0);
        expect(wind.altitude, AltitudeLevel.surface);
      });
    });

    group('fromSpeedDirection() factory', () {
      test('round-trips correctly', () {
        final wind = WindData.fromSpeedDirection(
          speed: 10.0,
          directionDegrees: 90.0,
          altitude: AltitudeLevel.midLevel,
          timestamp: timestamp,
        );

        expect(wind.speed, closeTo(10.0, 0.01));
        expect(wind.directionDegrees, closeTo(90.0, 0.1));
        expect(wind.altitude, AltitudeLevel.midLevel);
      });

      test('north wind round-trips', () {
        final wind = WindData.fromSpeedDirection(
          speed: 5.0,
          directionDegrees: 0.0,
          altitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(wind.speed, closeTo(5.0, 0.01));
        expect(wind.directionDegrees, closeTo(0.0, 0.1));
      });
    });

    group('JSON serialization', () {
      test('round-trip toJson -> fromJson produces equal instance', () {
        final original = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          gustSpeed: 8.0,
          altitude: AltitudeLevel.midLevel,
          timestamp: timestamp,
        );

        final json = original.toJson();
        final restored = WindData.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
