import 'package:flutter/material.dart';

import '../models/altitude_level.dart';
import '../models/view_mode.dart';
import '../models/wind_data.dart';

/// A debug panel widget that displays detailed metrics and provides
/// developer controls for the AR view.
///
/// Shows: heading, pitch, sky fraction, calibration state, altitude,
/// wind data, FPS, particle count, and view mode. Also provides buttons
/// to toggle view mode and force sky recalibration.
///
/// The panel has two parts:
/// - A toggle button (always visible) labeled "DBG"
/// - A details panel (shown when [showPanel] is true)
///
/// All data flows through constructor parameters and all user actions
/// flow through callback parameters, keeping this widget stateless.
///
/// Example:
/// ```dart
/// DebugPanel(
///   heading: 127.3,
///   pitch: 12.5,
///   skyFraction: 0.65,
///   isCalibrated: true,
///   altitudeLevel: AltitudeLevel.surface,
///   windData: windData,
///   currentFps: 58.0,
///   currentParticleCount: 2000,
///   viewMode: ViewMode.dots,
///   showPanel: false,
///   onTogglePanel: () {},
///   onToggleViewMode: () {},
///   onRecalibrate: () {},
/// )
/// ```
class DebugPanel extends StatelessWidget {
  /// Current compass heading in degrees (0-360).
  final double heading;

  /// Current device pitch in degrees.
  final double pitch;

  /// Current sky fraction (0.0 to 1.0).
  final double skyFraction;

  /// Whether the sky detector is calibrated.
  final bool isCalibrated;

  /// Current altitude level being visualized.
  final AltitudeLevel altitudeLevel;

  /// Current wind data.
  final WindData windData;

  /// Current frames per second.
  final double currentFps;

  /// Current particle count (may be reduced by PerformanceManager).
  final int currentParticleCount;

  /// Current view mode (dots or streamlines).
  final ViewMode viewMode;

  /// Whether the details panel is visible.
  final bool showPanel;

  /// Callback when the toggle button is tapped.
  final VoidCallback onTogglePanel;

  /// Callback when the view mode toggle button is tapped.
  final VoidCallback onToggleViewMode;

  /// Callback when the recalibrate button is tapped.
  final VoidCallback onRecalibrate;

  /// Current GPS latitude in degrees, or null if GPS not available.
  final double? latitude;

  /// Current GPS longitude in degrees, or null if GPS not available.
  final double? longitude;

  /// Creates a DebugPanel widget.
  ///
  /// All parameters except [latitude] and [longitude] are required.
  /// Data parameters provide values to display, and callback parameters
  /// handle user interactions. GPS fields are nullable -- when null,
  /// the GPS row is hidden.
  const DebugPanel({
    super.key,
    required this.heading,
    required this.pitch,
    required this.skyFraction,
    required this.isCalibrated,
    required this.altitudeLevel,
    required this.windData,
    required this.currentFps,
    required this.currentParticleCount,
    required this.viewMode,
    required this.showPanel,
    required this.onTogglePanel,
    required this.onToggleViewMode,
    required this.onRecalibrate,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle button (always visible)
        GestureDetector(
          onTap: onTogglePanel,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'DBG',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        // Details panel (conditionally visible)
        if (showPanel) ...[
          const SizedBox(height: 8),
          _buildDetailsPanel(),
        ],
      ],
    );
  }

  /// Builds the details panel showing all metrics and controls.
  Widget _buildDetailsPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDebugText('Heading: ${heading.toStringAsFixed(1)}'),
          const SizedBox(height: 4),
          _buildDebugText('Pitch: ${pitch.toStringAsFixed(1)}'),
          const SizedBox(height: 4),
          _buildDebugText('Sky: ${(skyFraction * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 4),
          _buildDebugText('Sky Cal: ${isCalibrated ? "Yes" : "No"}'),
          const SizedBox(height: 4),
          _buildDebugText('Altitude: ${altitudeLevel.displayName}'),
          const SizedBox(height: 4),
          _buildDebugText(
              'Wind: ${windData.speed.toStringAsFixed(1)}m/s @ ${windData.directionDegrees.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          _buildDebugText('FPS: ${currentFps.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          _buildDebugText('Particles: $currentParticleCount'),
          const SizedBox(height: 4),
          _buildDebugText('Mode: ${viewMode.displayName}'),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 4),
            _buildDebugText(
                'GPS: ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'),
          ],
          const SizedBox(height: 8),
          // View mode toggle button
          GestureDetector(
            onTap: onToggleViewMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: viewMode == ViewMode.streamlines
                    ? Colors.purple.withValues(alpha: 0.7)
                    : Colors.grey.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                viewMode == ViewMode.dots ? 'Streamlines' : 'Dots',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Recalibrate sky button
          GestureDetector(
            onTap: onRecalibrate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Recal Sky',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single line of debug text.
  Widget _buildDebugText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }
}
