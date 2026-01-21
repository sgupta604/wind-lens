import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/widgets/info_bar.dart';

void main() {
  group('InfoBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 10.0,
              windDirection: 45.0,
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      expect(find.byType(InfoBar), findsOneWidget);
    });

    testWidgets('displays wind speed with m/s unit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 12.5,
              windDirection: 45.0,
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      // Should display wind speed value
      expect(find.textContaining('12.5'), findsOneWidget);
      // Should display m/s unit
      expect(find.textContaining('m/s'), findsOneWidget);
    });

    testWidgets('displays cardinal direction from degrees', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 10.0,
              windDirection: 45.0, // NE
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      // 45 degrees should show NE
      expect(find.textContaining('NE'), findsOneWidget);
    });

    testWidgets('displays altitude level name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 10.0,
              windDirection: 45.0,
              altitude: AltitudeLevel.midLevel,
            ),
          ),
        ),
      );

      // Should display the altitude level name (Cloud Level)
      expect(find.textContaining('Cloud Level'), findsOneWidget);
    });

    testWidgets('uses BackdropFilter for glassmorphism', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 10.0,
              windDirection: 45.0,
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      // Check for BackdropFilter which provides glassmorphism effect
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('uses ClipRRect for rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 10.0,
              windDirection: 45.0,
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      // Check for ClipRRect which provides rounded corners
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('handles zero wind speed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 0.0,
              windDirection: 0.0,
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      // Should display zero wind speed without crashing
      expect(find.textContaining('0.0'), findsOneWidget);
      expect(find.byType(InfoBar), findsOneWidget);
    });

    testWidgets('handles all altitude levels', (tester) async {
      for (final level in AltitudeLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 90.0,
                altitude: level,
              ),
            ),
          ),
        );

        // Should render without crashing for all altitude levels
        expect(find.byType(InfoBar), findsOneWidget);
        // Should display the altitude level name
        expect(find.textContaining(level.displayName), findsOneWidget);
      }
    });

    group('cardinal direction conversion', () {
      testWidgets('converts 0 degrees to N', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 0.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 0 degrees should be North
        // We need to find just "N" without matching NE, NW, etc.
        expect(find.text('N'), findsOneWidget);
      });

      testWidgets('converts 90 degrees to E', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 90.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 90 degrees should be East
        expect(find.text('E'), findsOneWidget);
      });

      testWidgets('converts 180 degrees to S', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 180.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 180 degrees should be South
        expect(find.text('S'), findsOneWidget);
      });

      testWidgets('converts 270 degrees to W', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 270.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 270 degrees should be West
        expect(find.text('W'), findsOneWidget);
      });

      testWidgets('converts 45 degrees to NE', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 45.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 45 degrees should be NE
        expect(find.text('NE'), findsOneWidget);
      });

      testWidgets('converts 135 degrees to SE', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 135.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 135 degrees should be SE
        expect(find.text('SE'), findsOneWidget);
      });

      testWidgets('converts 225 degrees to SW', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 225.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 225 degrees should be SW
        expect(find.text('SW'), findsOneWidget);
      });

      testWidgets('converts 315 degrees to NW', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 315.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 315 degrees should be NW
        expect(find.text('NW'), findsOneWidget);
      });

      testWidgets('handles 360 degrees as N', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InfoBar(
                windSpeed: 10.0,
                windDirection: 360.0,
                altitude: AltitudeLevel.surface,
              ),
            ),
          ),
        );

        // 360 degrees should be North (same as 0)
        expect(find.text('N'), findsOneWidget);
      });
    });

    testWidgets('formats wind speed with one decimal place', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBar(
              windSpeed: 5.678,
              windDirection: 0.0,
              altitude: AltitudeLevel.surface,
            ),
          ),
        ),
      );

      // Should format to one decimal place
      expect(find.textContaining('5.7'), findsOneWidget);
    });
  });
}
