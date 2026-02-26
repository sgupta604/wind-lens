import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/altitude_level.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/scene_state.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/scene_provider.dart';
import 'package:wind_lens/features/home/widgets/home_wind_row.dart';

void main() {
  final now = DateTime.now();

  SceneState _makeScene({
    double uComponent = -7.2,
    double vComponent = -6.5,
    AltitudeLevel altitude = AltitudeLevel.surface,
  }) {
    return SceneState(
      position: PositionData(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 0.0,
        accuracy: 5.0,
        timestamp: now,
      ),
      horizon: HorizonProfile.flat(37.7749, -122.4194),
      wind: WindData(
        uComponent: uComponent,
        vComponent: vComponent,
        altitude: altitude,
        timestamp: now,
      ),
      compassHeading: 0.0,
      pitch: 0.0,
      skyMask: SkyMaskData.fullSky(),
      selectedAltitude: altitude,
      timestamp: now,
    );
  }

  group('HomeWindRow', () {
    testWidgets('shows placeholder "--" when sceneState is null',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sceneStateProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeWindRow()),
          ),
        ),
      );

      // Should show at least two "--" placeholders (speed and direction)
      expect(find.text('--'), findsAtLeast(2));
    });

    testWidgets('shows formatted speed value when wind data available',
        (tester) async {
      final scene = _makeScene(uComponent: -7.2, vComponent: -6.5);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sceneStateProvider.overrideWithValue(scene),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeWindRow()),
          ),
        ),
      );

      // speed = sqrt(7.2^2 + 6.5^2) = sqrt(51.84 + 42.25) = sqrt(94.09) ~ 9.7
      expect(find.text('9.7'), findsOneWidget);
    });

    testWidgets('shows cardinal direction when wind data available',
        (tester) async {
      // u=-7.2, v=-6.5: direction = atan2(7.2, 6.5) * 180/pi + 360 % 360
      // = ~47.9 degrees -> NE
      final scene = _makeScene(uComponent: -7.2, vComponent: -6.5);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sceneStateProvider.overrideWithValue(scene),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeWindRow()),
          ),
        ),
      );

      expect(find.text('NE'), findsOneWidget);
    });

    testWidgets('shows altitude label matching selectedAltitudeProvider',
        (tester) async {
      final scene = _makeScene(altitude: AltitudeLevel.midLevel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sceneStateProvider.overrideWithValue(scene),
            selectedAltitudeProvider.overrideWith(() => _MidLevelAltitude()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeWindRow()),
          ),
        ),
      );

      expect(find.text('4.9K'), findsOneWidget);
      expect(find.text('ft AGL'), findsOneWidget);
    });
  });
}

/// Override notifier that starts at midLevel.
class _MidLevelAltitude extends SelectedAltitude {
  @override
  AltitudeLevel build() => AltitudeLevel.midLevel;
}
