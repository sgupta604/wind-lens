import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/providers/location_override_provider.dart';
import 'package:wind_lens/core/widgets/location_indicator_chip.dart';

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

void main() {
  group('LocationIndicatorChip (shared path)', () {
    testWidgets('shows "GPS" label when no override is set', (tester) async {
      // No override; effectivePosition returns GPS value
      final gpsPosition = _makePosition(37.7749, -122.4194);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePositionProvider.overrideWithValue(gpsPosition),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LocationIndicatorChip()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GPS'), findsOneWidget);
      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });

    testWidgets('shows coordinates when override is set', (tester) async {
      final overridePosition = _makePosition(40.7128, -74.0060);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override effectivePosition to derive from locationOverride,
            // falling back to null (no GPS).
            effectivePositionProvider.overrideWith((ref) {
              return ref.watch(locationOverrideProvider);
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return const LocationIndicatorChip();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Set the override
      container.read(locationOverrideProvider.notifier).set(overridePosition);
      await tester.pump();

      expect(find.text('40.7128, -74.0060'), findsOneWidget);
    });

    testWidgets('updates reactively when override changes', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // effectivePosition derives from locationOverride, so it
            // reacts when override changes. No GPS fallback in this test.
            effectivePositionProvider.overrideWith((ref) {
              return ref.watch(locationOverrideProvider);
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return const LocationIndicatorChip();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially shows GPS (no override)
      expect(find.text('GPS'), findsOneWidget);

      // Set an override
      final overridePosition = _makePosition(51.5074, -0.1278);
      container.read(locationOverrideProvider.notifier).set(overridePosition);
      await tester.pump();

      // Should now show coordinates
      expect(find.text('51.5074, -0.1278'), findsOneWidget);

      // Clear the override
      container.read(locationOverrideProvider.notifier).clear();
      await tester.pump();

      // Should show GPS again
      expect(find.text('GPS'), findsOneWidget);
    });
  });
}
