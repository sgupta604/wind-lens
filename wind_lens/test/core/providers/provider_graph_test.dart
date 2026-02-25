import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/scene_state.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/lifecycle_provider.dart';
import 'package:wind_lens/core/providers/scene_provider.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/core/providers/service_providers.dart';
import 'package:wind_lens/core/services/horizon_provider.dart' as core;
import 'package:wind_lens/core/services/sensor_service.dart';
import 'package:wind_lens/core/services/wind_data_source.dart';
import 'package:wind_lens/models/altitude_level.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A controllable [SensorService] for integration testing.
///
/// Provides StreamControllers that tests can push data into.
class ControllableSensorService implements SensorService {
  final _sensorController = StreamController<SensorState>.broadcast();
  final _positionController = StreamController<PositionData>.broadcast();
  final List<String> calls = [];

  @override
  Stream<SensorState> get sensorStream => _sensorController.stream;

  @override
  Stream<PositionData> get positionStream => _positionController.stream;

  void emitSensor(SensorState state) => _sensorController.add(state);
  void emitPosition(PositionData position) => _positionController.add(position);

  @override
  void pause() => calls.add('pause');

  @override
  void resume() => calls.add('resume');

  @override
  void dispose() {
    calls.add('dispose');
    _sensorController.close();
    _positionController.close();
  }
}

/// A controllable [WindDataSource] for integration testing.
class ControllableWindDataSource implements WindDataSource {
  final List<String> calls = [];
  WindData Function(PositionData position, AltitudeLevel altitude)? resultFn;

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) async {
    calls.add('getWind(${altitude.name})');
    if (resultFn != null) {
      return resultFn!(position, altitude);
    }
    return WindData(
      uComponent: 3.0,
      vComponent: 4.0,
      altitude: altitude,
      timestamp: DateTime.now(),
    );
  }

  @override
  bool get isSimulated => true;
}

/// A controllable [HorizonProvider] for integration testing.
class ControllableHorizonProvider implements core.HorizonProvider {
  final List<String> calls = [];

