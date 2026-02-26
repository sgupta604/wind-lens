// Wind Lens main app widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/app.dart';
import 'package:wind_lens/features/home/home_screen.dart';

void main() {
  testWidgets('WindLensApp renders HomeScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WindLensApp());

    // Use pump() not pumpAndSettle() -- animation controllers never settle
    await tester.pump();

    // Verify that HomeScreen is rendered (app entry point changed from ARViewScreen)
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify dark theme is applied (Scaffold has black background)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, equals(Colors.black));
  });
}
