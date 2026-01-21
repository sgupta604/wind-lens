import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/altitude_level.dart';

/// A vertical slider for selecting altitude levels.
///
/// Displays three segments (JET, MID, SFC) from top to bottom, allowing
/// the user to tap to select a different altitude level. Uses glassmorphism
/// styling (frosted glass effect) for a modern AR appearance.
///
/// Features:
/// - Glassmorphism background with blur effect
/// - Three tappable segments with clear labels
/// - Visual highlighting of selected segment
/// - Haptic feedback on selection change
/// - Minimum 48pt touch targets for accessibility
///
/// Example:
/// ```dart
/// AltitudeSlider(
///   value: AltitudeLevel.surface,
///   onChanged: (level) {
///     setState(() => _altitudeLevel = level);
///   },
/// )
/// ```
class AltitudeSlider extends StatelessWidget {
  /// The currently selected altitude level.
  final AltitudeLevel value;

  /// Called when the user selects a different altitude level.
  final ValueChanged<AltitudeLevel> onChanged;

  /// Creates an AltitudeSlider.
  ///
  /// Both [value] and [onChanged] are required.
  const AltitudeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Width of the slider.
  static const double _width = 60.0;

  /// Height of each segment (minimum 48pt for accessibility).
  static const double _segmentHeight = 56.0;

  /// Border radius for the slider.
  static const double _borderRadius = 12.0;

  /// Maps altitude levels to their short labels.
  String _getLabel(AltitudeLevel level) {
    return switch (level) {
      AltitudeLevel.jetStream => 'JET',
      AltitudeLevel.midLevel => 'MID',
      AltitudeLevel.surface => 'SFC',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: _width,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // JET (top) - Jet Stream
              _buildSegment(
                level: AltitudeLevel.jetStream,
                isFirst: true,
              ),
              // MID (middle) - Mid-level / Cloud level
              _buildSegment(
                level: AltitudeLevel.midLevel,
              ),
              // SFC (bottom) - Surface
              _buildSegment(
                level: AltitudeLevel.surface,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single segment of the slider.
  Widget _buildSegment({
    required AltitudeLevel level,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = value == level;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          // Provide haptic feedback on level change
          HapticFeedback.lightImpact();
          onChanged(level);
        }
      },
      child: Container(
        width: _width,
        height: _segmentHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? Radius.circular(_borderRadius - 1) : Radius.zero,
            bottom: isLast ? Radius.circular(_borderRadius - 1) : Radius.zero,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: level.particleColor,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: level.particleColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              // Label text
              Text(
                _getLabel(level),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
