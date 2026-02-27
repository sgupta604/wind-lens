import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/providers/dome_providers.dart';
import 'package:wind_lens/features/wind_dome/widgets/dome_forecast_slider.dart';

void main() {
  group('DomeForecastSlider', () {
    Widget _buildWidget({int initialHoursAhead = 0}) {
      return ProviderScope(
        overrides: [
          hoursAheadProvider.overrideWith((ref) => initialHoursAhead),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DomeForecastSlider(),
          ),
        ),
      );
    }

    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.byType(DomeForecastSlider), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('label shows "Live" when value is 0', (tester) async {
      await tester.pumpWidget(_buildWidget(initialHoursAhead: 0));
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('label shows "+12h" text when value is 12', (tester) async {
      await tester.pumpWidget(_buildWidget(initialHoursAhead: 12));
      // The label contains "+12h - " as part of the formatted string
      // (the tick label is just "+12h" without the dash)
      expect(
        find.textContaining('+12h - '),
        findsOneWidget,
      );
    });

    testWidgets('slider onChanged callback fires', (tester) async {
      await tester.pumpWidget(_buildWidget());

      // Find the slider and drag it
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider to the right (toward higher hours)
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // The label should no longer show "Live"
      // (it moved to some non-zero hour)
      expect(find.text('Live'), findsNothing);
    });
  });
}
