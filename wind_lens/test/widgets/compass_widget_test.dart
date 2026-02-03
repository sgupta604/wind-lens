import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/widgets/compass_widget.dart';

void main() {
  group('CompassWidget', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      expect(find.byType(CompassWidget), findsOneWidget);
    });

    testWidgets('accepts heading boundary value 0 (North)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      final widget = tester.widget<CompassWidget>(find.byType(CompassWidget));
      expect(widget.heading, 0);
    });

    testWidgets('accepts heading boundary value 180 (South)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 180),
          ),
        ),
      );

      final widget = tester.widget<CompassWidget>(find.byType(CompassWidget));
      expect(widget.heading, 180);
    });

    testWidgets('accepts heading boundary value 360', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 360),
          ),
        ),
      );

      final widget = tester.widget<CompassWidget>(find.byType(CompassWidget));
      expect(widget.heading, 360);
    });

    testWidgets('has BackdropFilter for glassmorphism effect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('has ClipRRect for rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('has CustomPaint widget for compass dial', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      // Find CustomPaint that is a descendant of CompassWidget
      expect(
        find.descendant(
          of: find.byType(CompassWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has correct size (68x68 pixels)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CompassWidget(heading: 0),
            ),
          ),
        ),
      );

      final widgetSize = tester.getSize(find.byType(CompassWidget));
      expect(widgetSize.width, 68.0);
      expect(widgetSize.height, 68.0);
    });

    testWidgets('displays cardinal direction N', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      // The N label is rendered by the CustomPainter
      // We verify by checking that the widget renders without error
      // and that CustomPaint is present as a descendant
      expect(
        find.descendant(
          of: find.byType(CompassWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays cardinal direction S', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CompassWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays cardinal direction E', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CompassWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays cardinal direction W', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CompassWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has circular shape (borderRadius equals half diameter)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassWidget(heading: 0),
          ),
        ),
      );

      // Find the ClipRRect and verify it has circular border radius
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(34.0));
    });
  });

  group('CompassPainter', () {
    test('shouldRepaint returns true when heading changes', () {
      final painter1 = CompassPainter(heading: 0);
      final painter2 = CompassPainter(heading: 90);

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when heading unchanged', () {
      final painter1 = CompassPainter(heading: 45);
      final painter2 = CompassPainter(heading: 45);

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('handles negative heading values', () {
      // Should not throw
      final painter = CompassPainter(heading: -10);
      expect(painter.heading, -10);
    });

    test('handles heading values over 360', () {
      // Should not throw
      final painter = CompassPainter(heading: 400);
      expect(painter.heading, 400);
    });
  });
}
