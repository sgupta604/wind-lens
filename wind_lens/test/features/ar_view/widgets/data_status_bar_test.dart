import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/scene_state.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/features/ar_view/widgets/data_status_bar.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('DataStatusBar', () {
    testWidgets('shows "Waiting for GPS..." when no position and no scene',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataStatusBar(
              sceneState: null,
              hasPosition: false,
            ),
          ),
        ),
      );

      expect(find.text('Waiting for GPS...'), findsOneWidget);
    });

    testWidgets(
        'shows "Loading wind data..." when position available but no scene',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataStatusBar(
              sceneState: null,
              hasPosition: true,
            ),
          ),
        ),
      );

      expect(find.text('Loading wind data...'), findsOneWidget);
    });

    testWidgets('renders empty SizedBox when sceneState is available',
        (tester) async {
      final now = DateTime.now();
      final position = PositionData(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 0.0,
        accuracy: 5.0,
        timestamp: now,
      );
      final scene = SceneState(
        position: position,
        horizon: HorizonProfile.flat(37.7749, -122.4194),
        wind: WindData.zero(),
        compassHeading: 0.0,
        pitch: 0.0,
        skyMask: SkyMaskData.fullSky(),
        selectedAltitude: AltitudeLevel.surface,
        timestamp: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataStatusBar(
              sceneState: scene,
              hasPosition: true,
            ),
          ),
        ),
      );

      // DataStatusBar should render an empty SizedBox when data is ready
      expect(find.text('Waiting for GPS...'), findsNothing);
      expect(find.text('Loading wind data...'), findsNothing);
    });

    testWidgets('has a semi-transparent background when showing status',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataStatusBar(
              sceneState: null,
              hasPosition: false,
            ),
          ),
        ),
      );

      // Verify a Container with BoxDecoration is rendered
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DataStatusBar),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    testWidgets('shows a loading indicator when status is displayed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataStatusBar(
              sceneState: null,
              hasPosition: false,
            ),
          ),
        ),
      );

      // Should have a circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('text has white color for visibility over camera feed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataStatusBar(
              sceneState: null,
              hasPosition: false,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Waiting for GPS...'));
      expect(text.style?.color, Colors.white);
    });
  });
}
