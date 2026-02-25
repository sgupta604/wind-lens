import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/core/models/position_data.dart';

void main() {
  group('StablePosition', () {
    group('_distanceMeters', () {
      test('returns 0 for identical positions', () {
        final pos = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        expect(StablePosition.distanceMetersForTest(pos, pos), closeTo(0.0, 0.1));
      });

      test('returns ~111km for 1 degree latitude difference', () {
        final a = PositionData(
          latitude: 0.0,
          longitude: 0.0,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        final b = PositionData(
          latitude: 1.0,
          longitude: 0.0,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        // 1 degree latitude = ~111,195 meters
        final distance = StablePosition.distanceMetersForTest(a, b);
        expect(distance, closeTo(111195, 500));
      });

      test('returns small distance for nearby points', () {
        final a = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        // About 50 meters away
        final b = PositionData(
          latitude: 37.77535,
          longitude: -122.4194,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        final distance = StablePosition.distanceMetersForTest(a, b);
        expect(distance, closeTo(50, 10));
      });

      test('returns >100m for positions more than 100m apart', () {
        final a = PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        // About 200 meters away (roughly 0.0018 degrees latitude)
        final b = PositionData(
          latitude: 37.77672,
          longitude: -122.4194,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        final distance = StablePosition.distanceMetersForTest(a, b);
        expect(distance, greaterThan(100));
      });
    });
  });

  group('SensorNotifiers', () {
    test('heading defaults to 0.0', () {
      final notifiers = SensorNotifiers();
      expect(notifiers.heading.value, 0.0);
      notifiers.dispose();
    });

    test('pitch defaults to 0.0', () {
      final notifiers = SensorNotifiers();
      expect(notifiers.pitch.value, 0.0);
      notifiers.dispose();
    });

    test('heading can be updated', () {
      final notifiers = SensorNotifiers();
      notifiers.heading.value = 180.0;
      expect(notifiers.heading.value, 180.0);
      notifiers.dispose();
    });

    test('pitch can be updated', () {
      final notifiers = SensorNotifiers();
      notifiers.pitch.value = 45.0;
      expect(notifiers.pitch.value, 45.0);
      notifiers.dispose();
    });

    test('dispose does not throw', () {
      final notifiers = SensorNotifiers();
      expect(() => notifiers.dispose(), returnsNormally);
    });
  });
}