  @override
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  }) async {
    calls.add('getHorizon($latitude, $longitude)');
    return HorizonProfile.flat(latitude, longitude);
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

PositionData _makePosition(double lat, double lng) => PositionData(
      latitude: lat,
      longitude: lng,
      altitude: 0.0,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );

SensorState _makeSensor({double heading = 0.0, double pitch = 0.0}) =>
    SensorState(
      compassHeading: heading,
      pitch: pitch,
      timestamp: DateTime.now(),
    );

/// Pumps the microtask queue enough times for stream data and async providers
/// to propagate through the Riverpod dependency chain.
///
/// A single stream emission goes through:
/// 1. StreamController -> listener (microtask)
/// 2. Stream provider state update (microtask)
/// 3. Dependent provider rebuild (microtask)
/// 4. FutureProvider resolution (microtask)
///
/// We flush multiple times to ensure all layers have processed.
Future<void> _pumpProviders() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Required for WidgetsBindingObserver in lifecycle tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Provider graph integration', () {
    late ControllableSensorService sensorService;
    late ControllableWindDataSource windDataSource;
    late ControllableHorizonProvider horizonProvider;

    setUp(() {
      sensorService = ControllableSensorService();
      windDataSource = ControllableWindDataSource();
      horizonProvider = ControllableHorizonProvider();
    });

    tearDown(() {
      if (!sensorService.calls.contains('dispose')) {
        sensorService.dispose();
      }
    });

    /// Creates a [ProviderContainer] with service overrides.
    ///
    /// Subscribes to key providers so they don't auto-dispose, and
    /// returns the container. Caller must call `container.dispose()`.
    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sensorServiceProvider.overrideWithValue(sensorService),
          windDataSourceProvider.overrideWithValue(windDataSource),
          horizonProviderServiceProvider.overrideWithValue(horizonProvider),
        ],
      );
      // Keep providers alive by listening to them (auto-dispose needs listeners)
      container.listen(sceneStateProvider, (_, _) {});
      container.listen(stablePositionProvider, (_, _) {});
      container.listen(horizonProfileProvider, (_, _) {});
      container.listen(windDataProvider, (_, _) {});
      container.listen(rawSensorProvider, (_, _) {});
      container.listen(selectedAltitudeProvider, (_, _) {});
      return container;
    }

    // -- GPS debounce tests --

    test('GPS change >100m triggers horizon and wind refetch', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Emit initial position + sensor
      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      // First position should trigger horizon and wind fetch
      expect(horizonProvider.calls, hasLength(1));
      expect(windDataSource.calls, hasLength(1));

      // Move >100m (~0.001 degrees at this latitude is ~111m)
      sensorService.emitPosition(_makePosition(37.776, -122.4194));
      await _pumpProviders();

      // Should trigger new fetch because position changed >100m
      expect(horizonProvider.calls, hasLength(2));
      expect(windDataSource.calls, hasLength(2));
    });

    test('GPS change <100m does NOT trigger refetch', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(horizonProvider.calls, hasLength(1));
      expect(windDataSource.calls, hasLength(1));

      // Move <100m (~0.0001 degrees is ~11m)
      sensorService.emitPosition(_makePosition(37.77495, -122.41945));
      await _pumpProviders();

      // Should NOT trigger new fetch (within debounce threshold)
      expect(horizonProvider.calls, hasLength(1));
      expect(windDataSource.calls, hasLength(1));
    });

    // -- Altitude change tests --

    test('altitude change triggers wind refetch', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(windDataSource.calls, hasLength(1));
      expect(windDataSource.calls.last, contains('surface'));

      // Change altitude
      container.read(selectedAltitudeProvider.notifier).select(AltitudeLevel.jetStream);
      await _pumpProviders();

      // Wind should be refetched for the new altitude
      expect(windDataSource.calls, hasLength(2));
      expect(windDataSource.calls.last, contains('jetStream'));
    });

    test('altitude change does NOT trigger horizon refetch', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(horizonProvider.calls, hasLength(1));

      // Change altitude
      container.read(selectedAltitudeProvider.notifier).select(AltitudeLevel.midLevel);
      await _pumpProviders();

      // Horizon should NOT be refetched (doesn't depend on altitude)
      expect(horizonProvider.calls, hasLength(1));
    });

    // -- SceneState composition tests --

    test('SceneState is non-null when all critical data is present', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Initially null (no data yet)
      expect(container.read(sceneStateProvider), isNull);

      sensorService.emitSensor(_makeSensor(heading: 90.0, pitch: 15.0));
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      final scene = container.read(sceneStateProvider);
      expect(scene, isNotNull);
      expect(scene!.position.latitude, closeTo(37.7749, 0.001));
      expect(scene.wind.speed, closeTo(5.0, 0.01)); // sqrt(3^2 + 4^2)
      expect(scene.selectedAltitude, AltitudeLevel.surface);
    });

    test('SceneState is null when position is missing', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Emit sensor but NOT position
      sensorService.emitSensor(_makeSensor());
      await _pumpProviders();

      expect(container.read(sceneStateProvider), isNull);
    });

    test('SceneState is null when sensor data is missing', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Emit position but NOT sensor
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(container.read(sceneStateProvider), isNull);
    });

    test('SceneState uses flat horizon fallback', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      final scene = container.read(sceneStateProvider);
      expect(scene, isNotNull);
      // Horizon is flat (all elevations = 0) from MockHorizonProvider
      expect(scene!.horizon.getElevationAtBearing(0), 0.0);
      expect(scene.horizon.getElevationAtBearing(180), 0.0);
    });

    test('SceneState uses fullSky for skyMask fallback', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      final scene = container.read(sceneStateProvider);
      expect(scene, isNotNull);
      expect(scene!.skyMask.skyFraction, 1.0);
    });

    // -- Lifecycle tests (using AppLifecycleObserver directly) --

    test('lifecycle: pause causes sensor service pause', () {
      final observer = AppLifecycleObserver(sensorService: sensorService);
      addTearDown(observer.dispose);

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(sensorService.calls, contains('pause'));
    });

    test('lifecycle: resume after pause causes sensor service resume', () {
      final observer = AppLifecycleObserver(sensorService: sensorService);
      addTearDown(observer.dispose);

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(sensorService.calls, contains('pause'));
      expect(sensorService.calls, contains('resume'));
    });

    test('lifecycle: full cycle (pause -> resume -> pause -> resume)', () {
      final observer = AppLifecycleObserver(sensorService: sensorService);
      addTearDown(observer.dispose);

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(sensorService.calls, ['pause', 'resume', 'pause', 'resume']);
    });

    // -- Selected altitude state tests --

    test('selectedAltitude defaults to surface', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedAltitudeProvider), AltitudeLevel.surface);
    });

    test('selectedAltitude can be changed via notifier', () {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(selectedAltitudeProvider.notifier).select(AltitudeLevel.jetStream);
      expect(container.read(selectedAltitudeProvider), AltitudeLevel.jetStream);
    });

    // -- Wind data receives correct altitude --

    test('wind data request includes the selected altitude', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Set altitude before emitting position
      container.read(selectedAltitudeProvider.notifier).select(AltitudeLevel.midLevel);

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(windDataSource.calls.last, contains('midLevel'));
    });

    // -- SceneState reflects altitude change --

    test('SceneState reflects altitude change after wind refetch', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Configure wind source to return altitude-specific data
      windDataSource.resultFn = (position, altitude) => WindData(
            uComponent: altitude == AltitudeLevel.jetStream ? 30.0 : 3.0,
            vComponent: altitude == AltitudeLevel.jetStream ? 40.0 : 4.0,
            altitude: altitude,
            timestamp: DateTime.now(),
          );

      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      final scene1 = container.read(sceneStateProvider);
      expect(scene1, isNotNull);
      expect(scene1!.wind.speed, closeTo(5.0, 0.01)); // sqrt(9+16)

      // Change altitude
      container.read(selectedAltitudeProvider.notifier).select(AltitudeLevel.jetStream);
      await _pumpProviders();

      final scene2 = container.read(sceneStateProvider);
      expect(scene2, isNotNull);
      expect(scene2!.wind.speed, closeTo(50.0, 0.01)); // sqrt(900+1600)
      expect(scene2.selectedAltitude, AltitudeLevel.jetStream);
    });
  });
}
