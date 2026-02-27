import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dome_providers.dart';

/// Bottom slider for scrubbing through the 72-hour wind forecast.
///
/// Displays "Live" when at hour 0, or "+Nh - Day, Mon DD, H:MM AM/PM"
/// when in forecast mode. Updates [hoursAheadProvider] on drag.
///
/// A [ConsumerWidget] that reads/writes [hoursAheadProvider].
class DomeForecastSlider extends ConsumerWidget {
  const DomeForecastSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAhead = ref.watch(hoursAheadProvider);

    return Semantics(
      label: hoursAhead == 0
          ? 'Forecast time slider, currently showing live conditions'
          : 'Forecast time slider, currently showing plus $hoursAhead hours',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Text(
              _formatLabel(hoursAhead),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.1),
                trackHeight: 2,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: hoursAhead.toDouble(),
                min: 0,
                max: 72,
                divisions: 72,
                onChanged: (value) {
                  ref.read(hoursAheadProvider.notifier).state =
                      value.round();
                },
              ),
            ),
            // Tick labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final h in [0, 12, 24, 36, 48, 60, 72])
                    Text(
                      h == 0 ? 'Now' : '+${h}h',
                      style: TextStyle(
                        color: hoursAhead == h
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(int hoursAhead) {
    if (hoursAhead == 0) return 'Live';

    final targetTime = DateTime.now().add(Duration(hours: hoursAhead));
    final dayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final day = dayNames[targetTime.weekday - 1];
    final month = monthNames[targetTime.month - 1];
    final hour = targetTime.hour % 12 == 0 ? 12 : targetTime.hour % 12;
    final amPm = targetTime.hour < 12 ? 'AM' : 'PM';
    final minute = targetTime.minute.toString().padLeft(2, '0');

    return '+${hoursAhead}h - $day, $month ${targetTime.day}, $hour:$minute $amPm';
  }
}
