import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/location_override_provider.dart';

/// Small pill-shaped indicator showing the current location source.
///
/// Reads [locationOverrideProvider] and [effectivePositionProvider] directly:
/// - When no override is set: displays a pin icon + "GPS"
/// - When an override is set: displays a pin icon + "lat, lng" (4 decimal places)
///
/// Styled as a semi-transparent black pill to match the dome UI aesthetic.
class LocationIndicatorChip extends ConsumerWidget {
  const LocationIndicatorChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(locationOverrideProvider);
    final position = ref.watch(effectivePositionProvider);

    final bool isOverride = override != null;
    final String label;

    if (isOverride && position != null) {
      label = '${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}';
    } else {
      label = 'GPS';
    }

    final String semanticsLabel = isOverride
        ? 'Location source: custom coordinates'
        : 'Location source: GPS';

    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_pin,
              color: isOverride ? Colors.orangeAccent : Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isOverride ? Colors.orangeAccent : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
