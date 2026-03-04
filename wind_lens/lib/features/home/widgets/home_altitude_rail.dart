import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wind_lens/core/models/altitude_level.dart';
import 'package:wind_lens/core/providers/data_providers.dart';

/// Right-edge altitude tick marks showing 6 altitude levels.
///
/// A [ConsumerWidget] that reads [selectedAltitudeProvider] to determine
/// which tick is active. All 6 ticks map to real [AltitudeLevel] values
/// and are tappable.
///
/// Active tick: white text, white line (18px wide), triangle marker.
/// Inactive tick: dim text (#282828), dim line (#222222, 12px wide).
class HomeAltitudeRail extends ConsumerWidget {
  const HomeAltitudeRail({super.key});

  /// The 6 tick definitions from top (highest) to bottom (lowest).
  static const _ticks = [
    _AltitudeTick(label: '250 hPa', level: AltitudeLevel.jetStream),
    _AltitudeTick(label: '300 hPa', level: AltitudeLevel.level300),
    _AltitudeTick(label: '500 hPa', level: AltitudeLevel.level500),
    _AltitudeTick(label: '700 hPa', level: AltitudeLevel.level700),
    _AltitudeTick(label: '850 hPa', level: AltitudeLevel.midLevel),
    _AltitudeTick(label: 'Surface', level: AltitudeLevel.surface),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAltitude = ref.watch(selectedAltitudeProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _ticks.map((tick) {
        final isActive = tick.level == selectedAltitude;
        return GestureDetector(
          onTap: () =>
              ref.read(selectedAltitudeProvider.notifier).select(tick.level),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Altitude ${tick.label}',
                  button: true,
                  selected: isActive,
                  child: Text(
                    tick.label,
                    style: GoogleFonts.dmMono(
                      fontSize: 8,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF282828),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (isActive) ...[
                  const Text(
                    '\u25C0', // left-pointing triangle
                    style: TextStyle(
                      fontSize: 6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                Container(
                  width: isActive ? 18 : 12,
                  height: 1,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF222222),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Represents a single altitude tick on the rail.
class _AltitudeTick {
  final String label;

  /// The [AltitudeLevel] this tick maps to.
  final AltitudeLevel level;

  const _AltitudeTick({required this.label, required this.level});
}
