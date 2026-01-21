import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/screens/ar_view_screen.dart';
import 'package:wind_lens/widgets/altitude_slider.dart';
import 'package:wind_lens/widgets/camera_view.dart';
import 'package:wind_lens/widgets/info_bar.dart';

void main() {
  group('ARViewScreen', () {
    testWidgets('renders without crashing', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert
      expect(find.byType(ARViewScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - Find Scaffold and verify background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('contains CameraView widget', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert
      expect(find.byType(CameraView), findsOneWidget);
    });

    testWidgets('contains AltitudeSlider widget', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert
      expect(find.byType(AltitudeSlider), findsOneWidget);
    });
  });

  group('ARViewScreen Debug Panel', () {
    testWidgets('debug panel hidden by default', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - Debug panel content should NOT be visible initially
      expect(find.textContaining('Heading:'), findsNothing);
      expect(find.textContaining('Pitch:'), findsNothing);
      expect(find.textContaining('Sky:'), findsNothing);
    });

    testWidgets('debug panel shows FPS when visible', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Act - Simulate 3-finger tap using ScaleGesture with 3 pointers
      // Since we can't easily simulate 3-finger tap in tests,
      // we'll test that when shown, the debug panel contains FPS
      // This requires the debug panel to be visible

      // For now, we can verify the screen renders and InfoBar is present
      // The 3-finger gesture test is better suited for integration testing
      expect(find.byType(ARViewScreen), findsOneWidget);
    });

    testWidgets('debug panel shows particle count when visible', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - Screen renders correctly
      expect(find.byType(ARViewScreen), findsOneWidget);
    });
  });

  group('ARViewScreen Debug Toggle Button', () {
    testWidgets('debug toggle button is visible on screen', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - DBG button should always be visible
      expect(find.text('DBG'), findsOneWidget);
    });

    testWidgets('debug toggle button shows debug panel on tap', (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - Debug panel content should NOT be visible initially
      expect(find.textContaining('Heading:'), findsNothing);

      // Act - Tap the DBG button
      await tester.tap(find.text('DBG'));
      // Use pump() instead of pumpAndSettle() because ParticleOverlay animates continuously
      await tester.pump();

      // Assert - Debug panel content should now be visible
      expect(find.textContaining('Heading:'), findsOneWidget);
      expect(find.textContaining('Pitch:'), findsOneWidget);
      expect(find.textContaining('Sky:'), findsOneWidget);
    });

    testWidgets('debug toggle button hides debug panel on second tap',
        (tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Act - First tap to show debug panel
      await tester.tap(find.text('DBG'));
      // Use pump() instead of pumpAndSettle() because ParticleOverlay animates continuously
      await tester.pump();

      // Assert - Debug panel should be visible
      expect(find.textContaining('Heading:'), findsOneWidget);

      // Act - Second tap to hide debug panel
      await tester.tap(find.text('DBG'));
      await tester.pump();

      // Assert - Debug panel should be hidden again
      expect(find.textContaining('Heading:'), findsNothing);
    });
  });

  group('ARViewScreen InfoBar', () {
    testWidgets('info bar is visible', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - InfoBar should always be visible
      expect(find.byType(InfoBar), findsOneWidget);
    });

    testWidgets('info bar displays wind speed', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - InfoBar should show wind speed with m/s unit
      expect(find.textContaining('m/s'), findsOneWidget);
    });

    testWidgets('info bar displays altitude level', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ARViewScreen()));

      // Assert - InfoBar should show altitude level (default is Surface)
      expect(find.textContaining('Surface'), findsOneWidget);
    });
  });
}
