import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/providers/lifecycle_provider.dart';
import 'package:wind_lens/core/services/sensor_service.dart';

/// A minimal [SensorService] implementation for lifecycle testing.
///
/// Records pause/resume/dispose calls so we can verify the lifecycle
/// provider calls them at the right time.
class RecordingSensorService implements SensorService {
  final List<String> calls = [];

  @override
  Stream<SensorState> get sensorStream => const Stream.empty();

  @override
  Stream<PositionData> get positionStream => const Stream.empty();

  @override
  void pause() => calls.add('pause');

  @override
  void resume() => calls.add('resume');

  @override
  void dispose() => calls.add('dispose');
}

void main() {
  // Ensure binding is initialized for WidgetsBindingObserver tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleObserver', () {
    late RecordingSensorService sensorService;
    late AppLifecycleObserver observer;

    setUp(() {
      sensorService = RecordingSensorService();
      observer = AppLifecycleObserver(sensorService: sensorService);
    });

    tearDown(() {
      observer.dispose();
    });

    test('pauses sensor service when app goes to paused state', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(sensorService.calls, ['pause']);
    });

    test('resumes sensor service when app returns to resumed state', () {
      // First pause
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      sensorService.calls.clear();

      // Then resume
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(sensorService.calls, ['resume']);
    });

    test('pauses sensor service on inactive state', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(sensorService.calls, ['pause']);
    });

    test('pauses sensor service on hidden state', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(sensorService.calls, ['pause']);
    });

    test('pauses sensor service on detached state', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(sensorService.calls, ['pause']);
    });

    test('does not double-pause if already paused', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      // DeviceSensorService.pause() guards internally, but observer should also guard
      expect(sensorService.calls, ['pause']);
    });

    test('does not double-resume if already running', () {
      // Start fresh (not paused)
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // Should not call resume because we're already running
      expect(sensorService.calls, isEmpty);
    });

    test('full lifecycle cycle: pause then resume', () {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(sensorService.calls, ['pause', 'resume']);
    });

    test('dispose removes observer and does not throw', () {
      expect(() => observer.dispose(), returnsNormally);
    });
  });
}
