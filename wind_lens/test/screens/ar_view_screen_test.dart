import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/screens/ar_view_screen.dart';
import 'package:wind_lens/widgets/camera_view.dart';

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
  });
}
