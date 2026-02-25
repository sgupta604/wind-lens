import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/services/wind_data_source.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/services/wind/mock_wind_source.dart';

void main() {
  group('MockWindDataSource', () {
    late MockWindDataSource source;
    late PositionData testPosition;

    setUp(() {
      source = MockWindDataSource();
      testPosition = PositionData(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 0.0,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
    });

    test('implements WindDataSource interface', () {
      expect(source, isA<WindDataSource>());
    });

    test('returns a valid WindData future', () async {
      final wind = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );

      expect(wind, isA<WindData>());
      expect(wind.uComponent, isA<double>());
      expect(wind.vComponent, isA<double>());
      expect(wind.altitude, AltitudeLevel.surface);
    });

    test('isSimulated is true', () {
      expect(source.isSimulated, true);
    });

    test('returns different wind data for different altitude levels', () async {
      final surfaceWind = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );
      final midWind = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.midLevel,
      );
      final jetWind = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.jetStream,
      );

      // Different altitude levels should have different speeds
      // (due to speed multiplier in FakeWindService)
      expect(midWind.speed, greaterThan(surfaceWind.speed));
      expect(jetWind.speed, greaterThan(midWind.speed));

      // Altitude levels should match
      expect(surfaceWind.altitude, AltitudeLevel.surface);
      expect(midWind.altitude, AltitudeLevel.midLevel);
      expect(jetWind.altitude, AltitudeLevel.jetStream);
    });

    test('wind speed is positive', () async {
      final wind = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );

      expect(wind.speed, greaterThan(0));
    });
  });
}
