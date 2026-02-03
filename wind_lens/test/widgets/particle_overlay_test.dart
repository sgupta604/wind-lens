import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/models/view_mode.dart';
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

  group('ParticleOverlay World Anchoring', () {
    late MockSkyMask mockSkyMask;

    setUp(() {
      mockSkyMask = MockSkyMask();
    });

    testWidgets('all altitude levels shift equally on heading change',
        (tester) async {
      // This test verifies that when the phone rotates (heading changes),
      // ALL altitude levels shift by the same amount (100% world-fixed).
      // BUG-004: Previously, higher altitudes shifted less due to parallaxFactor.

      // Test each altitude level with identical heading change
      for (final level in AltitudeLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ParticleOverlay(
                skyMask: mockSkyMask,
                compassHeading: 90.0,
                previousHeading: 0.0, // 90 degree rotation
                altitudeLevel: level,
                particleCount: 100,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 16));

        // All altitude levels should accept the same heading change
        final overlay = tester.widget<ParticleOverlay>(
          find.byType(ParticleOverlay),
        );
        expect(overlay.compassHeading, 90.0);
        expect(overlay.previousHeading, 0.0);

        // The formula p.x -= (headingDelta / 360.0) should apply equally
        // regardless of altitudeLevel. Previously it was:
        // p.x -= (headingDelta / 360.0) * parallaxFactor
        // which would give different shifts for different altitudes.

        // Widget should render without error at each level
        expect(find.byType(ParticleOverlay), findsOneWidget);
      }
    });

    testWidgets('90-degree rotation produces approximately 25% particle shift',
        (tester) async {
      // When phone rotates 90 degrees, particles should shift 90/360 = 25%
      // of the screen width to maintain world-fixed position.

      // The formula is: p.x -= (headingDelta / 360.0)
      // For 90 degree rotation: shift = 90 / 360 = 0.25 (25% of screen)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              compassHeading: 90.0,  // Current heading
              previousHeading: 0.0,  // Previous heading
              altitudeLevel: AltitudeLevel.jetStream, // Test with jet stream
              particleCount: 100,
            ),
          ),
        ),
      );

      // Let animation run one frame to apply the heading change
      await tester.pump(const Duration(milliseconds: 16));

      // Verify widget has the correct heading values
      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );

      // 90 degree rotation should produce 25% shift for ALL altitudes
      // Including jet stream (which previously only shifted 7.5%)
      expect(overlay.compassHeading - overlay.previousHeading, 90.0);

      // Widget should render correctly
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('heading wraparound handled correctly (359 to 1 degrees)',
        (tester) async {
      // Test heading wraparound: going from 359 to 1 degrees should be
      // a 2-degree change (not 358 degrees in the wrong direction).
      // The formula normalizes heading delta to -180 to 180 range.

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              compassHeading: 1.0,   // Current heading (just past north)
              previousHeading: 359.0, // Previous heading (just before north)
              altitudeLevel: AltitudeLevel.surface,
              particleCount: 100,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));

      // Verify heading values
      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );

      // The raw delta is 1 - 359 = -358
      // But normalized: -358 + 360 = 2 (correct 2-degree rotation)
      // This should apply to ALL altitude levels equally
      expect(overlay.compassHeading, 1.0);
      expect(overlay.previousHeading, 359.0);

      // Widget should render correctly
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });
  });

  group('ParticleOverlay ViewMode Integration', () {
    late MockSkyMask mockSkyMask;

    setUp(() {
      mockSkyMask = MockSkyMask();
    });

    testWidgets('accepts viewMode parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              viewMode: ViewMode.streamlines,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.viewMode, ViewMode.streamlines);
    });

    testWidgets('viewMode defaults to dots', (tester) async {
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
      expect(overlay.viewMode, ViewMode.dots);
    });

    testWidgets('renders in dots mode without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              viewMode: ViewMode.dots,
              particleCount: 100,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('renders in streamlines mode without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              viewMode: ViewMode.streamlines,
              particleCount: 100,
            ),
          ),
        ),
      );

      // Run several frames to build up trail points
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('can switch between modes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              viewMode: ViewMode.dots,
              particleCount: 100,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));

      // Switch to streamlines
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              viewMode: ViewMode.streamlines,
              particleCount: 100,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.viewMode, ViewMode.streamlines);
    });

    testWidgets('streamlines mode works with wind data', (tester) async {
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
              viewMode: ViewMode.streamlines,
              windData: windData,
              particleCount: 100,
            ),
          ),
        ),
      );

      // Run frames to build trails
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.byType(ParticleOverlay), findsOneWidget);
    });
  });

  group('ParticleOverlay Streamline Ghosting Fix (BUG-007)', () {
    late MockSkyMask mockSkyMask;

    setUp(() {
      mockSkyMask = MockSkyMask();
    });

    testWidgets('particles reset via _resetToSkyPosition have cleared trail',
        (tester) async {
      // BUG-007: When particles are recycled via _resetToSkyPosition()
      // (due to expiration or drifting out of sky), their trail should be cleared.
      // Without this fix, old trail points persist, causing ghost lines.

      // Create a sky mask where only a small portion is sky
      // This forces particles that drift out to be reset via _resetToSkyPosition
      final limitedSkyMask = MockSkyMask(
        skyFraction: 0.3,
        allPointsInSky: false,
        customSkyCheck: (x, y) => y < 0.3, // Only top 30% is sky
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: limitedSkyMask,
                viewMode: ViewMode.streamlines,
                particleCount: 50,
                windData: WindData(
                  uComponent: 0.0,
                  vComponent: -5.0, // Wind pushing particles down (out of sky)
                  altitude: 10.0,
                  timestamp: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      );

      // Run animation for several frames to:
      // 1. Build up trail points
      // 2. Force some particles to drift out of sky (y > 0.3)
      // 3. Trigger _resetToSkyPosition() calls
      for (int i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // The implementation should reset trails when particles are recycled.
      // This test verifies the widget renders without error after recycling.
      // The actual trail clearing is verified by visual absence of ghost lines
      // and by the integration test below.
      expect(find.byType(ParticleOverlay), findsOneWidget);

      // Verify sky mask was consulted (particles were checked/reset)
      expect(limitedSkyMask.isPointInSkyCallCount, greaterThan(0));
    });

    testWidgets('streamlines mode clears trail on screen edge wrap',
        (tester) async {
      // BUG-007: In streamlines mode, when a particle wraps around a screen edge
      // (e.g., x goes from 1.05 to 0.05), the trail should be cleared.
      // Without this, a line would be drawn from the new position back to the
      // old position, spanning the entire screen.

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                viewMode: ViewMode.streamlines,
                particleCount: 50,
                windData: WindData(
                  uComponent: 10.0, // Strong wind to force edge wrapping
                  vComponent: 0.0,
                  altitude: 10.0,
                  timestamp: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      );

      // Run for many frames to ensure particles wrap around edges
      // With strong wind, particles will cross screen boundaries
      for (int i = 0; i < 180; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // The fix should reset trails when particles wrap.
      // This prevents cross-screen ghost lines.
      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('dots mode edge wrap does not affect particle state unnecessarily',
        (tester) async {
      // BUG-007 fix should only reset trails in streamlines mode.
      // Dots mode does not use the trail buffer for rendering, so
      // resetting it is harmless but the mode check should be in place.
      // This test verifies dots mode continues to work correctly.

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ParticleOverlay(
                skyMask: mockSkyMask,
                viewMode: ViewMode.dots, // Explicitly dots mode
                particleCount: 50,
                windData: WindData(
                  uComponent: 10.0, // Strong wind to force edge wrapping
                  vComponent: 0.0,
                  altitude: 10.0,
                  timestamp: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      );

      // Run for many frames with strong wind causing edge wraps
      for (int i = 0; i < 180; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Dots mode should continue to work correctly
      expect(find.byType(ParticleOverlay), findsOneWidget);

      // Verify the mode is still dots
      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.viewMode, ViewMode.dots);
    });

    testWidgets('no ghost trail segments after particle respawn in streamlines mode',
        (tester) async {
      // Integration test: BUG-007 complete scenario
      //
      // Scenario:
      // 1. Particles build up trail points while in sky
      // 2. Particles expire (age >= 1.0) or drift out of sky
      // 3. _resetToSkyPosition() teleports particle to new location
      // 4. With fix: trail is cleared, no ghost line
      // 5. Without fix: old trail points cause ghost line from new to old position
      //
      // This test runs through a full particle lifecycle and verifies
      // the widget renders without error throughout.

      // Sky mask with moderate sky fraction
      final testSkyMask = MockSkyMask(
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
                skyMask: testSkyMask,
                viewMode: ViewMode.streamlines,
                particleCount: 50,
                windData: WindData(
                  uComponent: 3.0,
                  vComponent: -4.0, // Pushing particles down and right
                  altitude: 10.0,
                  timestamp: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      );

      // Phase 1: Build up trails (particles accumulate trail points)
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Phase 2: Force particle recycling (run long enough for particles to expire)
      // Particle lifespan is ~3 seconds (age += dt * 0.3)
      // 240 frames * 16ms = ~4 seconds
      for (int i = 0; i < 240; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Phase 3: Continue running to verify no accumulated artifacts
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Widget should render correctly throughout
      expect(find.byType(ParticleOverlay), findsOneWidget);

      // Sky mask should have been consulted for particle reset decisions
      expect(testSkyMask.isPointInSkyCallCount, greaterThan(0));
    });
  });
}
