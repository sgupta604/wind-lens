import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/sensor_state.dart';

void main() {
  group('SensorState', () {
    final timestamp = DateTime(2026, 2, 25, 12, 0, 0);

    group('construction', () {
      test('creates instance with all fields', () {
        final state = SensorState(
          compassHeading: 127.3,
          pitch: 12.5,
          timestamp: timestamp,
        );

        expect(state.compassHeading, 127.3);
        expect(state.pitch, 12.5);
        expect(state.timestamp, timestamp);
      });
    });

    group('equality', () {
      test('same data produces equal instances', () {
        final a = SensorState(
          compassHeading: 127.3,
          pitch: 12.5,
          timestamp: timestamp,
        );
        final b = SensorState(
          compassHeading: 127.3,
          pitch: 12.5,
          timestamp: timestamp,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different data produces unequal instances', () {
        final a = SensorState(
          compassHeading: 127.3,
          pitch: 12.5,
          timestamp: timestamp,
        );
        final b = SensorState(
          compassHeading: 180.0,
          pitch: 12.5,
          timestamp: timestamp,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('produces modified copy', () {
        final original = SensorState(
          compassHeading: 127.3,
          pitch: 12.5,
          timestamp: timestamp,
        );

        final modified = original.copyWith(pitch: 45.0);

        expect(modified.compassHeading, original.compassHeading);
        expect(modified.pitch, 45.0);
        expect(modified.timestamp, original.timestamp);
      });
    });

    group('field names', () {
      test('uses compassHeading not heading (matches SPEC-001)', () {
        final state = SensorState(
          compassHeading: 90.0,
          pitch: 0.0,
          timestamp: timestamp,
        );

        // Verify the field is named compassHeading, not heading
        expect(state.compassHeading, 90.0);
      });
    });
  });
}
