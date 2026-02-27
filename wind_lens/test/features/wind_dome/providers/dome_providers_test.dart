import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_wind_field.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_layer.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_profile.dart';
import 'package:wind_lens/features/wind_dome/providers/dome_providers.dart';

void main() {
  group('Dome Providers', () {
    group('hoursAheadProvider', () {
      test('defaults to 0', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(hoursAheadProvider), 0);
      });

      test('setter updates state', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(hoursAheadProvider.notifier).state = 12;
        expect(container.read(hoursAheadProvider), 12);
      });
    });

    group('domeSizeProvider', () {
      test('defaults to 1000.0', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(domeSizeProvider), 1000.0);
      });

      test('can be set to 500.0', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(domeSizeProvider.notifier).state = 500.0;
        expect(container.read(domeSizeProvider), 500.0);
      });

      test('can be set to 2000.0', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(domeSizeProvider.notifier).state = 2000.0;
        expect(container.read(domeSizeProvider), 2000.0);
      });
    });

    group('currentDomeWindFieldProvider', () {
      DomeWindProfile _makeProfile(int hours) {
        final baseTime = DateTime.utc(2026, 2, 27, 12);
        return DomeWindProfile(
          hourly: List.generate(
            hours,
            (i) => DomeWindField(
              validTime: baseTime.add(Duration(hours: i)),
              layers: [
                DomeWindLayer(
                    altitudeMeters: 10, u: i * 1.0, v: i * 0.5),
                DomeWindLayer(
                    altitudeMeters: 1500, u: i * 2.0, v: i * 1.0),
                DomeWindLayer(
                    altitudeMeters: 3000, u: i * 3.0, v: i * 1.5),
              ],
            ),
          ),
          fetchedAt: baseTime,
          lat: 37.77,
          lng: -122.42,
        );
      }

      test('returns null when profile is null', () {
        final container = ProviderContainer(
          overrides: [
            domeWindProfileProvider
                .overrideWith((ref) => Future.value(null)),
          ],
        );
        addTearDown(container.dispose);

        // Read the provider to trigger async resolution
        container.read(domeWindProfileProvider);

        // Give it a moment to settle
        expect(container.read(currentDomeWindFieldProvider), isNull);
      });

      test('selects correct hour from profile', () async {
        final profile = _makeProfile(72);
        final container = ProviderContainer(
          overrides: [
            domeWindProfileProvider
                .overrideWith((ref) => Future.value(profile)),
          ],
        );
        addTearDown(container.dispose);

        // Wait for the future to resolve
        await container.read(domeWindProfileProvider.future);

        // Set hoursAhead to 10
        container.read(hoursAheadProvider.notifier).state = 10;

        final field = container.read(currentDomeWindFieldProvider);
        expect(field, isNotNull);
        // Hour 10 should have u=10.0 at surface
        expect(field!.layers[0].u, 10.0);
      });

      test('updates when hoursAhead changes', () async {
        final profile = _makeProfile(72);
        final container = ProviderContainer(
          overrides: [
            domeWindProfileProvider
                .overrideWith((ref) => Future.value(profile)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(domeWindProfileProvider.future);

        container.read(hoursAheadProvider.notifier).state = 5;
        final field5 = container.read(currentDomeWindFieldProvider);
        expect(field5!.layers[0].u, 5.0);

        container.read(hoursAheadProvider.notifier).state = 20;
        final field20 = container.read(currentDomeWindFieldProvider);
        expect(field20!.layers[0].u, 20.0);
      });
    });
  });
}
