import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wind_lens/core/models/altitude_level.dart';
import 'package:wind_lens/core/providers/data_providers.dart';

/// Right-edge altitude tick marks showing 5 altitude levels.
///
/// A [ConsumerWidget] that reads [selectedAltitudeProvider] to determine
/// which tick is active. Only 3 of the 5 ticks map to real [AltitudeLevel]
/// values; the other 2 (7,500 ft, 1,000 ft) are decorative.
///
/// Active tick: white text, white line (18px wide), triangle marker.
/// Inactive tick: dim text (#282828), dim line (#222222, 12px wide).
class HomeAltitudeRail extends ConsumerWidget {
  const HomeAltitudeRail({super.key});

  /// The 5 tick definitions from top to bottom.
  static const _ticks = [
    _AltitudeTick(label: '10,000 ft', level: AltitudeLevel.jetStream),
    _AltitudeTick(label: '7,500 ft', level: null),
    _AltitudeTick(label: '2,400 ft', level: AltitudeLevel.midLevel),
    _AltitudeTick(label: '1,000 ft', level: null),
    _AltitudeTick(label: 'Surface', level: AltitudeLevel.surface),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAltitude = ref.watch(selectedAltitudeProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _ticks.map((tick) {
        final isActive = tick.level != null && tick.level == selectedAltitude;
        return GestureDetector(
          onTap: tick.level != null
              ? () => ref.read(selectedAltitudeProvider.notifier).select(tick.level!)
              : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tick.label,
                  style: GoogleFonts.dmMono(
                    fontSize: 8,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF282828),
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

  /// The [AltitudeLevel] this tick maps to, or null for decorative ticks.
  final AltitudeLevel? level;

  const _AltitudeTick({required this.label, required this.level});
}
