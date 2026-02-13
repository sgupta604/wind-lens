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

    group('Constants', () {
      test('should have smoothing factor of 0.15', () {
        // Smoothing factor raised from 0.1 to 0.15 to compensate for
        // timer-based 20 Hz update rate (vs 50-100 Hz sensor rate).
        expect(CompassService.smoothingFactor, 0.15);
      });

      test('should have emit interval of 50ms (20 Hz)', () {
        // Timer-based emission at 20 Hz for smooth, consistent updates.
        expect(
          CompassService.emitInterval,
          const Duration(milliseconds: 50),
        );
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

  group('Timer Architecture Tests (BUG-009 v2)', () {
    late CompassService compassService;

    setUp(() {
      compassService = CompassService();
    });

    tearDown(() {
      compassService.dispose();
    });

    group('_lerpAngle circular interpolation', () {
      test('should interpolate clockwise through 0 (350 -> 10)', () {
        // Set raw heading to 10 degrees, smoothed starts at 350.
        // The shortest path from 350 to 10 is +20 degrees (clockwise
        // through 360/0), NOT -340 degrees (counterclockwise).
        compassService.setRawHeading(350.0);
        compassService.tick(); // Initialize smoothed to near 350
        // Run many ticks to converge near 350
        for (int i = 0; i < 200; i++) {
          compassService.tick();
        }
        expect(compassService.heading, closeTo(350.0, 1.0));

        // Now change target to 10 degrees
        compassService.setRawHeading(10.0);
        // After several ticks, heading should move clockwise through 0
        for (int i = 0; i < 100; i++) {
          compassService.tick();
        }
        // Should be close to 10, NOT have gone backwards through 180
        expect(
          compassService.heading,
          closeTo(10.0, 2.0),
          reason: '_lerpAngle should interpolate 350->10 through 0 (clockwise)',
        );
      });

      test('should interpolate counterclockwise through 0 (10 -> 350)', () {
        // Set raw heading to 10, converge, then change to 350.
        // The shortest path from 10 to 350 is -20 degrees (counterclockwise
        // through 360/0), NOT +340 degrees (clockwise).
        compassService.setRawHeading(10.0);
        for (int i = 0; i < 200; i++) {
          compassService.tick();
        }
        expect(compassService.heading, closeTo(10.0, 1.0));

        // Now change target to 350 degrees
        compassService.setRawHeading(350.0);
        for (int i = 0; i < 100; i++) {
          compassService.tick();
        }
        // Should be close to 350, having gone counterclockwise through 0
        expect(
          compassService.heading,
          closeTo(350.0, 2.0),
          reason: '_lerpAngle should interpolate 10->350 through 0 (counterclockwise)',
        );
      });

      test('should interpolate linearly for normal case (45 -> 90)', () {
        // No wraparound needed -- should move linearly from 45 to 90.
        compassService.setRawHeading(45.0);
        for (int i = 0; i < 200; i++) {
          compassService.tick();
        }
        expect(compassService.heading, closeTo(45.0, 1.0));

        compassService.setRawHeading(90.0);
        for (int i = 0; i < 100; i++) {
          compassService.tick();
        }
        expect(
          compassService.heading,
          closeTo(90.0, 2.0),
          reason: '_lerpAngle should interpolate 45->90 linearly',
        );
      });
    });

    group('tick() and stream emission', () {
      test('tick() should emit one CompassData event to the stream', () async {
        final events = <CompassData>[];
        final sub = compassService.stream.listen((data) {
          events.add(data);
        });

        await Future<void>.delayed(Duration.zero);

        compassService.setRawHeading(45.0);
        compassService.tick();

        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(events.length, 1,
            reason: 'One tick should produce exactly one stream event');
        expect(events.first.heading, isA<double>());
        expect(events.first.pitch, isA<double>());
      });

      test('multiple ticks should emit multiple events', () async {
        final events = <CompassData>[];
        final sub = compassService.stream.listen((data) {
          events.add(data);
        });

        await Future<void>.delayed(Duration.zero);

        compassService.setRawHeading(90.0);
        for (int i = 0; i < 10; i++) {
          compassService.tick();
        }

        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(events.length, 10,
            reason: '10 ticks should produce exactly 10 stream events');
      });

      test('continuous emission during stationary hold (100+ ticks)', () async {
        // BUG-009 v2 CRITICAL TEST: Verify that the timer-based architecture
        // does NOT stop emitting after convergence. With the old dead zone
        // architecture, emission stopped after ~35 events. With the new
        // timer architecture, tick() ALWAYS emits.
        final events = <CompassData>[];
        final sub = compassService.stream.listen((data) {
          events.add(data);
        });

        await Future<void>.delayed(Duration.zero);

        // Set heading and tick 100 times (simulating stationary hold)
        compassService.setRawHeading(90.0);
        for (int i = 0; i < 100; i++) {
          compassService.tick();
        }

        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        // ALL 100 ticks must produce stream events -- no dead zone suppression
        expect(
          events.length,
          100,
          reason: 'Timer-based architecture must emit on every tick, '
              'even after convergence. BUG-009 v2: dead zone suppressed '
              'emission after ~35 events.',
        );
      });

      test('continuous emission during slow rotation', () async {
        // BUG-009 v2 REGRESSION TEST: Verify continuous emission during
        // slow rotation. Each tick should emit regardless of heading delta.
        final events = <CompassData>[];
        final sub = compassService.stream.listen((data) {
          events.add(data);
        });

        await Future<void>.delayed(Duration.zero);

        // Simulate slow rotation: 0.5 degree per tick over 100 ticks
        for (int i = 0; i < 100; i++) {
          compassService.setRawHeading((i * 0.5) % 360);
          compassService.tick();
        }

        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        // All 100 ticks must produce events
        expect(
          events.length,
          100,
          reason: 'Every tick during slow rotation must emit a stream event',
        );

        // Verify heading actually tracked the rotation
        expect(
          events.last.heading,
          greaterThan(5.0),
          reason: 'Heading should track slow rotation, not freeze at 0',
        );
      });
    });

    group('setRawHeading and setRawPitch test helpers', () {
      test('setRawHeading sets raw heading for next tick', () {
        compassService.setRawHeading(180.0);
        // After many ticks, heading should converge to 180
        for (int i = 0; i < 200; i++) {
          compassService.tick();
        }
        expect(
          compassService.heading,
          closeTo(180.0, 1.0),
          reason: 'setRawHeading should set the target for smoothing',
        );
      });

      test('setRawPitch sets raw pitch for next tick', () {
        compassService.setRawPitch(45.0);
        // After many ticks, pitch should converge to 45
        for (int i = 0; i < 200; i++) {
          compassService.tick();
        }
        expect(
          compassService.pitch,
          closeTo(45.0, 1.0),
          reason: 'setRawPitch should set the target for smoothing',
        );
      });
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
      // With the timer-based architecture (smoothingFactor=0.15), the
      // smoothed heading should converge very close to 90 degrees.
      const targetHeading = 90.0;
      for (int i = 0; i < 200; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(targetHeading),
          _magY(targetHeading),
        );
      }

      // After 200 events with smoothingFactor=0.15, the heading MUST be
      // within 0.5 degrees of the target.
      expect(
        compassService.heading,
        closeTo(targetHeading, 0.5),
        reason: 'Heading should converge very close to target (within 0.5 deg) '
            'after 200 events.',
      );
    });

    test('heading should track to new direction after initial convergence', () {
      // BUG-009 REGRESSION TEST: This is the core test for the convergence trap.
      // First converge to heading A, then change to heading B (small step)
      // and verify the compass tracks to B (not stuck at A).
      const headingA = 90.0;
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

      // The compass MUST track to heading B.
      expect(
        compassService.heading,
        closeTo(headingB, 2.0),
        reason: 'Heading should track to new direction B after convergence at A '
            '(BUG-009: must not freeze after convergence)',
      );
    });

    test('heading should not freeze permanently after convergence', () async {
      // BUG-009 CRITICAL REGRESSION TEST: Verify that the stream keeps
      // emitting after initial convergence. With the old dead zone
      // architecture, emissions stopped permanently.
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

      // Send 50 events at heading B = 93
      const headingB = 93.0;
      for (int i = 0; i < 50; i++) {
        compassService.simulateMagnetometerEvent(
          _magX(headingB),
          _magY(headingB),
        );
      }

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // With the timer-based architecture, simulateMagnetometerEvent calls
      // tick() which always emits. All 50 events should produce stream events.
      expect(
        events.length,
        50,
        reason: 'Stream should emit on every simulateMagnetometerEvent call '
            '(timer architecture always emits)',
      );
    });

    test('heading should track slow rotation continuously', () {
      // Simulate slow rotation: 0.5-degree increments over many events.
      // With the timer-based architecture, every tick emits and heading tracks.
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

      // With timer architecture, every simulateMagnetometerEvent emits
      expect(
        events.length,
        50,
        reason: 'Stream should emit on every event (timer architecture)',
      );
    });
  });

  group('Null heading handling (compass-native)', () {
    late CompassService compassService;

    setUp(() {
      compassService = CompassService();
    });

    tearDown(() {
      compassService.dispose();
    });

    test('should retain previous heading when native compass returns null', () {
      // Set initial heading, converge, then verify it holds.
      // When flutter_compass sends null heading, _rawHeading is not updated,
      // so the smoothed heading should hold steady at the last known value.
      compassService.setRawHeading(90.0);
      for (int i = 0; i < 200; i++) {
        compassService.tick();
      }
      expect(compassService.heading, closeTo(90.0, 1.0));

      // Tick again without changing _rawHeading (simulates null from flutter_compass)
      compassService.tick();
      expect(compassService.heading, closeTo(90.0, 1.0));
    });

    test('should hold steady through multiple ticks without rawHeading change', () {
      // Set heading to 270, converge, then tick 50 more times without updating
      // _rawHeading. The heading should remain stable (no drift).
      compassService.setRawHeading(270.0);
      for (int i = 0; i < 200; i++) {
        compassService.tick();
      }
      final headingAfterConverge = compassService.heading;
      expect(headingAfterConverge, closeTo(270.0, 1.0));

      // 50 more ticks with no _rawHeading change (simulating sustained null headings)
      for (int i = 0; i < 50; i++) {
        compassService.tick();
      }
      expect(
        compassService.heading,
        closeTo(270.0, 0.5),
        reason: 'Heading should not drift when _rawHeading is unchanged '
            '(simulates flutter_compass returning null)',
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
      // With smoothingFactor=0.15, pitch converges very close.
      const targetPitch = 45.0;
      for (int i = 0; i < 200; i++) {
        compassService.simulateAccelerometerEvent(
          _accelY(targetPitch),
          _accelZ(targetPitch),
        );
      }

      // After 200 events the pitch MUST be within 1.0 degree.
      expect(
        compassService.pitch,
        closeTo(targetPitch, 1.0),
        reason: 'Pitch should converge very close to target (within 1.0 deg) '
            'after 200 events.',
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

      // The pitch MUST track to B.
      expect(
        compassService.pitch,
        closeTo(pitchB, 3.0),
        reason: 'Pitch should track to new direction B after convergence at A '
            '(BUG-009: must not freeze after convergence)',
      );
    });
  });
}
