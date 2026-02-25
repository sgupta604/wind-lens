import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/scene_state.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('SceneState composition', () {
    test('can be constructed with all sub-models', () {
      final now = DateTime.now();
      final position = PositionData(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 0.0,
        accuracy: 5.0,
        timestamp: now,
      );
      final horizon = HorizonProfile.flat(37.7749, -122.4194);
      final wind = WindData.zero();
      final skyMask = SkyMaskData.fullSky();

      final scene = SceneState(
        position: position,
        horizon: horizon,
        wind: wind,
        compassHeading: 127.3,
        pitch: 12.5,
        skyMask: skyMask,
        selectedAltitude: AltitudeLevel.surface,
        timestamp: now,
      );

      expect(scene.position, position);
      expect(scene.horizon, horizon);
      expect(scene.wind, wind);
      expect(scene.compassHeading, 127.3);
      expect(scene.pitch, 12.5);
      expect(scene.skyMask, skyMask);
      expect(scene.selectedAltitude, AltitudeLevel.surface);
    });

    test('fallback horizon is flat', () {
      final horizon = HorizonProfile.flat(37.7749, -122.4194);
      expect(horizon.getElevationAtBearing(0), 0.0);
      expect(horizon.getElevationAtBearing(180), 0.0);
    });

    test('fallback sky mask is full sky', () {
      final skyMask = SkyMaskData.fullSky();
      expect(skyMask.skyFraction, 1.0);
      expect(skyMask.isPointInSky(0.5, 0.5), true);
    });

    test('scene state uses copyWith for altitude change', () {
      final now = DateTime.now();
      final scene = SceneState(
        position: PositionData(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 0.0,
          accuracy: 5.0,
          timestamp: now,
        ),
        horizon: HorizonProfile.flat(37.7749, -122.4194),
        wind: WindData.zero(),
        compassHeading: 0.0,
        pitch: 0.0,
        skyMask: SkyMaskData.fullSky(),
        selectedAltitude: AltitudeLevel.surface,
        timestamp: now,
      );

      final updated = scene.copyWith(selectedAltitude: AltitudeLevel.jetStream);
      expect(updated.selectedAltitude, AltitudeLevel.jetStream);
      expect(updated.position, scene.position);
    });
  });
}
