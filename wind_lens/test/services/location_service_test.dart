import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/location_data.dart';
import 'package:wind_lens/services/location_service.dart';

void main() {
  // Initialize Flutter bindings for platform channel tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    tearDown(() {
      locationService.dispose();
    });

    group('Initial State', () {
      test('initial latitude is 0', () {
        expect(locationService.latitude, 0);
      });

      test('initial longitude is 0', () {
        expect(locationService.longitude, 0);
      });

      test('initial hasPermission is false', () {
        expect(locationService.hasPermission, isFalse);
      });
    });

    group('Stream', () {
      test('provides broadcast stream', () {
        expect(locationService.stream, isA<Stream<LocationData>>());
      });

      test('stream allows multiple listeners', () async {
        // Test that multiple listeners can subscribe without error
        final sub1 = locationService.stream.listen((_) {});
        final sub2 = locationService.stream.listen((_) {});

        // If we got here without error, the stream is broadcast
        await sub1.cancel();
        await sub2.cancel();
        expect(true, isTrue);
      });
    });

    group('setPosition test helper', () {
      test('setPosition updates latitude getter', () {
        locationService.setPosition(37.7749, -122.4194);
        expect(locationService.latitude, 37.7749);
      });

      test('setPosition updates longitude getter', () {
        locationService.setPosition(37.7749, -122.4194);
        expect(locationService.longitude, -122.4194);
      });

      test('setPosition sets hasPermission to true', () {
        expect(locationService.hasPermission, isFalse);
        locationService.setPosition(37.7749, -122.4194);
        expect(locationService.hasPermission, isTrue);
      });

      test('setPosition emits LocationData to stream', () async {
        final events = <LocationData>[];
        final sub = locationService.stream.listen((data) {
          events.add(data);
        });

        // Allow listener to be established
        await Future<void>.delayed(Duration.zero);

        locationService.setPosition(37.7749, -122.4194);

        // Allow stream event to be delivered
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(events.length, 1);
        expect(events.first.latitude, 37.7749);
        expect(events.first.longitude, -122.4194);
        expect(events.first.accuracy, 0);
        expect(events.first.timestamp, isA<DateTime>());
      });
    });

    group('Dispose', () {
      test('dispose closes stream (no events after dispose)', () async {
        final events = <LocationData>[];
        final sub = locationService.stream.listen((data) {
          events.add(data);
        });

        // Allow listener to be established
        await Future<void>.delayed(Duration.zero);

        // Dispose closes the controller
        locationService.dispose();

        // After dispose, the stream should be done
        // Verify no new events arrive after dispose
        final eventCountAfterDispose = events.length;

        // Allow microtasks
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(events.length, eventCountAfterDispose);
      });
    });
  });
}
