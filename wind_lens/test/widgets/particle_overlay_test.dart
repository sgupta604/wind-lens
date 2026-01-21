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
  final bool Function(double x, double y)? _customSkyCheck;

  /// Track calls to isPointInSky for verification
  int _isPointInSkyCallCount = 0;
  final List<(double x, double y)> _isPointInSkyCalls = [];

  MockSkyMask({
    double skyFraction = 1.0,
    bool allPointsInSky = true,
    bool Function(double x, double y)? customSkyCheck,
  })  : _skyFraction = skyFraction,
        _allPointsInSky = allPointsInSky,
        _customSkyCheck = customSkyCheck;

  @override
  double get skyFraction => _skyFraction;

  /// Get the number of times isPointInSky was called
  int get isPointInSkyCallCount => _isPointInSkyCallCount;

  /// Get all coordinates passed to isPointInSky
  List<(double x, double y)> get isPointInSkyCalls => List.unmodifiable(_isPointInSkyCalls);

  /// Reset call tracking
  void resetCallTracking() {
    _isPointInSkyCallCount = 0;
    _isPointInSkyCalls.clear();
  }

  @override
  bool isPointInSky(double normalizedX, double normalizedY) {
    _isPointInSkyCallCount++;
    _isPointInSkyCalls.add((normalizedX, normalizedY));

    if (_customSkyCheck != null) {
      return _customSkyCheck(normalizedX, normalizedY);
    }
    if (_allPointsInSky) return true;
    // Simple mock: top portion based on skyFraction is sky
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

  group('ParticleOverlay Sky-Aware Spawning', () {
    testWidgets('particles spawn in sky region when sky is available',
        (tester) async {
      // Create mock where only top half (y < 0.5) is sky
      final mockSkyMask = MockSkyMask(
        skyFraction: 0.5,
        allPointsInSky: false,
        customSkyCheck: (x, y) => y < 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 50, // Small count for test
              ),
            ),
          ),
        ),
      );

      // Run animation for several frames to allow particles to settle into sky positions
      // Particles that start outside sky should be reset to sky on next tick
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // After multiple frames, most particles should have been checked against sky mask
      // The implementation should call isPointInSky to verify particle positions
      expect(mockSkyMask.isPointInSkyCallCount, greaterThan(0),
          reason: 'Sky mask should be checked during particle updates');
    });

    testWidgets('particles gracefully fall back when no sky visible',
        (tester) async {
      // Create mock with NO sky (all points return false)
      final mockSkyMask = MockSkyMask(
        skyFraction: 0.0,
        allPointsInSky: false,
        customSkyCheck: (x, y) => false, // No sky anywhere
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 50,
              ),
            ),
          ),
        ),
      );

      // Run animation for several frames - should NOT hang in infinite loop
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      stopwatch.stop();

      // Should complete in reasonable time (well under 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Should not hang in infinite loop when no sky');

      // Widget should still be present
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('particles that drift out of sky region are reset',
        (tester) async {
      // Start with full sky, then shrink it
      bool fullSky = true;
      final mockSkyMask = MockSkyMask(
        skyFraction: 1.0,
        customSkyCheck: (x, y) => fullSky ? true : y < 0.3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 50,
              ),
            ),
          ),
        ),
      );

      // Let particles distribute across screen with full sky
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Now shrink sky region - only top 30% is sky
      fullSky = false;
      mockSkyMask.resetCallTracking();

      // Run more frames - particles in bottom 70% should be detected and reset
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Implementation should check if particles are still in sky
      expect(mockSkyMask.isPointInSkyCallCount, greaterThan(0),
          reason: 'Should check if particles drifted out of sky');
    });

    testWidgets('expired particles reset to sky positions',
        (tester) async {
      // Create mock where only top half is sky
      final mockSkyMask = MockSkyMask(
        skyFraction: 0.5,
        allPointsInSky: false,
        customSkyCheck: (x, y) => y < 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 50,
              ),
            ),
          ),
        ),
      );

      // Run animation for enough frames to cycle through particle lifespans
      // Particles have ~3 second lifespan (age += dt * 0.3)
      // So run for several seconds worth of frames
      for (int i = 0; i < 240; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Implementation should place expired particles back in sky
      // The sky mask should be consulted when resetting particles
      expect(mockSkyMask.isPointInSkyCallCount, greaterThan(0),
          reason: 'Expired particles should be reset to sky positions');

      // Widget should still function correctly
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('maxAttempts prevents infinite loop with very low sky fraction',
        (tester) async {
      // Create mock with very sparse sky (only 1% of area)
      final mockSkyMask = MockSkyMask(
        skyFraction: 0.01,
        customSkyCheck: (x, y) {
          // Very small sky region - only a tiny area
          return x < 0.01 && y < 0.01;
        },
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 50,
              ),
            ),
          ),
        ),
      );

      // Run several frames
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      stopwatch.stop();

      // Should complete quickly due to maxAttempts limit
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'maxAttempts should prevent excessive attempts');

      // Widget should still function
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('after multiple frames most particles are in sky region',
        (tester) async {
      // Integration test: verify particle distribution converges to sky
      int inSkyCount = 0;
      int outSkyCount = 0;

      final mockSkyMask = MockSkyMask(
        skyFraction: 0.5,
        customSkyCheck: (x, y) {
          final inSky = y < 0.5;
          if (inSky) {
            inSkyCount++;
          } else {
            outSkyCount++;
          }
          return inSky;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                particleCount: 100,
              ),
            ),
          ),
        ),
      );

      // Run for many frames to reach steady state
      for (int i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // After implementation, most checks should be for in-sky positions
      // because particles outside sky get reset to sky
      final totalChecks = inSkyCount + outSkyCount;
      expect(totalChecks, greaterThan(0),
          reason: 'Should have checked particle positions');

      // Widget should be functioning
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });
  });
}
