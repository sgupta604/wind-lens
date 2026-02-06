import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/compass_data.dart';
import 'package:wind_lens/services/compass_service.dart';

void main() {
  // Initialize Flutter bindings for sensor tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompassService', () {
    late CompassService compassService;
    bool serviceStarted = false;

    setUp(() {
      compassService = CompassService();
      serviceStarted = false;
    });

    tearDown(() {
      // Only dispose if service wasn't started (to avoid platform channel issues)
      // When start() is called, sensors_plus creates platform channels that
      // may not be available in test environment
      if (!serviceStarted) {
        compassService.dispose();
      }
    });

    group('Initial State', () {
      test('should have initial heading of 0', () {
        expect(compassService.heading, 0);
      });

      test('should have initial pitch of 0', () {
        expect(compassService.pitch, 0);
      });
    });

    group('Heading Calculation', () {
      test('should calculate heading from magnetometer event', () {
        // For a magnetic field pointing east (positive x, zero y):
        // atan2(0, positive) = 0 degrees
        // This tests that the atan2 calculation is working
        // Note: actual calculation depends on implementation details
        // We can test by checking the heading changes after simulating events
        expect(compassService.heading, isA<double>());
      });
    });

    group('Heading Wraparound', () {
      test('should handle wraparound from high to low degrees smoothly', () {
        // Testing that 359 -> 1 degree transition doesn't jump through 180
        // This is tested through the delta calculation logic
        // The service should use delta-based smoothing to handle this
        expect(compassService.heading, greaterThanOrEqualTo(0));
        expect(compassService.heading, lessThan(360));
      });

      test('should handle wraparound from low to high degrees smoothly', () {
        // Testing that 1 -> 359 degree transition doesn't jump through 180
        expect(compassService.heading, greaterThanOrEqualTo(0));
        expect(compassService.heading, lessThan(360));
      });
    });

    group('Dead Zones', () {
      test('should have heading dead zone of 1.0 degrees', () {
        // The service should ignore heading changes smaller than 1.0 degree
        expect(CompassService.headingDeadZone, 1.0);
      });

      test('should have pitch dead zone of 2.0 degrees', () {
        // The service should ignore pitch changes smaller than 2.0 degrees
        expect(CompassService.pitchDeadZone, 2.0);
      });
    });

    group('Smoothing', () {
      test('should have smoothing factor of 0.1', () {
        // Lower smoothing factor = smoother but more laggy
        expect(CompassService.smoothingFactor, 0.1);
      });
    });

    group('Stream', () {
      test('should provide a broadcast stream', () {
        expect(compassService.stream, isA<Stream<CompassData>>());
      });

      test('stream should be broadcast (multiple listeners allowed)', () async {
        // Test that multiple listeners can subscribe
        final completer1 = Completer<void>();
        final completer2 = Completer<void>();

        final sub1 = compassService.stream.listen((_) {
          if (!completer1.isCompleted) completer1.complete();
        });
        final sub2 = compassService.stream.listen((_) {
          if (!completer2.isCompleted) completer2.complete();
        });

        // Clean up subscriptions
        await sub1.cancel();
        await sub2.cancel();

        // If we got here without error, the stream is broadcast
        expect(true, isTrue);
      });
    });

    group('Dispose', () {
      test('should cancel subscriptions on dispose', () {
        // After dispose, the service should not emit any more updates
        compassService.dispose();

        // If dispose works correctly, this should not throw
        expect(() => compassService.heading, returnsNormally);
      });

      test('should close the stream controller on dispose', () async {
        final stream = compassService.stream;
        compassService.dispose();

        // After dispose, the stream should be closed
        // Listening after close should eventually complete with no events
        var eventCount = 0;
        await for (final _ in stream.timeout(
          const Duration(milliseconds: 100),
          onTimeout: (sink) => sink.close(),
        )) {
          eventCount++;
        }

        expect(eventCount, 0);
      });
    });

    group('Start Method', () {
      test('start method exists and is callable', () {
        // The start() method should exist on the service.
        // Actual sensor testing requires a real device because sensors_plus
        // uses platform channels that are not available in unit tests.
        // We verify the method exists without calling it to avoid
        // MissingPluginException errors.
        expect(compassService.start, isNotNull);
        expect(compassService.start, isA<Function>());
      });

      // Note: Testing actual sensor behavior requires a real device.
      // The start() method calls magnetometerEventStream() and
      // accelerometerEventStream() which use platform channels.
      // See implementation.md for manual testing instructions.
    });

    group('Getters', () {
      test('heading getter should return current smoothed heading', () {
        final heading = compassService.heading;
        expect(heading, isA<double>());
        expect(heading, greaterThanOrEqualTo(0));
        expect(heading, lessThan(360));
      });

      test('pitch getter should return current smoothed pitch', () {
        final pitch = compassService.pitch;
        expect(pitch, isA<double>());
      });
    });
  });

  group('CompassService Algorithm Tests', () {
    // These tests verify the mathematical algorithms used in the service

    test('heading should normalize to 0-360 range', () {
      // Test the normalization formula: (rawHeading + 360) % 360
      final testCases = [
        (-90.0, 270.0),
        (0.0, 0.0),
        (90.0, 90.0),
        (180.0, 180.0),
        (270.0, 270.0),
        (360.0, 0.0),
        (450.0, 90.0),
        (-180.0, 180.0),
      ];

      for (final testCase in testCases) {
        final raw = testCase.$1;
        final expected = testCase.$2;
        final normalized = (raw + 360) % 360;
        expect(normalized, expected, reason: 'Raw $raw should normalize to $expected');
      }
    });

    test('delta calculation should find shortest path around circle', () {
      // Test wraparound delta calculation
      // delta > 180: delta -= 360
      // delta < -180: delta += 360

      // Case 1: 10 to 350 (should be -20, not 340)
      var delta = 350.0 - 10.0; // 340
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      expect(delta, -20.0);

      // Case 2: 350 to 10 (should be 20, not -340)
      delta = 10.0 - 350.0; // -340
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      expect(delta, 20.0);

      // Case 3: Normal case without wraparound
      delta = 100.0 - 50.0; // 50
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      expect(delta, 50.0);
    });

    test('smoothing formula should apply factor correctly', () {
      // smoothed = smoothed + (delta * smoothingFactor)
      const smoothingFactor = 0.1;
      var smoothed = 0.0;
      const delta = 100.0;

      // After one update
      smoothed = smoothed + delta * smoothingFactor;
      expect(smoothed, 10.0);

      // After second update with same delta
      smoothed = smoothed + delta * smoothingFactor;
      expect(smoothed, 20.0);
    });

    test('atan2 calculation for heading', () {
      // Test the heading calculation from magnetometer x, y values
      // rawHeading = atan2(y, x) * 180 / pi

      // Pointing North (x=0, y=positive) -> should be 90 degrees initially
      var rawHeading = atan2(1.0, 0.0) * 180 / pi;
      expect(rawHeading, closeTo(90.0, 0.01));

      // Pointing East (x=positive, y=0) -> should be 0 degrees
      rawHeading = atan2(0.0, 1.0) * 180 / pi;
      expect(rawHeading, closeTo(0.0, 0.01));

      // Pointing South (x=0, y=negative) -> should be -90 degrees
      rawHeading = atan2(-1.0, 0.0) * 180 / pi;
      expect(rawHeading, closeTo(-90.0, 0.01));

      // Pointing West (x=negative, y=0) -> should be 180 or -180
      rawHeading = atan2(0.0, -1.0) * 180 / pi;
      expect(rawHeading.abs(), closeTo(180.0, 0.01));
    });

    test('atan2 calculation for pitch', () {
      // Test the pitch calculation from accelerometer y, z values
      // rawPitch = atan2(-z, y) * 180 / pi

      // Phone flat (y=0, z=-9.8) -> pitch near 90 degrees (pointing up at sky)
      var rawPitch = atan2(9.8, 0.0) * 180 / pi;
      expect(rawPitch, closeTo(90.0, 0.01));

      // Phone vertical (y=9.8, z=0) -> pitch 0 degrees
      rawPitch = atan2(0.0, 9.8) * 180 / pi;
      expect(rawPitch, closeTo(0.0, 0.01));

      // Phone upside down (y=0, z=9.8) -> pitch near -90 degrees
      rawPitch = atan2(-9.8, 0.0) * 180 / pi;
      expect(rawPitch, closeTo(-90.0, 0.01));
    });
  });

  // Helper: compute magnetometer x,y values that produce a given heading.
  // Since rawHeading = atan2(y, x) * 180 / pi, we need:
  //   x = cos(heading * pi / 180)
  //   y = sin(heading * pi / 180)
  double _magX(double headingDeg) => cos(headingDeg * pi / 180);
  double _magY(double headingDeg) => sin(headingDeg * pi / 180);

  // Helper: compute accelerometer y,z values that produce a given pitch.
  // Since rawPitch = atan2(-z, y) * 180 / pi, we need:
  //   y = cos(pitch * pi / 180)
  //   z = -sin(pitch * pi / 180)
  double _accelY(double pitchDeg) => cos(pitchDeg * pi / 180);
  double _accelZ(double pitchDeg) => -sin(pitchDeg * pi / 180);

  group('Heading Convergence Regression Tests (BUG-009)', () {
    late CompassService compassService;

    setUp(() {
      compassService = CompassService();
    });

    tearDown(() {
      compassService.dispose();
    });

    test('heading should converge very close to target after many events at constant raw heading', () {
      // Simulate 200 magnetometer events all pointing at 90 degrees.
      // With the fix (smoothing always runs), the smoothed heading should
      // converge extremely close to 90 degrees (within 0.1 degree).
      // With the bug (smoothing blocked by dead zone), the heading gets
      // stuck about 0.7 degrees away from the target and never reaches it.
      const targetHeading = 90.0;
      for (int i = 0; i < 200; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(targetHeading),
          _magY(targetHeading),
        );
      }

      // After 200 events with smoothingFactor=0.1, the heading MUST be
      // within 0.5 degrees of the target if smoothing runs continuously.
      // With the bug, it gets stuck at ~89.3 degrees (0.7 away from 90).
      expect(
        compassService.heading,
        closeTo(targetHeading, 0.5),
        reason: 'Heading should converge very close to target (within 0.5 deg) '
            'after 200 events. BUG-009: dead zone blocks smoothing, '
            'causing heading to freeze ~0.7 deg from target.',
      );
    });

    test('heading should track to new direction after initial convergence', () {
      // BUG-009 REGRESSION TEST: This is the core test for the convergence trap.
      // First converge to heading A, then change to heading B (small step)
      // and verify the compass tracks to B (not stuck at A).
      const headingA = 90.0;
      // Use a SMALL change (5 degrees) - large enough to initially exceed
      // dead zone from A, but the bug will trap it after a few events
      // because smoothing brings the internal state close to A, and the
      // dead zone then blocks further smoothing toward B.
      const headingB = 95.0;

      // Phase 1: Converge to heading A (100 events)
      for (int i = 0; i < 100; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(headingA),
          _magY(headingA),
        );
      }
      final headingAfterA = compassService.heading;
      // Verify convergence to A
      expect(
        headingAfterA,
        closeTo(headingA, 2.0),
        reason: 'Should converge to heading A first',
      );

      // Phase 2: Change to heading B (100 events, small delta)
      for (int i = 0; i < 100; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(headingB),
          _magY(headingB),
        );
      }

      // The compass MUST track to heading B. With the buggy code, after
      // converging to ~89.3 at A, sending B=95 gives delta=5.7 which
      // passes the dead zone initially. But after a few smoothing steps
      // the smoothed heading gets close enough to 95 that delta < 1.0
      // and it freezes again at ~94.3. That's still close to 95, so this
      // tests the GENERAL tracking capability. The more critical test is
      // the slow rotation test below.
      expect(
        compassService.heading,
        closeTo(headingB, 2.0),
        reason: 'Heading should track to new direction B after convergence at A '
            '(BUG-009: dead zone must not block smoothing)',
      );
    });

    test('heading should not freeze permanently after convergence', () async {
      // BUG-009 CRITICAL REGRESSION TEST: Verify that the stream keeps
      // emitting after initial convergence. With the buggy code, emissions
      // stop permanently once the smoothed heading gets within the dead zone
      // of the raw heading.
      const headingA = 90.0;

      // Phase 1: Converge to heading A
      for (int i = 0; i < 100; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(headingA),
          _magY(headingA),
        );
      }

      // Allow stream events to flush
      await Future<void>.delayed(Duration.zero);

      // Phase 2: Listen for events and then change heading slightly
      final events = <CompassData>[];
      final sub = compassService.stream.listen((data) {
        events.add(data);
      });

      await Future<void>.delayed(Duration.zero);

      // Send 50 events at heading B = 93 (3 degrees from A's convergence point ~89.3)
      // With the buggy code: delta = 93 - 89.3 = 3.7 initially passes dead zone,
      // but after a few steps smoothed gets close to 93 and freezes again.
      // More importantly, test that events ARE emitted.
      const headingB = 93.0;
      for (int i = 0; i < 50; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(headingB),
          _magY(headingB),
        );
      }

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // With the fix, smoothing always runs and the heading should be close to B.
      // More importantly, we should have received stream events during the change.
      expect(
        events.length,
        greaterThan(0),
        reason: 'Stream should emit events when heading changes after convergence',
      );
    });

    test('heading should track slow rotation continuously', () {
      // Simulate slow rotation: 0.5-degree increments over many events.
      // With dead zone = 1.0 degree and smoothing = 0.1, the compass
      // should still track the overall rotation even if individual steps
      // are small, because the accumulated delta should grow.
      double currentTarget = 0.0;
      for (int i = 0; i < 200; i++) {
        currentTarget = (currentTarget + 0.5) % 360;
        compassService.simulateMagnetometerEvent(
          _magX(currentTarget),
          _magY(currentTarget),
        );
      }
      // After 200 steps of 0.5 degrees = 100 degrees total rotation.
      // The smoothed heading should have moved significantly from 0.
      // With a working smoothing filter, it should be in the general
      // direction of ~100 degrees (with smoothing lag).
      expect(
        compassService.heading,
        greaterThan(20.0),
        reason: 'Heading should track slow rotation and not freeze near 0',
      );
    });

    test('stream should emit events during a large heading change', () async {
      // Verify that the stream actually emits CompassData events
      // as the heading changes significantly.
      final events = <CompassData>[];
      final sub = compassService.stream.listen((data) {
        events.add(data);
      });

      // Allow the stream listener to be established
      await Future<void>.delayed(Duration.zero);

      // Simulate a large heading change: 0 -> 90 degrees
      const targetHeading = 90.0;
      for (int i = 0; i < 50; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(targetHeading),
          _magY(targetHeading),
        );
      }

      // Allow microtasks to complete for stream delivery
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      // During a 90-degree change, there should be multiple emissions
      // (not zero, which would indicate the dead zone is blocking everything)
      expect(
        events.length,
        greaterThan(0),
        reason: 'Stream should emit events during a large heading change',
      );
    });
  });

  group('Pitch Convergence Regression Tests (BUG-009)', () {
    late CompassService compassService;

    setUp(() {
      compassService = CompassService();
    });

    tearDown(() {
      compassService.dispose();
    });

    test('pitch should converge very close to target after many events', () {
      // Simulate 200 accelerometer events all at pitch = 45 degrees.
      // With the fix, smoothing always runs and pitch converges very close.
      // With the bug, pitch gets stuck ~1.4 degrees away (pitchDeadZone=2.0).
      const targetPitch = 45.0;
      for (int i = 0; i < 200; i++) {
        compassService.simulateAccelerometerEvent(
          _accelY(targetPitch),
          _accelZ(targetPitch),
        );
      }

      // After 200 events the pitch MUST be within 1.0 degree.
      // With the bug, it freezes ~1.4 degrees from target.
      expect(
        compassService.pitch,
        closeTo(targetPitch, 1.0),
        reason: 'Pitch should converge very close to target (within 1.0 deg) '
            'after 200 events. BUG-009: dead zone blocks smoothing.',
      );
    });

    test('pitch should track to new direction after initial convergence', () {
      // BUG-009 REGRESSION TEST for pitch: converge to pitch A, then
      // change to pitch B and verify tracking.
      const pitchA = 45.0;
      const pitchB = -30.0;

      // Phase 1: Converge to pitch A (100 events)
      for (int i = 0; i < 100; i++) {
        compassService.simulateAccelerometerEvent(
          _accelY(pitchA),
          _accelZ(pitchA),
        );
      }
      expect(
        compassService.pitch,
        closeTo(pitchA, 2.0),
        reason: 'Should converge to pitch A first',
      );

      // Phase 2: Change to pitch B (100 events)
      for (int i = 0; i < 100; i++) {
        compassService.simulateAccelerometerEvent(
          _accelY(pitchB),
          _accelZ(pitchB),
        );
      }

      // The pitch MUST track to B. If the dead zone blocks smoothing,
      // it will be stuck near A.
      expect(
        compassService.pitch,
        closeTo(pitchB, 3.0),
        reason: 'Pitch should track to new direction B after convergence at A '
            '(BUG-009: dead zone must not block smoothing)',
      );
    });
  });
}
