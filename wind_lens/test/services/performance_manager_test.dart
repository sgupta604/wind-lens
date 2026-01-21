import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/services/performance_manager.dart';

void main() {
  group('PerformanceManager', () {
    late PerformanceManager performanceManager;

    setUp(() {
      performanceManager = PerformanceManager();
    });

    group('initial state', () {
      test('starts with default particle count of 2000', () {
        expect(performanceManager.particleCount, 2000);
      });

      test('starts with default FPS of 60', () {
        expect(performanceManager.currentFps, 60.0);
      });
    });

    group('recordFrame', () {
      test('calculates FPS from duration', () {
        // Simulate 60 FPS (16.67ms per frame)
        const frameTime = Duration(microseconds: 16667);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + frameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Should calculate ~60 FPS
        expect(performanceManager.currentFps, closeTo(60.0, 1.0));
      });

      test('clamps FPS values between 0 and 120', () {
        // Test with very fast frames (would be >120 FPS)
        const veryFastFrame = Duration(microseconds: 5000); // 200 FPS
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + veryFastFrame;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // FPS should be clamped to 120
        expect(performanceManager.currentFps, lessThanOrEqualTo(120.0));
      });
    });

    group('particle adjustment', () {
      test('reduces particles to 70% when avgFps below 45', () {
        // Simulate 30 FPS (33.33ms per frame) for 30 frames
        const slowFrameTime = Duration(microseconds: 33333);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + slowFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // 2000 * 0.7 = 1400 particles
        expect(performanceManager.particleCount, 1400);
      });

      test('increases particles by 10% when avgFps above 58', () {
        // First reduce particles by simulating low FPS
        const slowFrameTime = Duration(microseconds: 33333);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + slowFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        final reducedCount = performanceManager.particleCount;
        expect(reducedCount, lessThan(2000));

        // Now simulate high FPS (60 FPS)
        const fastFrameTime = Duration(microseconds: 16667);

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + fastFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Should increase by 10%
        expect(performanceManager.particleCount,
            (reducedCount * 1.1).round().clamp(500, 2000));
      });

      test('never reduces below minimum 500 particles', () {
        // Simulate extremely low FPS repeatedly
        const verySlowFrameTime = Duration(microseconds: 100000); // 10 FPS
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        // Run many adjustment cycles (each 30 frames)
        for (int cycle = 0; cycle < 10; cycle++) {
          for (int i = 0; i < 30; i++) {
            lastElapsed = elapsed;
            elapsed = elapsed + verySlowFrameTime;
            performanceManager.recordFrame(elapsed, lastElapsed);
          }
        }

        // Should never go below 500
        expect(performanceManager.particleCount, greaterThanOrEqualTo(500));
      });

      test('never exceeds maximum 2000 particles', () {
        // Simulate high FPS repeatedly, but we can't increase beyond 2000
        const fastFrameTime = Duration(microseconds: 16667);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        // Run many adjustment cycles
        for (int cycle = 0; cycle < 10; cycle++) {
          for (int i = 0; i < 30; i++) {
            lastElapsed = elapsed;
            elapsed = elapsed + fastFrameTime;
            performanceManager.recordFrame(elapsed, lastElapsed);
          }
        }

        // Should never exceed 2000
        expect(performanceManager.particleCount, lessThanOrEqualTo(2000));
      });

      test('only adjusts after full window of 30 frames', () {
        // Simulate low FPS but only for 29 frames
        const slowFrameTime = Duration(microseconds: 33333);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 29; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + slowFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Should NOT have adjusted yet
        expect(performanceManager.particleCount, 2000);

        // Add one more frame to complete the window
        lastElapsed = elapsed;
        elapsed = elapsed + slowFrameTime;
        performanceManager.recordFrame(elapsed, lastElapsed);

        // NOW it should adjust
        expect(performanceManager.particleCount, lessThan(2000));
      });

      test('clears window after particle adjustment', () {
        // Simulate low FPS for 30 frames to trigger adjustment
        const slowFrameTime = Duration(microseconds: 33333);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + slowFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        final countAfterFirstAdjustment = performanceManager.particleCount;
        expect(countAfterFirstAdjustment, 1400); // 2000 * 0.7

        // Add 29 more low FPS frames - should not adjust again (window cleared)
        for (int i = 0; i < 29; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + slowFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Still same count (window not yet full)
        expect(performanceManager.particleCount, countAfterFirstAdjustment);

        // Add 30th frame to complete window
        lastElapsed = elapsed;
        elapsed = elapsed + slowFrameTime;
        performanceManager.recordFrame(elapsed, lastElapsed);

        // Now it should adjust again
        expect(
            performanceManager.particleCount, lessThan(countAfterFirstAdjustment));
      });
    });

    group('reset', () {
      test('reset restores default values', () {
        // First modify state by simulating frames
        const slowFrameTime = Duration(microseconds: 33333);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + slowFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Verify state was modified
        expect(performanceManager.particleCount, lessThan(2000));
        expect(performanceManager.currentFps, lessThan(60.0));

        // Reset
        performanceManager.reset();

        // Verify defaults are restored
        expect(performanceManager.particleCount, 2000);
        expect(performanceManager.currentFps, 60.0);
      });
    });

    group('edge cases', () {
      test('handles zero duration between frames gracefully', () {
        // Simulate zero time between frames
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        // Should not crash
        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          // elapsed stays the same (zero duration)
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Should handle gracefully (default to 60 FPS for zero duration)
        expect(performanceManager.currentFps, greaterThan(0));
      });

      test('does not adjust particles when FPS is between 45 and 58', () {
        // Simulate ~50 FPS (20ms per frame)
        const mediumFrameTime = Duration(microseconds: 20000);
        Duration elapsed = Duration.zero;
        Duration lastElapsed = Duration.zero;

        for (int i = 0; i < 30; i++) {
          lastElapsed = elapsed;
          elapsed = elapsed + mediumFrameTime;
          performanceManager.recordFrame(elapsed, lastElapsed);
        }

        // Particle count should remain at 2000 (50 FPS is in acceptable range)
        expect(performanceManager.particleCount, 2000);
      });
    });
  });
}
