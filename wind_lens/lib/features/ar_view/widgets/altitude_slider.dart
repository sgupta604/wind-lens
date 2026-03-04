import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wind_lens/core/models/altitude_level.dart';

/// A collapsible vertical altitude selector for the AR view.
///
/// **Collapsed (default):** A small pill button showing the current altitude
/// level as a colored dot and short label (e.g., "SFC"). Tap to expand.
///
/// **Expanded:** A vertical panel with 6 altitude stops from highest (250 hPa)
/// at the top to lowest (Surface) at the bottom. Each stop shows a colored dot
/// and label. Tapping a stop selects it and collapses the panel. Tapping the
/// pill again collapses without changing the selection.
///
/// Uses glassmorphism styling (frosted glass effect) for a modern AR appearance.
///
/// Features:
/// - 6 altitude stops: Surface, 850 hPa, 700 hPa, 500 hPa, 300 hPa, 250 hPa
/// - Collapsible toggle: collapsed by default, tap to expand
/// - Visual highlighting of selected stop
/// - Haptic feedback on selection change
/// - Drag gesture support when expanded
/// - Altitude meters readout when expanded
/// - Minimum 48pt touch targets for accessibility
///
/// Example:
/// ```dart
/// AltitudeSlider(
///   value: AltitudeLevel.surface,
///   onChanged: (level) {
///     ref.read(selectedAltitudeProvider.notifier).select(level);
///   },
/// )
/// ```
class AltitudeSlider extends StatefulWidget {
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
  static const double _segmentHeight = 48.0;

  /// Border radius for the slider.
  static const double _borderRadius = 12.0;

  /// The 6 altitude levels in top-to-bottom order (highest first).
  static const _levels = [
    AltitudeLevel.jetStream,
    AltitudeLevel.level300,
    AltitudeLevel.level500,
    AltitudeLevel.level700,
    AltitudeLevel.midLevel,
    AltitudeLevel.surface,
  ];

  @override
  State<AltitudeSlider> createState() => _AltitudeSliderState();
}

class _AltitudeSliderState extends State<AltitudeSlider> {
  bool _isExpanded = false;

  /// Maps altitude levels to their short labels.
  static String _getLabel(AltitudeLevel level) {
    return switch (level) {
      AltitudeLevel.jetStream => '250',
      AltitudeLevel.level300 => '300',
      AltitudeLevel.level500 => '500',
      AltitudeLevel.level700 => '700',
      AltitudeLevel.midLevel => '850',
      AltitudeLevel.surface => 'SFC',
    };
  }

  /// Formats meters for display (e.g., "5,500m").
  static String _formatMeters(double meters) {
    if (meters >= 1000) {
      final formatted = meters.toInt().toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
      return '${formatted}m';
    }
    return '${meters.toInt()}m';
  }

  /// Determines which altitude level corresponds to a Y position.
  AltitudeLevel _levelFromY(double localY) {
    final segmentIndex = (localY / AltitudeSlider._segmentHeight)
        .floor()
        .clamp(0, AltitudeSlider._levels.length - 1);
    return AltitudeSlider._levels[segmentIndex];
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectLevel(AltitudeLevel level) {
    if (level != widget.value) {
      HapticFeedback.lightImpact();
      widget.onChanged(level);
    }
    setState(() {
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
    );
  }

  /// Builds the collapsed pill button showing current level.
  Widget _buildCollapsed() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AltitudeSlider._borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: AltitudeSlider._width,
            height: AltitudeSlider._segmentHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AltitudeSlider._borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
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
                      color: widget.value.particleColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.value.particleColor
                              .withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label text
                  Text(
                    _getLabel(widget.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the expanded panel with all 6 altitude stops.
  Widget _buildExpanded() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final newLevel = _levelFromY(details.localPosition.dy);
        if (newLevel != widget.value) {
          HapticFeedback.lightImpact();
          widget.onChanged(newLevel);
        }
      },
      onVerticalDragEnd: (_) {
        // Collapse after drag ends
        setState(() {
          _isExpanded = false;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AltitudeSlider._borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: AltitudeSlider._width,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AltitudeSlider._borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < AltitudeSlider._levels.length; i++)
                  _buildSegment(
                    level: AltitudeSlider._levels[i],
                    isFirst: i == 0,
                    isLast: i == AltitudeSlider._levels.length - 1,
                  ),
                // Altitude readout below stops
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Semantics(
                    label:
                        'Altitude ${_formatMeters(widget.value.metersAGL)}',
                    child: Text(
                      _formatMeters(widget.value.metersAGL),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single segment of the expanded slider.
  Widget _buildSegment({
    required AltitudeLevel level,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = widget.value == level;

    return GestureDetector(
      onTap: () => _selectLevel(level),
      child: Container(
        width: AltitudeSlider._width,
        height: AltitudeSlider._segmentHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst
                ? Radius.circular(AltitudeSlider._borderRadius - 1)
                : Radius.zero,
            bottom: isLast
                ? Radius.circular(AltitudeSlider._borderRadius - 1)
                : Radius.zero,
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
                            color:
                                level.particleColor.withValues(alpha: 0.6),
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
                  color: Colors.white
                      .withValues(alpha: isSelected ? 1.0 : 0.7),
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
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
