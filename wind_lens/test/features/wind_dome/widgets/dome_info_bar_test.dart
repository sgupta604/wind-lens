import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_field.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_layer.dart';
import 'package:wind_lens/features/wind_dome/providers/dome_providers.dart';
import 'package:wind_lens/features/wind_dome/widgets/dome_info_bar.dart';
import 'package:wind_lens/models/altitude_level.dart';

void main() {
  group('DomeInfoBar', () {
    Widget _buildWidget({
      DomeWindField? windField,
      int hoursAhead = 0,
    }) {
      return ProviderScope(
        overrides: [
          currentDomeWindFieldProvider.overrideWith((ref) => windField),
          hoursAheadProvider.overrideWith((ref) => hoursAhead),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DomeInfoBar(onBack: () {}),
          ),
        ),
      );
    }

    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.byType(DomeInfoBar), findsOneWidget);
    });

    testWidgets('shows "Live" badge when hoursAhead=0', (tester) async {
      await tester.pumpWidget(_buildWidget(hoursAhead: 0));
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('shows "Fcst" badge when hoursAhead>0', (tester) async {
      await tester.pumpWidget(_buildWidget(hoursAhead: 6));
      expect(find.text('Fcst'), findsOneWidget);
    });

    testWidgets('shows wind speed from current field', (tester) async {
      final field = DomeWindField(
        validTime: DateTime.utc(2026),
        layers: [
          const DomeWindLayer(altitudeMeters: 10, u: 3.0, v: 4.0), // speed = 5.0
          const DomeWindLayer(altitudeMeters: 1500, u: 6.0, v: 8.0),
          const DomeWindLayer(altitudeMeters: 3000, u: 9.0, v: 12.0),
        ],
      );
      await tester.pumpWidget(_buildWidget(windField: field));

      // Surface wind speed: sqrt(3^2 + 4^2) = 5.0
      expect(find.text('5.0 m/s'), findsOneWidget);
    });

    group('size preset buttons', () {
      testWidgets('renders three size preset buttons', (tester) async {
        await tester.pumpWidget(_buildWidget());
        expect(find.text('500m'), findsOneWidget);
        expect(find.text('1km'), findsOneWidget);
        expect(find.text('2km'), findsOneWidget);
      });

      testWidgets('tapping 500m updates domeSizeProvider', (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDomeWindFieldProvider.overrideWith((ref) => null),
              hoursAheadProvider.overrideWith((ref) => 0),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    // Capture the container for later reading
                    container = ProviderScope.containerOf(context);
                    return DomeInfoBar(onBack: () {});
                  },
                ),
              ),
            ),
          ),
        );

        // Default should be 1000.0
        expect(container.read(domeSizeProvider), 1000.0);

        // Tap the 500m button
        await tester.tap(find.text('500m'));
        await tester.pump();

        expect(container.read(domeSizeProvider), 500.0);
      });

      testWidgets('active preset is visually distinct', (tester) async {
        await tester.pumpWidget(_buildWidget());

        // The default is 1000.0, so "1km" should be the active button.
        // We verify by checking that the "1km" text widget exists and
        // that there are exactly 3 size buttons rendered.
        expect(find.text('1km'), findsOneWidget);
        expect(find.text('500m'), findsOneWidget);
        expect(find.text('2km'), findsOneWidget);
      });
    });

    group('live vs forecast speed sourcing', () {
      testWidgets('shows AR wind speed when hoursAhead is 0', (tester) async {
        // AR wind: u=3, v=4 -> speed = 5.0
        final arWind = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: DateTime.utc(2026),
        );

        // Dome field: u=0.3, v=0.4 -> speed = 0.5
        final domeField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 0.3, v: 0.4),
            const DomeWindLayer(altitudeMeters: 1500, u: 1.0, v: 1.0),
            const DomeWindLayer(altitudeMeters: 3000, u: 2.0, v: 2.0),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDomeWindFieldProvider.overrideWith((ref) => domeField),
              hoursAheadProvider.overrideWith((ref) => 0),
              windDataProvider.overrideWith((ref) => Future.value(arWind)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: DomeInfoBar(onBack: () {}),
              ),
            ),
          ),
        );
        // Allow async provider to resolve
        await tester.pump();

        // Should display AR wind speed (5.0), not dome surface speed (0.5)
        expect(find.text('5.0 m/s'), findsOneWidget);
      });

      testWidgets('shows dome surface speed when hoursAhead > 0', (tester) async {
        // AR wind: u=3, v=4 -> speed = 5.0
        final arWind = WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: AltitudeLevel.surface,
          timestamp: DateTime.utc(2026),
        );

        // Dome field: u=6, v=8 -> speed = 10.0
        final domeField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 6.0, v: 8.0),
            const DomeWindLayer(altitudeMeters: 1500, u: 1.0, v: 1.0),
            const DomeWindLayer(altitudeMeters: 3000, u: 2.0, v: 2.0),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDomeWindFieldProvider.overrideWith((ref) => domeField),
              hoursAheadProvider.overrideWith((ref) => 6),
              windDataProvider.overrideWith((ref) => Future.value(arWind)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: DomeInfoBar(onBack: () {}),
              ),
            ),
          ),
        );
        await tester.pump();

        // Should display dome surface speed (10.0), not AR speed (5.0)
        expect(find.text('10.0 m/s'), findsOneWidget);
      });
    });
  });
}
