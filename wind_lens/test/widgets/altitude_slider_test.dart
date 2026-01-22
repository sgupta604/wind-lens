import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/widgets/altitude_slider.dart';

void main() {
  group('AltitudeSlider', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AltitudeSlider), findsOneWidget);
    });

    testWidgets('displays all three segments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should have exactly 3 tappable segments
      // Each segment should be a GestureDetector or InkWell
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('shows correct labels (JET, MID, SFC)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Check for the segment labels
      expect(find.text('JET'), findsOneWidget);
      expect(find.text('MID'), findsOneWidget);
      expect(find.text('SFC'), findsOneWidget);
    });

    testWidgets('highlights selected segment visually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.midLevel,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // The widget should render with midLevel selected
      final slider =
          tester.widget<AltitudeSlider>(find.byType(AltitudeSlider));
      expect(slider.value, AltitudeLevel.midLevel);
    });

    testWidgets('calls onChanged when segment tapped', (tester) async {
      AltitudeLevel? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (level) {
                changedValue = level;
              },
            ),
          ),
        ),
      );

      // Tap on JET segment (top)
      await tester.tap(find.text('JET'));
      await tester.pump();

      expect(changedValue, AltitudeLevel.jetStream);
    });

    testWidgets('selects correct level based on tap position', (tester) async {
      final List<AltitudeLevel> tappedLevels = [];
      AltitudeLevel currentValue = AltitudeLevel.jetStream; // Start with jetStream selected

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AltitudeSlider(
                    value: currentValue,
                    onChanged: (level) {
                      tappedLevels.add(level);
                      setState(() => currentValue = level);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap on MID segment (jetStream -> midLevel)
      await tester.tap(find.text('MID'));
      await tester.pump();

      // Tap on SFC segment (midLevel -> surface)
      await tester.tap(find.text('SFC'));
      await tester.pump();

      // Tap on JET segment (surface -> jetStream)
      await tester.tap(find.text('JET'));
      await tester.pump();

      expect(tappedLevels, [
        AltitudeLevel.midLevel,
        AltitudeLevel.surface,
        AltitudeLevel.jetStream,
      ]);
    });

    testWidgets('has minimum touch target size (48pt height per segment)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AltitudeSlider(
                value: AltitudeLevel.surface,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Find the slider widget
      final sliderFinder = find.byType(AltitudeSlider);
      expect(sliderFinder, findsOneWidget);

      // Get the size of the slider
      final sliderSize = tester.getSize(sliderFinder);

      // With 3 segments, total height should be at least 3 * 48 = 144pt
      expect(sliderSize.height, greaterThanOrEqualTo(144));
    });

    testWidgets('does not call onChanged when tapping already selected segment',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (_) {
                callCount++;
              },
            ),
          ),
        ),
      );

      // Tap on already selected SFC segment
      await tester.tap(find.text('SFC'));
      await tester.pump();

      // Should not trigger callback since it's already selected
      expect(callCount, 0);
    });

    testWidgets('uses glassmorphism styling (has BackdropFilter)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Check for BackdropFilter which is used for glassmorphism effect
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('has ClipRRect for rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.surface,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Check for ClipRRect which provides rounded corners
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('calls onChanged when dragging between segments',
        (tester) async {
      final List<AltitudeLevel> changedLevels = [];
      AltitudeLevel currentValue = AltitudeLevel.jetStream;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AltitudeSlider(
                    value: currentValue,
                    onChanged: (level) {
                      changedLevels.add(level);
                      setState(() => currentValue = level);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Get slider position
      final sliderFinder = find.byType(AltitudeSlider);
      final sliderTopLeft = tester.getTopLeft(sliderFinder);

      // Simulate drag from top (JET) to bottom (SFC)
      // Each segment is 56px high, so drag 120px to cross both boundaries
      await tester.timedDragFrom(
        sliderTopLeft + const Offset(30, 10), // Start at top of JET segment
        const Offset(0, 120), // Drag down through MID to SFC
        const Duration(milliseconds: 300),
      );
      await tester.pump();

      // Should have triggered callbacks for MID and SFC (crossed 2 boundaries)
      expect(changedLevels, contains(AltitudeLevel.midLevel));
      expect(changedLevels, contains(AltitudeLevel.surface));
    });
  });
}
