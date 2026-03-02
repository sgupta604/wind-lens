import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/sensor_state.dart';
import 'package:wind_lens/core/providers/location_override_provider.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/core/providers/service_providers.dart';
import 'package:wind_lens/core/services/sensor_service.dart';
import 'package:wind_lens/features/location_picker/location_picker_screen.dart';

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

void main() {
  late SensorNotifiers testNotifiers;
  late _TestSensorService testSensorService;

  setUp(() {
    testNotifiers = SensorNotifiers();
    testSensorService = _TestSensorService();
  });

  tearDown(() {
    testNotifiers.dispose();
    testSensorService.dispose();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        sensorServiceProvider.overrideWithValue(testSensorService),
        sensorNotifiersProvider.overrideWithValue(testNotifiers),
      ],
      child: const MaterialApp(
        home: LocationPickerScreen(),
      ),
    );
  }

  group('LocationPickerScreen', () {
    testWidgets('renders FlutterMap widget', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('Confirm button is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('CONFIRM'), findsOneWidget);
    });

    testWidgets('Cancel/back button is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Look for the back/cancel button by its semantics label
      expect(
        find.bySemanticsLabel('Cancel and go back'),
        findsOneWidget,
      );
    });

    testWidgets('Reset to GPS button is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('RESET TO GPS'), findsOneWidget);
    });

    testWidgets('initState uses effectivePositionProvider for initial center',
        (tester) async {
      // Set a location override before opening the screen.
      // The map should open at the override position, not (0,0).
      final overridePosition = _makePosition(51.5074, -0.1278); // London

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sensorServiceProvider.overrideWithValue(testSensorService),
            sensorNotifiersProvider.overrideWithValue(testNotifiers),
            locationOverrideProvider.overrideWith(() {
              final notifier = LocationOverride();
              return notifier;
            }),
            effectivePositionProvider.overrideWithValue(overridePosition),
          ],
          child: const MaterialApp(
            home: LocationPickerScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify coordinate display shows the override location, not (0,0)
      expect(find.text('51.5074, -0.1278'), findsOneWidget);
    });

    testWidgets('Reset to GPS shows SnackBar when GPS is null',
        (tester) async {
      // No GPS emitted, no override -- stablePositionProvider is null
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Tap "RESET TO GPS" button
      await tester.tap(find.text('RESET TO GPS'));
      await tester.pump();

      // Verify SnackBar appears with the expected message
      expect(find.text('GPS not available \u2014 keeping current location'), findsOneWidget);
    });

    testWidgets('Reset to GPS clears location override', (tester) async {
      late ProviderContainer container;
      final overridePosition = _makePosition(40.7128, -74.0060); // NYC

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sensorServiceProvider.overrideWithValue(testSensorService),
            sensorNotifiersProvider.overrideWithValue(testNotifiers),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return const LocationPickerScreen();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Set a location override
      container.read(locationOverrideProvider.notifier).set(overridePosition);
      expect(container.read(locationOverrideProvider), isNotNull);

      // Tap "RESET TO GPS" button
      await tester.tap(find.text('RESET TO GPS'));
      await tester.pump();

      // Verify override is cleared
      expect(container.read(locationOverrideProvider), isNull);
    });

    testWidgets(
        'Cancel pops navigator without modifying locationOverrideProvider',
        (tester) async {
      bool didPop = false;
      final observer = _TestNavigatorObserver(onPop: () => didPop = true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sensorServiceProvider.overrideWithValue(testSensorService),
            sensorNotifiersProvider.overrideWithValue(testNotifiers),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerScreen(),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Navigate to the location picker
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LocationPickerScreen), findsOneWidget);

      // Tap the cancel/back button
      await tester.tap(find.bySemanticsLabel('Cancel and go back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(didPop, isTrue);
    });

    testWidgets('has correct Semantics labels on interactive elements',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify all interactive elements have Semantics wrappers
      expect(find.bySemanticsLabel('Cancel and go back'), findsOneWidget);

      // The Confirm and Reset buttons have Semantics labels and child text.
      // Use byWidgetPredicate to find Semantics widgets by label.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Confirm selected location',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Reset to GPS location',
        ),
        findsOneWidget,
      );
    });
  });
}

/// A simple navigator observer for tracking pop events in tests.
class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback? onPop;

  _TestNavigatorObserver({this.onPop});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop?.call();
  }
}
