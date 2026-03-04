import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_providers.dart';
import '../models/dome_constants.dart';
import '../models/dome_wind_field.dart';
import '../providers/dome_providers.dart';

/// Size presets for the dome radius in meters.
///
/// Presets >= 25km trigger grid-based wind fetching with spatial variation.
const _sizePresets = <(String, double)>[
  ('500m', 500.0),
  ('1km', 1000.0),
  ('2km', 2000.0),
  ('5km', 5000.0),
  ('25km', 25000.0),
  ('50km', 50000.0),
];

/// Top info bar showing wind speed, live/forecast badge, back button, and
/// dome size preset buttons.
///
/// A [ConsumerWidget] that reads [currentDomeWindFieldProvider],
/// [hoursAheadProvider], and [domeSizeProvider].
class DomeInfoBar extends ConsumerWidget {
  /// Callback when the back button is tapped.
  final VoidCallback onBack;

  const DomeInfoBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windField = ref.watch(currentDomeWindFieldProvider);
    final hoursAhead = ref.watch(hoursAheadProvider);
    final currentSize = ref.watch(domeSizeProvider);
    final arWind = ref.watch(windDataProvider);

    final isLive = hoursAhead == 0;
    // When live (hoursAhead == 0), display the AR wind speed for consistency.
    // When in forecast mode, use the dome's own time-series surface speed.
    final windSpeed = isLive
        ? (arWind.valueOrNull?.speed ?? _surfaceSpeed(windField))
        : _surfaceSpeed(windField);

    return Semantics(
      label:
          'Wind dome info bar. Wind speed ${windSpeed.toStringAsFixed(1)} meters per second. ${isLive ? 'Live' : 'Forecast'}.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: back button, wind speed, live/forecast badge
            Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Wind speed
                Text(
                  '${windSpeed.toStringAsFixed(1)} m/s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // Live / Forecast badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLive ? Icons.circle : Icons.play_arrow,
                        color: isLive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        size: 8,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? 'Live' : 'Fcst',
                        style: TextStyle(
                          color: isLive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Bottom row: dome size presets
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (label, value) in _sizePresets) ...[
                  _SizePresetButton(
                    label: label,
                    isActive: currentSize == value,
                    onTap: () {
                      ref.read(domeSizeProvider.notifier).state = value;
                    },
                  ),
                  if (label != _sizePresets.last.$1)
                    const SizedBox(width: 8),
                ],
              ],
            ),

            const SizedBox(height: 4),

            // Altitude range label
            Semantics(
              label: 'Dome altitude range: Surface to ${DomeConstants.maxAltitudeMeters.toInt()} meters',
              child: Text(
                'Surface \u2013 ${DomeConstants.maxAltitudeMeters.toInt()}m',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extracts the surface wind speed from the current field.
  double _surfaceSpeed(DomeWindField? field) {
    if (field == null || field.layers.isEmpty) return 0.0;
    final surface = field.layers.first;
    return sqrt(surface.u * surface.u + surface.v * surface.v);
  }
}

/// A small pill-shaped button for dome size presets.
class _SizePresetButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SizePresetButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dome size $label',
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
