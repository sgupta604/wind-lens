import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom compass row showing 8 cardinal/intercardinal directions.
///
/// Uses [ValueListenableBuilder] on [headingNotifier] to avoid setState
/// and minimize widget rebuilds. The active direction (nearest to the
/// current heading) is highlighted in grey; all others are dim.
///
/// Directions: N, NE, E, SE, S, SW, W, NW
class HomeCompassBar extends StatelessWidget {
  /// The heading notifier providing compass heading in degrees (0-360).
  final ValueNotifier<double> headingNotifier;

  const HomeCompassBar({super.key, required this.headingNotifier});

  static const _directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  /// Determines the active direction index (0-7) from a heading in degrees.
  static int _activeIndex(double heading) {
    return ((heading + 22.5) % 360 / 45).floor();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: headingNotifier,
      builder: (context, heading, _) {
        final active = _activeIndex(heading);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_directions.length, (i) {
              final isActive = i == active;
              return Text(
                _directions[i],
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: isActive
                      ? const Color(0xFF666666)
                      : const Color(0xFF222222),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
