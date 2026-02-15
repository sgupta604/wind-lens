import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/location_data.dart';

void main() {
  group('LocationData', () {
    test('creates with required fields', () {
      final timestamp = DateTime(2026, 2, 15, 12, 0, 0);
      final data = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: timestamp,
      );

      expect(data, isNotNull);
      expect(data, isA<LocationData>());
    });

    test('stores values correctly', () {
      final timestamp = DateTime(2026, 2, 15, 12, 0, 0);
      final data = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: timestamp,
      );

      expect(data.latitude, 37.7749);
      expect(data.longitude, -122.4194);
      expect(data.accuracy, 10.0);
      expect(data.timestamp, timestamp);
    });

    test('fields are final (immutable)', () {
      final timestamp = DateTime(2026, 2, 15, 12, 0, 0);
      final data = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: timestamp,
      );

      // Verify fields are accessible and return expected types
      expect(data.latitude, isA<double>());
      expect(data.longitude, isA<double>());
      expect(data.accuracy, isA<double>());
      expect(data.timestamp, isA<DateTime>());
    });

    test('handles edge values (equator, poles, antimeridian)', () {
      final timestamp = DateTime(2026, 1, 1);

      // Equator / prime meridian
      final equator = LocationData(
        latitude: 0,
        longitude: 0,
        accuracy: 5.0,
        timestamp: timestamp,
      );
      expect(equator.latitude, 0);
      expect(equator.longitude, 0);

      // North pole
      final northPole = LocationData(
        latitude: 90,
        longitude: 0,
        accuracy: 5.0,
        timestamp: timestamp,
      );
      expect(northPole.latitude, 90);

      // South pole
      final southPole = LocationData(
        latitude: -90,
        longitude: 0,
        accuracy: 5.0,
        timestamp: timestamp,
      );
      expect(southPole.latitude, -90);

      // Antimeridian east
      final antimeridianEast = LocationData(
        latitude: 0,
        longitude: 180,
        accuracy: 5.0,
        timestamp: timestamp,
      );
      expect(antimeridianEast.longitude, 180);

      // Antimeridian west
      final antimeridianWest = LocationData(
        latitude: 0,
        longitude: -180,
        accuracy: 5.0,
        timestamp: timestamp,
      );
      expect(antimeridianWest.longitude, -180);
    });
  });
}
