import 'package:flutter/material.dart';

/// Static "TERRAIN" label displayed below the terrain section.
///
/// Replaces the previous toggle buttons (PARTICLES, PRESSURE, TERRAIN, CLOUDS)
/// which were visual-only and never wired to any providers.
class HomeLayerToggles extends StatelessWidget {
  const HomeLayerToggles({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
      child: Center(
        child: Text(
          'TERRAIN',
          style: TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 9,
            color: const Color(0xFF555555),
            letterSpacing: 1.35, // 0.15 * 9
          ),
        ),
      ),
    );
  }
}
