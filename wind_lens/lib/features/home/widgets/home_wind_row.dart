import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:wind_lens/core/models/altitude_level.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/scene_provider.dart';
import 'package:wind_lens/core/utils/wind_utils.dart';

/// Three-column wind data row showing Speed, Direction, and Altitude.
///
/// A [ConsumerWidget] that reads [sceneStateProvider] for wind data
/// and [selectedAltitudeProvider] for the current altitude level.
///
/// Shows "--" placeholder values while scene state is null (loading).
class HomeWindRow extends ConsumerWidget {
  const HomeWindRow({super.key});

  /// Maps [AltitudeLevel] to a display value for the altitude column.
  static String _altitudeValue(AltitudeLevel level) {
    return switch (level) {
      AltitudeLevel.surface => '33',
      AltitudeLevel.midLevel => '4.9K',
      AltitudeLevel.level700 => '9.8K',
      AltitudeLevel.level500 => '18K',
      AltitudeLevel.level300 => '29.5K',
      AltitudeLevel.jetStream => '34.4K',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneState = ref.watch(sceneStateProvider);
    final selectedAltitude = ref.watch(selectedAltitudeProvider);

    final wind = sceneState?.wind;
    final speedValue = wind != null ? wind.speed.toStringAsFixed(1) : '--';
    // Show wind flow direction (where it's headed), not meteorological "from".
    final towardDegrees = wind != null
        ? (wind.directionDegrees + 180) % 360
        : 0.0;
    final directionValue = wind != null
        ? degreesToCardinal(towardDegrees)
        : '--';
    final bearingText = wind != null
        ? 'toward ${towardDegrees.round()}\u00B0'
        : '';
    final altitudeValue = _altitudeValue(selectedAltitude);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Speed column
            Expanded(
              child: Semantics(
                label: wind != null
                    ? 'Wind speed $speedValue meters per second'
                    : 'Wind speed loading',
                child: _DataColumn(
                  label: 'SPEED',
                  value: speedValue,
                  unit: 'm/s',
                ),
              ),
            ),
            VerticalDivider(
              color: const Color(0xFF111111),
              thickness: 1,
              width: 1,
            ),
            // Direction column
            Expanded(
              child: Semantics(
                label: wind != null
                    ? 'Wind heading $directionValue'
                    : 'Wind heading loading',
                child: _DataColumn(
                  label: 'DIRECTION',
                  value: directionValue,
                  unit: bearingText,
                ),
              ),
            ),
            VerticalDivider(
              color: const Color(0xFF111111),
              thickness: 1,
              width: 1,
            ),
            // Altitude column
            Expanded(
              child: Semantics(
                label: 'Altitude $altitudeValue feet above ground level',
                child: _DataColumn(
                  label: 'ALTITUDE',
                  value: altitudeValue,
                  unit: 'ft AGL',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single data column with label, value, and unit.
class _DataColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _DataColumn({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 10,
              color: Color(0xFF555555),
              letterSpacing: 0.25 * 10, // 0.25em
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 11,
              color: Color(0xFF777777),
              letterSpacing: 0.15 * 11, // 0.15em
            ),
          ),
        ],
      ),
    );
  }
}
