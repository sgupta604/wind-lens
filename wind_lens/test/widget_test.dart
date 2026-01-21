// Wind Lens main app widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/main.dart';
import 'package:wind_lens/screens/ar_view_screen.dart';

void main() {
  testWidgets('WindLensApp renders ARViewScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WindLensApp());

    // Verify that ARViewScreen is rendered
    expect(find.byType(ARViewScreen), findsOneWidget);

    // Verify dark theme is applied (Scaffold has black background)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(Colors.black));
  });
}
