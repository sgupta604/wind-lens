import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/scene_state.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('SceneState', () {
    final timestamp = DateTime(2026, 2, 25, 12, 0, 0);

    late PositionData position;
    late HorizonProfile horizon;
    late WindData wind;
    late SkyMaskData skyMask;

    setUp(() {
      position = PositionData(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 15.0,
        accuracy: 10.0,
        timestamp: timestamp,
      );
      horizon = HorizonProfile.flat(37.7749, -122.4194);
      wind = WindData(
        uComponent: 3.0,
        vComponent: 4.0,
        altitude: AltitudeLevel.surface,
        timestamp: timestamp,
      );
      skyMask = SkyMaskData.fullSky();
    });

    group('construction', () {
      test('creates instance with all sub-models', () {
        final scene = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(scene.position, position);
        expect(scene.horizon.latitude, 37.7749);
        expect(scene.wind.speed, closeTo(5.0, 0.01));
        expect(scene.compassHeading, 127.3);
        expect(scene.pitch, 12.5);
        expect(scene.skyMask.skyFraction, 1.0);
        expect(scene.selectedAltitude, AltitudeLevel.surface);
        expect(scene.timestamp, timestamp);
      });
    });

    group('equality', () {
      test('same data produces equal instances', () {
        final a = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        final b = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different wind data produces unequal instances', () {
        final differentWind = WindData(
          uComponent: 10.0,
          vComponent: 10.0,
          altitude: AltitudeLevel.jetStream,
          timestamp: timestamp,
        );

        final a = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        final b = SceneState(
          position: position,
          horizon: horizon,
          wind: differentWind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(a, isNot(equals(b)));
      });

      test('different heading produces unequal instances', () {
        final a = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );
        final b = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 250.0,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('allows changing individual fields (altitude)', () {
        final original = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        final modified =
            original.copyWith(selectedAltitude: AltitudeLevel.jetStream);

        expect(modified.selectedAltitude, AltitudeLevel.jetStream);
        expect(modified.position, original.position);
        expect(modified.wind, original.wind);
        expect(modified.compassHeading, original.compassHeading);
      });

      test('allows changing compass heading', () {
        final original = SceneState(
          position: position,
          horizon: horizon,
          wind: wind,
          compassHeading: 127.3,
          pitch: 12.5,
          skyMask: skyMask,
          selectedAltitude: AltitudeLevel.surface,
          timestamp: timestamp,
        );

        final modified = original.copyWith(compassHeading: 300.0);

        expect(modified.compassHeading, 300.0);
        expect(modified.pitch, original.pitch);
      });
    });
  });
}
