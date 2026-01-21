import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/models/wind_data.dart';
import 'package:wind_lens/services/fake_wind_service.dart';

void main() {
  group('FakeWindService', () {
    late FakeWindService service;

    setUp(() {
      service = FakeWindService();
    });

    group('getWind()', () {
      test('returns WindData instance', () {
        final wind = service.getWind();

        expect(wind, isA<WindData>());
        expect(wind.uComponent, isA<double>());
        expect(wind.vComponent, isA<double>());
        expect(wind.altitude, isA<double>());
        expect(wind.timestamp, isA<DateTime>());
      });

      test('wind data has valid speed greater than 0', () {
        final wind = service.getWind();

        expect(wind.speed, greaterThan(0));
      });

      test('wind speed is in expected surface range (1-6 m/s)', () {
        // Call multiple times to check range
        for (int i = 0; i < 10; i++) {
          final wind = service.getWind();
          // Surface wind range from spec: u = 3.0 + sin(t) * 2.0 = 1-5 m/s
          // v = 2.0 + cos(t) * 1.5 = 0.5-3.5 m/s
          // Combined speed: sqrt((1-5)^2 + (0.5-3.5)^2) ranges from ~1.1 to ~6.1 m/s
          expect(wind.speed, greaterThanOrEqualTo(1.0));
          expect(wind.speed, lessThanOrEqualTo(7.0)); // Allow some margin
        }
      });

      test('wind varies over time (two calls at different times differ)', () async {
        final wind1 = service.getWind();

        // Wait a bit for time to change
        await Future.delayed(const Duration(milliseconds: 100));

        final wind2 = service.getWind();

        // At least one component should differ (time-based oscillation)
        // Note: With short delay, values may be very close but not identical
        // We check that the values are somewhat different
        final uDiff = (wind1.uComponent - wind2.uComponent).abs();
        final vDiff = (wind1.vComponent - wind2.vComponent).abs();

        // At least some difference should exist
        expect(uDiff > 0 || vDiff > 0, true,
            reason: 'Wind should vary over time');
      });

      test('returns surface altitude (10m)', () {
        final wind = service.getWind();

        expect(wind.altitude, 10.0);
      });

      test('returns current timestamp', () {
        final before = DateTime.now();
        final wind = service.getWind();
        final after = DateTime.now();

        expect(
          wind.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
          true,
        );
        expect(
          wind.timestamp.isBefore(after.add(const Duration(seconds: 1))),
          true,
        );
      });
    });
  });

  group('getWindForAltitude()', () {
    late FakeWindService service;

    setUp(() {
      service = FakeWindService();
    });

    test('returns WindData for surface altitude', () {
      final wind = service.getWindForAltitude(AltitudeLevel.surface);

      expect(wind, isA<WindData>());
      expect(wind.altitude, 10.0);
    });

    test('returns WindData for midLevel altitude', () {
      final wind = service.getWindForAltitude(AltitudeLevel.midLevel);

      expect(wind, isA<WindData>());
      expect(wind.altitude, 1500.0);
    });

    test('returns WindData for jetStream altitude', () {
      final wind = service.getWindForAltitude(AltitudeLevel.jetStream);

      expect(wind, isA<WindData>());
      expect(wind.altitude, 10500.0);
    });

    test('wind speed increases with altitude level', () {
      final surfaceWind = service.getWindForAltitude(AltitudeLevel.surface);
      final midWind = service.getWindForAltitude(AltitudeLevel.midLevel);
      final jetWind = service.getWindForAltitude(AltitudeLevel.jetStream);

      // Mid-level wind should be faster than surface (1.5x multiplier)
      expect(midWind.speed, greaterThan(surfaceWind.speed));

      // Jet stream should be faster than mid-level (3.0x vs 1.5x)
      expect(jetWind.speed, greaterThan(midWind.speed));
    });

    test('returns correct altitude value in WindData', () {
      final surfaceWind = service.getWindForAltitude(AltitudeLevel.surface);
      final midWind = service.getWindForAltitude(AltitudeLevel.midLevel);
      final jetWind = service.getWindForAltitude(AltitudeLevel.jetStream);

      expect(surfaceWind.altitude, AltitudeLevel.surface.metersAGL);
      expect(midWind.altitude, AltitudeLevel.midLevel.metersAGL);
      expect(jetWind.altitude, AltitudeLevel.jetStream.metersAGL);
    });
  });
}
