import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/providers/scene_provider.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/features/ar_view/ar_view_screen.dart';
import 'package:wind_lens/features/home/home_screen.dart';

void main() {
  late SensorNotifiers testNotifiers;

  setUp(() {
    testNotifiers = SensorNotifiers();
  });

  tearDown(() {
    testNotifiers.dispose();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        sceneStateProvider.overrideWithValue(null),
        sensorNotifiersProvider.overrideWithValue(testNotifiers),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('shows "ShyftLens" logo text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('ShyftLens'), findsOneWidget);
    });

    testWidgets('shows "ATMOSPHERIC AR" subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('ATMOSPHERIC AR'), findsOneWidget);
    });

    testWidgets('shows "LIVE AR" button text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('LIVE AR'), findsOneWidget);
    });

    testWidgets('Live AR button navigates to ARViewScreen on tap',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('LIVE AR'));
      // Use pump() not pumpAndSettle() -- animation controllers never settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ARViewScreen), findsOneWidget);
    });

    testWidgets('layer toggle text visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('PARTICLES'), findsOneWidget);
      expect(find.text('TERRAIN'), findsOneWidget);
    });

    testWidgets('altitude rail shows "Surface" label', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Surface'), findsOneWidget);
    });
  });
}
