import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/location_override_provider.dart';
import 'package:wind_lens/core/providers/scene_provider.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/core/providers/service_providers.dart';
import 'package:wind_lens/core/services/horizon_provider.dart' as core;
import 'package:wind_lens/core/services/sensor_service.dart';
import 'package:wind_lens/core/services/wind_data_source.dart';
import 'package:wind_lens/models/altitude_level.dart';

// ---------------------------------------------------------------------------
// Test doubles (same pattern as provider_graph_test.dart)
// ---------------------------------------------------------------------------

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

class ControllableWindDataSource implements WindDataSource {
  final List<String> calls = [];

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) async {
    calls.add('getWind(${position.latitude}, ${position.longitude})');
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
// Helpers
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

Future<void> _pumpProviders() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('effectivePosition provider graph propagation', () {
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

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sensorServiceProvider.overrideWithValue(sensorService),
          windDataSourceProvider.overrideWithValue(windDataSource),
          horizonProviderServiceProvider.overrideWithValue(horizonProvider),
        ],
      );
      // Keep providers alive
      container.listen(sceneStateProvider, (_, _) {});
      container.listen(stablePositionProvider, (_, _) {});
      container.listen(effectivePositionProvider, (_, _) {});
      container.listen(horizonProfileProvider, (_, _) {});
      container.listen(windDataProvider, (_, _) {});
      container.listen(rawSensorProvider, (_, _) {});
      container.listen(locationOverrideProvider, (_, _) {});
      return container;
    }

    test('override propagates to windDataProvider', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Start with GPS position
      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(windDataSource.calls, hasLength(1));
      expect(windDataSource.calls.last, contains('37.7749'));

      // Set override to London
      final london = _makePosition(51.5074, -0.1278);
      container.read(locationOverrideProvider.notifier).set(london);
      await _pumpProviders();

      // Wind should be refetched for London coordinates
      expect(windDataSource.calls, hasLength(2));
      expect(windDataSource.calls.last, contains('51.5074'));
    });

    test('override propagates to horizonProfileProvider', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Start with GPS position
      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(horizonProvider.calls, hasLength(1));
      expect(horizonProvider.calls.last, contains('37.7749'));

      // Set override to London
      final london = _makePosition(51.5074, -0.1278);
      container.read(locationOverrideProvider.notifier).set(london);
      await _pumpProviders();

      // Horizon should be refetched for London coordinates
      expect(horizonProvider.calls, hasLength(2));
      expect(horizonProvider.calls.last, contains('51.5074'));
    });

    test('override does NOT affect sensorNotifiers', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      // Also listen to sensorNotifiers so it stays alive
      container.listen(sensorNotifiersProvider, (_, _) {});

      // Emit sensor and GPS data
      sensorService.emitSensor(_makeSensor(heading: 90.0, pitch: 15.0));
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      final notifiers = container.read(sensorNotifiersProvider);
      expect(notifiers.heading.value, 90.0);
      expect(notifiers.pitch.value, 15.0);

      // Set override -- should NOT affect sensors
      final london = _makePosition(51.5074, -0.1278);
      container.read(locationOverrideProvider.notifier).set(london);
      await _pumpProviders();

      // Heading and pitch are still from the device sensor, not changed
      expect(notifiers.heading.value, 90.0);
      expect(notifiers.pitch.value, 15.0);
    });

    test('GPS chain stays alive during override (no disposal)', () async {
      // Regression test: previously effectivePositionProvider used a
      // conditional watch (if override != null, return early without
      // watching stablePositionProvider). AutoDispose would tear down
      // the GPS chain while an override was set, so clearing the
      // override returned null instead of the GPS position.
      final container = ProviderContainer(
        overrides: [
          sensorServiceProvider.overrideWithValue(sensorService),
          windDataSourceProvider.overrideWithValue(windDataSource),
          horizonProviderServiceProvider.overrideWithValue(horizonProvider),
        ],
      );
      addTearDown(container.dispose);
      // Only listen to effectivePosition -- NOT stablePosition directly.
      // This is the realistic scenario: downstream providers watch
      // effectivePosition, not stablePosition.
      container.listen(effectivePositionProvider, (_, _) {});
      container.listen(locationOverrideProvider, (_, _) {});

      // Emit GPS
      final gps = _makePosition(37.7749, -122.4194);
      sensorService.emitPosition(gps);
      await _pumpProviders();
      expect(container.read(effectivePositionProvider), equals(gps));

      // Set override
      final london = _makePosition(51.5074, -0.1278);
      container.read(locationOverrideProvider.notifier).set(london);
      await _pumpProviders();
      expect(container.read(effectivePositionProvider), equals(london));

      // Clear override -- GPS must still be available
      container.read(locationOverrideProvider.notifier).clear();
      await _pumpProviders();
      expect(container.read(effectivePositionProvider), equals(gps));
    });

    test('clear() reverts data providers to GPS position', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Start with GPS
      sensorService.emitSensor(_makeSensor());
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      expect(windDataSource.calls, hasLength(1));
      expect(windDataSource.calls.last, contains('37.7749'));

      // Set override to London
      final london = _makePosition(51.5074, -0.1278);
      container.read(locationOverrideProvider.notifier).set(london);
      await _pumpProviders();

      expect(windDataSource.calls, hasLength(2));
      expect(windDataSource.calls.last, contains('51.5074'));

      // Clear override -- should revert to GPS position
      container.read(locationOverrideProvider.notifier).clear();
      await _pumpProviders();

      expect(windDataSource.calls, hasLength(3));
      expect(windDataSource.calls.last, contains('37.7749'));
    });
  });
}
