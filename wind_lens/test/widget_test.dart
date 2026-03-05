// Wind Lens main app widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/app.dart';
import 'package:wind_lens/features/splash/splash_screen.dart';

void main() {
  testWidgets('WindLensApp renders SplashScreen as initial route',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WindLensApp());

    // Use pump() not pumpAndSettle() -- animation controllers never settle
    await tester.pump();

    // Verify that SplashScreen is rendered (initial route changed from HomeScreen)
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify dark theme is applied (Scaffold has black background)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, equals(Colors.black));

    // Drain timers (2s min-time + 60s error timer)
    await tester.pump(const Duration(seconds: 61));
  });
}
