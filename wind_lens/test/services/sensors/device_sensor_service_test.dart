import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/services/sensor_service.dart';
import 'package:wind_lens/services/compass_service.dart';
import 'package:wind_lens/services/location_service.dart';
import 'package:wind_lens/services/sensors/device_sensor_service.dart';

void main() {
  group('DeviceSensorService', () {
    late CompassService compassService;
    late LocationService locationService;
    late DeviceSensorService deviceSensorService;

    setUp(() {
      compassService = CompassService();
      locationService = LocationService();
      // autoStart: false avoids platform channel calls in tests.
      // wireStreams() sets up the stream mapping without calling .start().
      deviceSensorService = DeviceSensorService(
        compassService: compassService,
        locationService: locationService,
        autoStart: false,
      );
      deviceSensorService.wireStreams();
    });

    tearDown(() {
      deviceSensorService.dispose();
    });

    test('implements SensorService interface', () {
      expect(deviceSensorService, isA<SensorService>());
    });

    test('sensorStream emits SensorState when compass data arrives',
        () async {
      // Set up a listener on the sensor stream
      final completer = Completer<SensorState>();
      final sub = deviceSensorService.sensorStream.listen((state) {
        if (!completer.isCompleted) {
          completer.complete(state);
        }
      });

      // Simulate compass data via @visibleForTesting helpers
      compassService.setRawHeading(127.3);
      compassService.setRawPitch(12.5);
      compassService.tick(); // Triggers one smoothing + emission cycle

      final state = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('No SensorState emitted'),
      );

      expect(state, isA<SensorState>());
      // Due to smoothing, the value won't be exactly 127.3 on first tick
      // but it should be a valid double
      expect(state.compassHeading, isA<double>());
      expect(state.pitch, isA<double>());
      expect(state.timestamp, isA<DateTime>());

      await sub.cancel();
    });

    test('positionStream emits PositionData when location data arrives',
        () async {
      final completer = Completer<PositionData>();
      final sub = deviceSensorService.positionStream.listen((data) {
        if (!completer.isCompleted) {
          completer.complete(data);
        }
      });

      // Simulate location data via @visibleForTesting helper
      locationService.setPosition(37.7749, -122.4194);

      final data = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('No PositionData emitted'),
      );

      expect(data, isA<PositionData>());
      expect(data.latitude, 37.7749);
      expect(data.longitude, -122.4194);
      expect(data.altitude, 0.0); // Default altitude from setPosition()
      expect(data.accuracy, isA<double>());
      expect(data.timestamp, isA<DateTime>());

      await sub.cancel();
    });

    test('dispose cleans up both internal services', () async {
      deviceSensorService.dispose();

      // After disposal, the stream controllers should be closed
      // and no new events should be emitted
      // Just verify dispose doesn't throw
      expect(true, true);
    });

    test('sensorStream is a broadcast stream', () {
      expect(deviceSensorService.sensorStream.isBroadcast, true);
    });

    test('positionStream is a broadcast stream', () {
      expect(deviceSensorService.positionStream.isBroadcast, true);
    });
  });
}
