import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/altitude_level.dart';
import '../models/compass_data.dart';
import '../models/view_mode.dart';
import '../models/wind_data.dart';
import '../services/compass_service.dart';
import '../services/fake_wind_service.dart';
import 'package:camera/camera.dart';
import '../services/sky_detection/auto_calibrating_sky_detector.dart';
import '../widgets/altitude_slider.dart';
import '../widgets/camera_view.dart';
import '../widgets/compass_widget.dart';
import '../widgets/info_bar.dart';
import '../widgets/particle_overlay.dart';

/// The main AR view screen that displays the camera feed with wind visualization.
///
/// This screen provides a fullscreen camera preview with a black background,
/// designed for augmented reality wind visualization. It includes:
/// - Wind-driven particle animation with two view modes (dots/streamlines)
/// - World-fixed particle direction (adjusts for compass heading)
/// - Altitude selection with visual depth effects (parallax)
/// - Toggleable debug panel (3-finger tap to show/hide)
/// - User-facing info bar with wind speed, direction, and altitude
/// - Adaptive performance management
/// - View mode toggle (long-press altitude slider or use debug panel button)
class ARViewScreen extends StatefulWidget {
  const ARViewScreen({super.key});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  /// The compass service for managing sensor data.
  late CompassService _compassService;

  /// The wind service for providing wind data.
  late FakeWindService _windService;

  /// Subscription to the compass data stream.
  StreamSubscription<CompassData>? _compassSubscription;

  /// Current compass heading in degrees (0-360).
  double _heading = 0;

  /// Current device pitch in degrees.
  double _pitch = 0;

  /// The sky detector for determining sky regions.
  /// Uses auto-calibrating color-based detection with pitch-based fallback.
  late AutoCalibratingSkyDetector _skyDetector;

  /// Current sky fraction (0.0 to 1.0).
  double _skyFraction = 0;

  /// Current wind data.
  WindData _windData = WindData.zero();

  /// Current altitude level for particle visualization.
  AltitudeLevel _altitudeLevel = AltitudeLevel.surface;

  /// Previous compass heading for parallax calculation.
  ///
  /// Stored before updating _heading to calculate the heading delta.
  double _previousHeading = 0;

  /// Whether the debug panel is visible.
  ///
  /// Toggle with 3-finger tap. Hidden by default for clean user experience.
  bool _showDebugPanel = false;

  /// Current FPS from ParticleOverlay (updated ~1/second).
  double _currentFps = 60.0;

  /// Current particle count (may be reduced by PerformanceManager).
  int _currentParticleCount = 2000;

  /// Whether the sky detector is calibrated.
  bool _isCalibrated = false;

  /// Current view mode for particle rendering.
  ///
  /// - dots: Traditional short line segments (default)
  /// - streamlines: Flowing trails with speed-based colors
  ViewMode _viewMode = ViewMode.dots;

  @override
  void initState() {
    super.initState();
    _compassService = CompassService();
    _windService = FakeWindService();
    _skyDetector = AutoCalibratingSkyDetector();
    _compassService.start();
    _compassSubscription = _compassService.stream.listen(_onCompassUpdate);
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _compassService.dispose();
    super.dispose();
  }

  /// Handles compass data updates from the service.
  ///
  /// Updates heading, pitch, sky detector, and fetches altitude-specific wind data.
  /// Stores previous heading before update for parallax calculation.
  void _onCompassUpdate(CompassData data) {
    setState(() {
      // Store previous heading BEFORE updating for parallax calculation
      _previousHeading = _heading;

      _heading = data.heading;
      _pitch = data.pitch;
      _skyDetector.updatePitch(_pitch);
      _skyFraction = _skyDetector.skyFraction;
      _isCalibrated = _skyDetector.isCalibrated;

      // Update wind data for current altitude level
      _windData = _windService.getWindForAltitude(_altitudeLevel);
    });
  }

  /// Handles camera frame updates for sky detection.
  ///
  /// Passes frames to the auto-calibrating sky detector for color-based
  /// sky detection and calibration.
  void _onCameraFrame(CameraImage image) {
    _skyDetector.processFrame(image);

    // Update sky fraction after processing (don't call setState too frequently)
    final newFraction = _skyDetector.skyFraction;
    final newCalibrated = _skyDetector.isCalibrated;

    if ((newFraction - _skyFraction).abs() > 0.01 ||
        newCalibrated != _isCalibrated) {
      setState(() {
        _skyFraction = newFraction;
        _isCalibrated = newCalibrated;
      });
    }
  }

  /// Handles altitude level changes from the slider.
  void _onAltitudeChanged(AltitudeLevel level) {
    setState(() {
      _altitudeLevel = level;
      // Immediately update wind data for the new altitude
      _windData = _windService.getWindForAltitude(_altitudeLevel);
    });
  }

