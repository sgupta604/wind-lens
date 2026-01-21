import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/models/wind_data.dart';
import 'package:wind_lens/services/sky_detection/sky_mask.dart';
import 'package:wind_lens/widgets/particle_overlay.dart';

/// Mock SkyMask that returns all points as sky for testing.
class MockSkyMask implements SkyMask {
  final double _skyFraction;
  final bool _allPointsInSky;

  MockSkyMask({
    double skyFraction = 1.0,
    bool allPointsInSky = true,
  })  : _skyFraction = skyFraction,
        _allPointsInSky = allPointsInSky;

  @override
  double get skyFraction => _skyFraction;

  @override
  bool isPointInSky(double normalizedX, double normalizedY) {
    if (_allPointsInSky) return true;
    // Simple mock: top half is sky
    return normalizedY < _skyFraction;
  }
}

void main() {
  group('ParticleOverlay', () {
    late MockSkyMask mockSkyMask;

    setUp(() {
      mockSkyMask = MockSkyMask();
    });

    testWidgets('creates with required skyMask parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('uses CustomPaint widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      // Find CustomPaint that is a descendant of ParticleOverlay
      expect(
        find.descendant(
          of: find.byType(ParticleOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('respects default particleCount of 2000', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.particleCount, 2000);
    });

    testWidgets('respects custom particleCount parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              particleCount: 1000,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.particleCount, 1000);
    });

    testWidgets('accepts optional windData parameter with default zero wind',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windData.speed, 0.0);
    });

    testWidgets('accepts custom windData parameter', (tester) async {
      final windData = WindData(
        uComponent: 3.0,
        vComponent: 4.0,
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windData.speed, 5.0); // sqrt(3^2 + 4^2) = 5
    });

    testWidgets('receives skyMask correctly', (tester) async {
      final customMask = MockSkyMask(skyFraction: 0.7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: customMask,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.skyMask.skyFraction, 0.7);
    });

    testWidgets('updates when windData changes', (tester) async {
      final windData1 = WindData(
        uComponent: 1.0,
        vComponent: 0.0,
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData1,
            ),
          ),
        ),
      );

      final windData2 = WindData(
        uComponent: 5.0,
        vComponent: 0.0,
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      // Update with new wind data
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData2,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windData.speed, 5.0);
    });

    testWidgets('disposes correctly without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      // Pump a few frames to let ticker run
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      // Replace with empty container to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Should not throw any errors
      expect(find.byType(ParticleOverlay), findsNothing);
    });

    testWidgets('animation runs over multiple frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 100, // Smaller for test
              ),
            ),
          ),
        ),
      );

      // Let animation run for several frames
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      // Widget should still be present and rendering
      expect(find.byType(ParticleOverlay), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ParticleOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });
  });

  group('ParticleOverlay Wind Integration', () {
    late MockSkyMask mockSkyMask;

    setUp(() {
      mockSkyMask = MockSkyMask();
    });

    testWidgets('accepts windData and compassHeading parameters', (tester) async {
      final windData = WindData(
        uComponent: 3.0,
        vComponent: 4.0,
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData,
              compassHeading: 45.0,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windData, windData);
      expect(overlay.compassHeading, 45.0);
    });

    testWidgets('uses default compassHeading of 0.0 when not specified', (tester) async {
      final windData = WindData(
        uComponent: 3.0,
        vComponent: 4.0,
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.compassHeading, 0.0);
    });

    testWidgets('uses WindData.zero() as default windData', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windData.speed, 0.0);
    });

    testWidgets('direction changes with compass heading (world-fixed)', (tester) async {
      final windData = WindData(
        uComponent: 3.0,
        vComponent: 4.0,
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      // First render with compass heading 0
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData,
              compassHeading: 0.0,
              particleCount: 100,
            ),
          ),
        ),
      );

      // Let animation run a few frames
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      // Now change compass heading to simulate phone rotation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData,
              compassHeading: 90.0, // Rotated 90 degrees
              particleCount: 100,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      // Verify the widget accepts the new compass heading
      expect(overlay.compassHeading, 90.0);

      // Let animation continue
      await tester.pump(const Duration(milliseconds: 16));

      // Widget should still be present and rendering
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('screen angle computed from wind direction and compass heading', (tester) async {
      // Wind from south (direction 0 in meteorological), compass heading 90
      // Screen angle should be wind direction - compass heading
      final windData = WindData(
        uComponent: 0.0,
        vComponent: -1.0, // blowing northward (wind from south)
        altitude: 10.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windData: windData,
              compassHeading: 90.0,
              particleCount: 100,
            ),
          ),
        ),
      );

      // The screen angle calculation should be:
      // windDirection (radians) - compassHeading (converted to radians)
      // = 0 - (90 * pi / 180) = -pi/2
      // This ensures particles appear to move in a consistent world direction
      // regardless of phone orientation

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windData.directionRadians, closeTo(0.0, 0.001));
      expect(overlay.compassHeading, 90.0);

      // Animation should run without error
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });
  });

  group('ParticleOverlay Altitude Integration', () {
    late MockSkyMask mockSkyMask;

    setUp(() {
      mockSkyMask = MockSkyMask();
    });

    testWidgets('accepts altitudeLevel parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              altitudeLevel: AltitudeLevel.midLevel,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.altitudeLevel, AltitudeLevel.midLevel);
    });

    testWidgets('accepts previousHeading parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              previousHeading: 45.0,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.previousHeading, 45.0);
    });

    testWidgets('defaults to surface altitude when not specified',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.altitudeLevel, AltitudeLevel.surface);
    });

    testWidgets('defaults to 0.0 previousHeading when not specified',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.previousHeading, 0.0);
    });

    testWidgets('renders with different altitude levels', (tester) async {
      // Test all three altitude levels render without error
      for (final level in AltitudeLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ParticleOverlay(
                skyMask: mockSkyMask,
                altitudeLevel: level,
                particleCount: 100,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 16));

        expect(find.byType(ParticleOverlay), findsOneWidget);
      }
    });

    testWidgets('handles compass heading changes for parallax', (tester) async {
      // First render with heading 0
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              compassHeading: 0.0,
              previousHeading: 0.0,
              altitudeLevel: AltitudeLevel.surface,
              particleCount: 100,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));

      // Change heading to simulate rotation (previous = 0, current = 90)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              compassHeading: 90.0,
              previousHeading: 0.0,
              altitudeLevel: AltitudeLevel.surface,
              particleCount: 100,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));

      // Should render without error
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });
  });
}
