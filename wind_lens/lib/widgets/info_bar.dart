import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/altitude_level.dart';

/// A user-facing info bar displaying wind speed, direction, and altitude.
///
/// Uses glassmorphism styling (frosted glass effect) consistent with
/// the AltitudeSlider. Designed to be positioned at the bottom of the
/// screen above the safe area.
///
/// Example:
/// ```dart
/// InfoBar(
///   windSpeed: 12.5,
///   windDirection: 45.0,
///   altitude: AltitudeLevel.surface,
/// )
/// ```
class InfoBar extends StatelessWidget {
  /// Wind speed in meters per second.
  final double windSpeed;

  /// Wind direction in degrees (0-360, clockwise from North).
  final double windDirection;

  /// Current altitude level being visualized.
  final AltitudeLevel altitude;

  /// Creates an InfoBar widget.
  ///
  /// All parameters are required:
  /// - [windSpeed]: Wind speed in m/s (displayed with 1 decimal)
  /// - [windDirection]: Direction in degrees (converted to cardinal)
  /// - [altitude]: Current altitude level (displayed by name)
  const InfoBar({
    super.key,
    required this.windSpeed,
    required this.windDirection,
    required this.altitude,
  });

  /// Border radius for the info bar container.
  static const double _borderRadius = 12.0;

  /// Converts degrees to 8-point cardinal direction.
  ///
  /// Uses the standard compass rose with 45-degree segments:
  /// - 0/360: N
  /// - 45: NE
  /// - 90: E
  /// - 135: SE
  /// - 180: S
  /// - 225: SW
  /// - 270: W
  /// - 315: NW
  String _getCardinalDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    // Normalize to 0-360 range and add 22.5 to center each sector
    final normalizedDegrees = degrees % 360;
    final index = ((normalizedDegrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Formats wind speed to one decimal place.
  String _formatWindSpeed(double speed) {
    return speed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wind speed section
              _buildWindSection(),
              const SizedBox(width: 16),
              // Vertical divider
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              // Altitude section
              _buildAltitudeSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the wind speed and direction display section.
  Widget _buildWindSection() {
    final cardinal = _getCardinalDirection(windDirection);
    final speedText = _formatWindSpeed(windSpeed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wind icon
        Icon(
          Icons.air,
          color: Colors.white.withValues(alpha: 0.9),
          size: 24,
        ),
        const SizedBox(width: 8),
        // Speed value
        Text(
          speedText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        // Unit
        Text(
          'm/s',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        // Cardinal direction
        Text(
          cardinal,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds the altitude level display section.
  Widget _buildAltitudeSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Altitude indicator dot with level color
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: altitude.particleColor,
            boxShadow: [
              BoxShadow(
                color: altitude.particleColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Altitude level name
        Text(
          altitude.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
