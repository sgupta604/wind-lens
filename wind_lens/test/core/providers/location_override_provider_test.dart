import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/providers/location_override_provider.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/core/providers/service_providers.dart';
import 'package:wind_lens/core/services/sensor_service.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _TestSensorService implements SensorService {
  final _sensorController = StreamController<SensorState>.broadcast();
  final _positionController = StreamController<PositionData>.broadcast();

  @override
  Stream<SensorState> get sensorStream => _sensorController.stream;

  @override
  Stream<PositionData> get positionStream => _positionController.stream;

  void emitPosition(PositionData position) => _positionController.add(position);

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  void dispose() {
    _sensorController.close();
    _positionController.close();
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
      timestamp: DateTime(2026, 1, 1),
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
  group('locationOverrideProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(locationOverrideProvider), isNull);
    });

    test('set() stores a PositionData', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final position = _makePosition(40.7128, -74.0060);
      container.read(locationOverrideProvider.notifier).set(position);

      expect(container.read(locationOverrideProvider), equals(position));
    });

    test('clear() returns to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(locationOverrideProvider.notifier)
          .set(_makePosition(40.7128, -74.0060));
      container.read(locationOverrideProvider.notifier).clear();

      expect(container.read(locationOverrideProvider), isNull);
    });

    test('set() then set() overwrites previous value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = _makePosition(40.7128, -74.0060);
      final second = _makePosition(51.5074, -0.1278);

      container.read(locationOverrideProvider.notifier).set(first);
      container.read(locationOverrideProvider.notifier).set(second);

      expect(container.read(locationOverrideProvider), equals(second));
    });
  });

  group('effectivePositionProvider', () {
    late _TestSensorService sensorService;

    setUp(() {
      sensorService = _TestSensorService();
    });

    tearDown(() {
      sensorService.dispose();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sensorServiceProvider.overrideWithValue(sensorService),
        ],
      );
      // Keep providers alive
      container.listen(effectivePositionProvider, (_, _) {});
      container.listen(stablePositionProvider, (_, _) {});
      container.listen(locationOverrideProvider, (_, _) {});
      return container;
    }

    test('returns stablePosition when no override', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final gpsPosition = _makePosition(37.7749, -122.4194);
      sensorService.emitPosition(gpsPosition);
      await _pumpProviders();

      expect(container.read(effectivePositionProvider), equals(gpsPosition));
    });

    test('returns override when set', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Emit GPS first
      sensorService.emitPosition(_makePosition(37.7749, -122.4194));
      await _pumpProviders();

      // Set override
      final overridePosition = _makePosition(51.5074, -0.1278);
      container
          .read(locationOverrideProvider.notifier)
          .set(overridePosition);

      expect(
          container.read(effectivePositionProvider), equals(overridePosition));
    });

    test('returns null when both stablePosition and override are null',
        () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // No GPS emitted, no override set
      expect(container.read(effectivePositionProvider), isNull);
    });

    test('updates reactively when override changes', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final gpsPosition = _makePosition(37.7749, -122.4194);
      sensorService.emitPosition(gpsPosition);
      await _pumpProviders();

      // Initially: GPS position
      expect(container.read(effectivePositionProvider), equals(gpsPosition));

      // Set override
      final overridePosition = _makePosition(51.5074, -0.1278);
      container
          .read(locationOverrideProvider.notifier)
          .set(overridePosition);
      expect(
          container.read(effectivePositionProvider), equals(overridePosition));

      // Clear override: back to GPS
      container.read(locationOverrideProvider.notifier).clear();
      expect(container.read(effectivePositionProvider), equals(gpsPosition));
    });
  });
}
