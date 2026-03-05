import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/altitude_level.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/location_override_provider.dart';
import 'package:wind_lens/features/splash/splash_screen.dart';

void main() {
  /// Builds a test widget with providers overridden to simulate various
  /// loading states. All three providers default to "not yet loaded".
  Widget buildTestWidget({
    PositionData? position,
    AsyncValue<WindData>? wind,
    AsyncValue<HorizonProfile>? horizon,
  }) {
    return ProviderScope(
      overrides: [
        effectivePositionProvider.overrideWithValue(position),
        windDataProvider.overrideWith(
          (ref) => wind != null && wind.hasValue
              ? Future.value(wind.value)
              : Future.error(StateError('No GPS fix yet')),
        ),
        horizonProfileProvider.overrideWith(
          (ref) => horizon != null && horizon.hasValue
              ? Future.value(horizon.value)
              : Future.error(StateError('No GPS fix yet')),
        ),
      ],
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    );
  }

  /// Drains all pending timers so the test framework does not complain.
  Future<void> drainTimers(WidgetTester tester) async {
    // Advance past both the 2s min-time and 60s error timers.
    await tester.pump(const Duration(seconds: 61));
  }

  group('SplashScreen', () {
    testWidgets('renders "ShyftLens" logo text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('ShyftLens'), findsOneWidget);

      await drainTimers(tester);
    });

    testWidgets('renders progress bar widget', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await drainTimers(tester);
    });

    testWidgets('shows "Acquiring GPS..." when no data loaded',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Acquiring GPS...'), findsOneWidget);

      await drainTimers(tester);
    });

    testWidgets('shows "Loading wind data..." when GPS loaded',
        (tester) async {
      final testPosition = PositionData(
        latitude: 40.0,
        longitude: -96.0,
        altitude: 0.0,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(buildTestWidget(
        position: testPosition,
      ));
      await tester.pump();

      expect(find.text('Loading wind data...'), findsOneWidget);

      await drainTimers(tester);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.black);

      await drainTimers(tester);
    });

    testWidgets('logo uses Bebas Neue font', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final text = tester.widget<Text>(find.text('ShyftLens'));
      expect(text.style?.fontFamily, 'Bebas Neue');

      await drainTimers(tester);
    });

    testWidgets('shows error message after 60 seconds without data',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Initially no error
      expect(find.text('Unable to load data \u2014 check your connection'),
          findsNothing);
      expect(find.text('RETRY'), findsNothing);

      // Advance past the 60-second error timer
      await tester.pump(const Duration(seconds: 61));

      // Error state should now be visible
      expect(find.text('Unable to load data \u2014 check your connection'),
          findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      // Progress bar should NOT be visible in error state
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('retry button clears error and restarts timer',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Trigger error
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('RETRY'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('RETRY'));
      await tester.pump();

      // Error should be cleared, progress bar back
      expect(find.text('Unable to load data \u2014 check your connection'),
          findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Drain the new 60s timer
      await drainTimers(tester);
    });

    testWidgets('does not navigate to home on timeout (strict gating)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Advance well past old 15s timeout
      await tester.pump(const Duration(seconds: 20));

      // Should still be on splash screen (no silent timeout entry)
      expect(find.text('ShyftLens'), findsOneWidget);

      // Drain remaining timers
      await tester.pump(const Duration(seconds: 41));
    });
  });
}
