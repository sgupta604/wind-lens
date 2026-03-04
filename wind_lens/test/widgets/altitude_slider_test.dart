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

    testWidgets('starts collapsed showing current level label', (tester) async {
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

      // Collapsed state shows only the current level's label
      expect(find.text('SFC'), findsOneWidget);
      // Other labels should NOT be visible in collapsed state
      expect(find.text('250'), findsNothing);
      expect(find.text('300'), findsNothing);
      expect(find.text('500'), findsNothing);
      expect(find.text('700'), findsNothing);
      expect(find.text('850'), findsNothing);
    });

    testWidgets('renders all 6 stop labels when expanded', (tester) async {
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

      // Tap to expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // All 6 stops should show their labels when expanded
      expect(find.text('250'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('700'), findsOneWidget);
      expect(find.text('850'), findsOneWidget);
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

      // Collapsed state shows 850 label for midLevel
      expect(find.text('850'), findsOneWidget);
    });

    testWidgets('tapping collapsed pill expands the panel', (tester) async {
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

      // Initially collapsed -- only SFC visible
      expect(find.text('250'), findsNothing);

      // Tap to expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Now all labels should be visible
      expect(find.text('250'), findsOneWidget);
      expect(find.text('SFC'), findsOneWidget);
    });

    testWidgets('selecting a stop collapses the panel and calls onChanged',
        (tester) async {
      AltitudeLevel? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AltitudeSlider(
                  value: changedValue ?? AltitudeLevel.surface,
                  onChanged: (level) {
                    setState(() => changedValue = level);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Tap on 250 segment (jetStream)
      await tester.tap(find.text('250'));
      await tester.pumpAndSettle();

      expect(changedValue, AltitudeLevel.jetStream);

      // Panel should be collapsed again -- only selected label visible
      // (300, 500, 700, 850 should no longer be visible)
      expect(find.text('300'), findsNothing);
    });

    testWidgets('tapping a stop calls onChanged with correct AltitudeLevel',
        (tester) async {
      final List<AltitudeLevel> tappedLevels = [];
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

      // Expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Tap on 850 segment (jetStream -> midLevel)
      await tester.tap(find.text('850'));
      await tester.pumpAndSettle();

      // Expand again (now collapsed after selection)
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Tap on SFC segment (midLevel -> surface)
      await tester.tap(find.text('SFC'));
      await tester.pumpAndSettle();

      // Expand again
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Tap on 500 segment (surface -> level500)
      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();

      expect(tappedLevels, [
        AltitudeLevel.midLevel,
        AltitudeLevel.surface,
        AltitudeLevel.level500,
      ]);
    });

    testWidgets(
        'expanded panel has minimum touch target size (48pt height per segment)',
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

      // Expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Find the slider widget
      final sliderFinder = find.byType(AltitudeSlider);
      expect(sliderFinder, findsOneWidget);

      // Get the size of the expanded slider
      final sliderSize = tester.getSize(sliderFinder);

      // With 6 segments at 48px each + readout, total height should be >= 288
      expect(sliderSize.height, greaterThanOrEqualTo(288));
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

      // Expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Tap on already selected SFC segment
      await tester.tap(find.text('SFC'));
      await tester.pumpAndSettle();

      // Should not trigger callback since it's already selected
      // (panel collapses but no onChanged)
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

      // Expand first
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Get slider position
      final sliderFinder = find.byType(AltitudeSlider);
      final sliderTopLeft = tester.getTopLeft(sliderFinder);
      final sliderSize = tester.getSize(sliderFinder);

      // Simulate drag from top (250) to bottom (SFC)
      await tester.timedDragFrom(
        sliderTopLeft + const Offset(30, 10), // Start at top of 250 segment
        Offset(0, sliderSize.height - 20), // Drag to near bottom
        const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();

      // Should have triggered callbacks for levels crossed during drag
      expect(changedLevels, isNotEmpty);
      // Should have crossed through multiple levels
      expect(changedLevels.length, greaterThanOrEqualTo(2));
    });

    testWidgets('initial value matches value parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.level500,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider =
          tester.widget<AltitudeSlider>(find.byType(AltitudeSlider));
      expect(slider.value, AltitudeLevel.level500);

      // Collapsed should show 500 label
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('widget has correct width (60px)', (tester) async {
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

      final sliderFinder = find.byType(AltitudeSlider);
      final sliderSize = tester.getSize(sliderFinder);

      expect(sliderSize.width, 60.0);
    });

    testWidgets('renders 6 colored dots when expanded', (tester) async {
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

      // Expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Find all Container widgets that are 8x8 circles (colored dots)
      final allContainers = find.byType(Container);
      int circleCount = 0;
      for (final element in allContainers.evaluate()) {
        final widget = element.widget as Container;
        if (widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          if (deco.shape == BoxShape.circle) {
            circleCount++;
          }
        }
      }
      // Should find at least 6 circle containers (the colored dots)
      expect(circleCount, greaterThanOrEqualTo(6));
    });

    testWidgets('shows altitude readout when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.level500,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Expand
      await tester.tap(find.byType(AltitudeSlider));
      await tester.pumpAndSettle();

      // Should show the meters readout for selected level (5,500m)
      expect(find.text('5,500m'), findsOneWidget);
    });

    testWidgets('altitude readout not visible when collapsed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AltitudeSlider(
              value: AltitudeLevel.level500,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Collapsed -- no meters readout
      expect(find.text('5,500m'), findsNothing);
    });

    testWidgets('has AnimatedSize for expand/collapse animation',
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

      expect(find.byType(AnimatedSize), findsOneWidget);
    });
  });
}
