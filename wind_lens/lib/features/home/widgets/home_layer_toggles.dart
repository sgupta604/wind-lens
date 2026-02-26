import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom button row with four layer toggle buttons.
///
/// In MVP these are visual-only -- no functional wiring to providers.
/// Wire to `detectionModeProvider` in a follow-up feature.
///
/// Button states:
/// - "on": white background, black text (PARTICLES, TERRAIN)
/// - "dim": dark background, dark border, grey text (PRESSURE, CLOUDS)
class HomeLayerToggles extends StatelessWidget {
  const HomeLayerToggles({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
      child: Row(
        children: [
          _ToggleButton(label: 'PARTICLES', isOn: true),
          const SizedBox(width: 8),
          _ToggleButton(label: 'PRESSURE', isOn: false),
          const SizedBox(width: 8),
          _ToggleButton(label: 'TERRAIN', isOn: true),
          const SizedBox(width: 8),
          _ToggleButton(label: 'CLOUDS', isOn: false),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isOn;

  const _ToggleButton({required this.label, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isOn ? Colors.white : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(6),
          border: isOn
              ? null
              : Border.all(color: const Color(0xFF222222), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 9,
            color: isOn ? Colors.black : const Color(0xFF555555),
            letterSpacing: 0.15 * 9, // 0.15em
          ),
        ),
      ),
    );
  }
}
