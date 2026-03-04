import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';

void main() {
  group('HorizonProfile', () {
    final timestamp = DateTime(2026, 2, 25, 12, 0, 0);

    group('construction', () {
      test('creates instance with all fields', () {
        final profile = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 5.0, 90.0: 10.0, 180.0: 3.0, 270.0: 7.0},
          fetchedAt: timestamp,
        );

        expect(profile.latitude, 37.7749);
        expect(profile.longitude, -122.4194);
        expect(profile.elevationAngles.length, 4);
        expect(profile.fetchedAt, timestamp);
      });
    });

    group('equality', () {
      test('same data produces equal instances', () {
        final a = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 5.0, 90.0: 10.0},
          fetchedAt: timestamp,
        );
        final b = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 5.0, 90.0: 10.0},
          fetchedAt: timestamp,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different data produces unequal instances', () {
        final a = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 5.0},
          fetchedAt: timestamp,
        );
        final b = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 10.0},
          fetchedAt: timestamp,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('getElevationAtBearing', () {
      test('returns exact match when bearing exists in map', () {
        final profile = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {0.0: 5.0, 90.0: 10.0, 180.0: 3.0, 270.0: 7.0},
          fetchedAt: timestamp,
        );

        expect(profile.getElevationAtBearing(0.0), 5.0);
        expect(profile.getElevationAtBearing(90.0), 10.0);
        expect(profile.getElevationAtBearing(180.0), 3.0);
        expect(profile.getElevationAtBearing(270.0), 7.0);
      });

      test('interpolates between two entries', () {
        final profile = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {0.0: 0.0, 90.0: 10.0},
          fetchedAt: timestamp,
        );

        // At bearing 45 (halfway between 0 and 90), elevation should be ~5.0
        expect(profile.getElevationAtBearing(45.0), closeTo(5.0, 0.01));

        // At bearing 30 (1/3 of way), elevation should be ~3.33
        expect(profile.getElevationAtBearing(30.0), closeTo(10.0 / 3, 0.01));
      });

      test('handles wraparound near 0/360 degrees', () {
        final profile = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {350.0: 10.0, 10.0: 20.0},
          fetchedAt: timestamp,
        );

        // At bearing 0 (halfway between 350 and 10), should interpolate
        // Range is 20 degrees (350 to 10 via 0)
        // Position at 0 is 10 degrees from 350
        // t = 10/20 = 0.5
        // Expected: 10 + (20-10)*0.5 = 15.0
        expect(profile.getElevationAtBearing(0.0), closeTo(15.0, 0.01));

        // At bearing 355, position is 5/20 from lower
        // Expected: 10 + (20-10)*0.25 = 12.5
        expect(profile.getElevationAtBearing(355.0), closeTo(12.5, 0.01));
      });

      test('handles empty map gracefully', () {
        final profile = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {},
          fetchedAt: timestamp,
        );

        expect(profile.getElevationAtBearing(45.0), 0.0);
      });

      test('handles single entry in map', () {
        final profile = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {180.0: 5.0},
          fetchedAt: timestamp,
        );

        // With only one entry, that value should be returned for any bearing
        // (lower and upper both point to 180)
        expect(profile.getElevationAtBearing(180.0), 5.0);
        expect(profile.getElevationAtBearing(90.0), 5.0);
      });

      test('normalizes bearings outside 0-360 range', () {
        final profile = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {0.0: 5.0, 180.0: 10.0},
          fetchedAt: timestamp,
        );

        // 360 should normalize to 0
        expect(profile.getElevationAtBearing(360.0), closeTo(5.0, 0.01));

        // Negative bearings should wrap
        expect(profile.getElevationAtBearing(-180.0), closeTo(10.0, 0.01));
      });
    });

    group('flat() factory', () {
      test('returns 0 elevation at any bearing', () {
        final profile = HorizonProfile.flat(37.0, -122.0);

        expect(profile.getElevationAtBearing(0), 0.0);
        expect(profile.getElevationAtBearing(45), 0.0);
        expect(profile.getElevationAtBearing(90), 0.0);
        expect(profile.getElevationAtBearing(180), 0.0);
        expect(profile.getElevationAtBearing(270), 0.0);
        expect(profile.getElevationAtBearing(359), 0.0);
      });

      test('has matching lat/lng', () {
        final profile = HorizonProfile.flat(37.0, -122.0);

        expect(profile.latitude, 37.0);
        expect(profile.longitude, -122.0);
      });

      test('has 360 entries (one per degree)', () {
        final profile = HorizonProfile.flat(0, 0);

        expect(profile.elevationAngles.length, 360);
      });
    });

    group('JSON serialization', () {
      test('round-trip toJson -> fromJson produces equal instance', () {
        final original = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 5.0, 90.0: 10.0, 180.0: 3.0, 270.0: 7.0},
          fetchedAt: timestamp,
        );

        final json = original.toJson();
        final restored = HorizonProfile.fromJson(json);

        expect(restored, equals(original));
      });

      test('handles empty elevation map in JSON', () {
        final original = HorizonProfile(
          latitude: 0,
          longitude: 0,
          elevationAngles: {},
          fetchedAt: timestamp,
        );

        final json = original.toJson();
        final restored = HorizonProfile.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('declination and panoramaId fields', () {
      test('declination defaults to 0.0', () {
        final profile = HorizonProfile(
          latitude: 37.0,
          longitude: -122.0,
          elevationAngles: {0.0: 5.0},
          fetchedAt: timestamp,
        );

        expect(profile.declination, 0.0);
      });

      test('panoramaId defaults to null', () {
        final profile = HorizonProfile(
          latitude: 37.0,
          longitude: -122.0,
          elevationAngles: {0.0: 5.0},
          fetchedAt: timestamp,
        );

        expect(profile.panoramaId, isNull);
      });

      test('JSON round-trip preserves declination and panoramaId', () {
        final original = HorizonProfile(
          latitude: 47.6062,
          longitude: -122.3321,
          elevationAngles: {0.0: 5.0, 90.0: 10.0},
          fetchedAt: timestamp,
          declination: 15.0,
          panoramaId: 'RDJCX2LU',
        );

        final json = original.toJson();
        final restored = HorizonProfile.fromJson(json);

        expect(restored, equals(original));
        expect(restored.declination, 15.0);
        expect(restored.panoramaId, 'RDJCX2LU');
      });

      test('flat() factory has declination 0.0 and panoramaId null', () {
        final profile = HorizonProfile.flat(37.0, -122.0);

        expect(profile.declination, 0.0);
        expect(profile.panoramaId, isNull);
      });
    });
  });
}
