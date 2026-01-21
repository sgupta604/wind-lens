import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('accepts optional windAngle parameter with default 0.0',
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
      expect(overlay.windAngle, 0.0);
    });

    testWidgets('accepts custom windAngle parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windAngle: 1.57, // ~90 degrees
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windAngle, 1.57);
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

    testWidgets('updates when windAngle changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windAngle: 0.0,
            ),
          ),
        ),
      );

      // Update with new wind angle
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              skyMask: mockSkyMask,
              windAngle: 3.14,
            ),
          ),
        ),
      );

      final overlay = tester.widget<ParticleOverlay>(
        find.byType(ParticleOverlay),
      );
      expect(overlay.windAngle, 3.14);
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
}
