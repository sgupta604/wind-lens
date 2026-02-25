import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';

void main() {
  group('PositionData', () {
    final timestamp = DateTime(2026, 2, 25, 12, 0, 0);

    group('construction', () {
      test('creates instance with all fields', () {
        final data = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );

        expect(data.latitude, 37.7749);
        expect(data.longitude, -122.4194);
        expect(data.altitude, 15.0);
        expect(data.accuracy, 10.0);
        expect(data.timestamp, timestamp);
      });
    });

    group('equality', () {
      test('same data produces equal instances', () {
        final a = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );
        final b = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different data produces unequal instances', () {
        final a = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );
        final b = PositionData(
          latitude: 37.7750,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('produces modified copy', () {
        final original = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );

        final modified = original.copyWith(latitude: 40.0);

        expect(modified.latitude, 40.0);
        expect(modified.longitude, original.longitude);
        expect(modified.altitude, original.altitude);
        expect(modified.accuracy, original.accuracy);
        expect(modified.timestamp, original.timestamp);
      });
    });

    group('JSON serialization', () {
      test('round-trip toJson -> fromJson produces equal instance', () {
        final original = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 15.0,
          accuracy: 10.0,
          timestamp: timestamp,
        );

        final json = original.toJson();
        final restored = PositionData.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('altitude field', () {
      test('altitude field exists and stores value', () {
        final data = PositionData(
          latitude: 0,
          longitude: 0,
          altitude: 100.5,
          accuracy: 0,
          timestamp: timestamp,
        );

        expect(data.altitude, 100.5);
      });
    });
  });
}