  /// Handles FPS updates from the ParticleOverlay.
  void _onFpsUpdate(double fps, int particleCount) {
    setState(() {
      _currentFps = fps;
      _currentParticleCount = particleCount;
    });
  }

  /// Toggles the debug panel visibility with haptic feedback.
  void _toggleDebugPanel() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showDebugPanel = !_showDebugPanel;
    });
  }

  /// Toggles the view mode between dots and streamlines.
  ///
  /// Provides haptic feedback on toggle. In streamlines mode,
  /// the particle count may be reduced for better performance.
  void _toggleViewMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _viewMode = _viewMode.toggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // 3-finger tap detection for debug panel toggle
        onScaleStart: (details) {
          if (details.pointerCount >= 3) {
            _toggleDebugPanel();
          }
        },
        child: Stack(
          children: [
            // Layer 1: Camera feed as the base layer
            CameraView(onFrame: _onCameraFrame),

            // Layer 2: Particle overlay for wind visualization
            ParticleOverlay(
              skyMask: _skyDetector,
              windData: _windData,
              compassHeading: _heading,
              altitudeLevel: _altitudeLevel,
              previousHeading: _previousHeading,
              onFpsUpdate: _onFpsUpdate,
              viewMode: _viewMode,
              // Reduce particle count in streamlines mode for better performance
              particleCount: _viewMode == ViewMode.streamlines ? 1000 : 2000,
            ),

            // Layer 3: Debug toggle button (always visible)
            _buildDebugToggleButton(),

            // Layer 4: Debug panel (conditionally visible)
            // Positioned below the toggle button (8 + 40 + 8 = 56)
            if (_showDebugPanel)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                left: 8,
                child: _buildDebugPanel(),
              ),

            // Layer 5: Altitude slider positioned at right edge, vertically centered
            // Long-press toggles view mode (dots/streamlines)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onLongPress: _toggleViewMode,
                  child: AltitudeSlider(
                    value: _altitudeLevel,
                    onChanged: _onAltitudeChanged,
                  ),
                ),
              ),
            ),

            // Layer 6: Info bar at the bottom
            Positioned(
              left: 16,
              right: 80, // Leave space for altitude slider
              bottom: bottomPadding + 16,
              child: InfoBar(
                windSpeed: _windData.speed,
                windDirection: _windData.directionDegrees,
                altitude: _altitudeLevel,
              ),
            ),

            // Layer 7: Compass widget positioned above InfoBar
            Positioned(
              left: 16,
              bottom: bottomPadding + 76, // 16px margin + ~60px InfoBar height
              child: CompassWidget(heading: _heading),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the debug toggle button positioned in the top-left corner.
  ///
  /// This button provides a reliable way to toggle the debug panel on real
  /// devices, as the 3-finger gesture may not work reliably due to system
  /// gesture interference.
  Widget _buildDebugToggleButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      child: GestureDetector(
        onTap: _toggleDebugPanel,
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
    );
  }

  /// Builds the debug panel widget showing detailed metrics.
  ///
  /// Shows: Heading, Pitch, Sky%, Altitude, Wind, FPS, Particles, Recal button
  Widget _buildDebugPanel() {
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
          _buildDebugText('Heading: ${_heading.toStringAsFixed(1)}'),
          const SizedBox(height: 4),
          _buildDebugText('Pitch: ${_pitch.toStringAsFixed(1)}'),
          const SizedBox(height: 4),
          _buildDebugText('Sky: ${(_skyFraction * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 4),
          _buildDebugText('Sky Cal: ${_isCalibrated ? "Yes" : "No"}'),
          const SizedBox(height: 4),
          _buildDebugText('Altitude: ${_altitudeLevel.displayName}'),
          const SizedBox(height: 4),
          _buildDebugText(
              'Wind: ${_windData.speed.toStringAsFixed(1)}m/s @ ${_windData.directionDegrees.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          _buildDebugText('FPS: ${_currentFps.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          _buildDebugText('Particles: $_currentParticleCount'),
          const SizedBox(height: 4),
          _buildDebugText('Mode: ${_viewMode.displayName}'),
          const SizedBox(height: 8),
          // View mode toggle button
          GestureDetector(
            onTap: _toggleViewMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _viewMode == ViewMode.streamlines
                    ? Colors.purple.withValues(alpha: 0.7)
                    : Colors.grey.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _viewMode == ViewMode.dots ? 'Streamlines' : 'Dots',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Recalibrate sky button - allows user to force recalibration
          // when under overhang or if automatic calibration failed
          GestureDetector(
            onTap: _onRecalibratePressed,
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

  /// Handles the recalibrate button press.
  ///
  /// Forces the sky detector to recalibrate on the next frame.
  /// Provides haptic feedback to confirm the action.
  void _onRecalibratePressed() {
    HapticFeedback.mediumImpact();
    _skyDetector.forceRecalibrate();
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
