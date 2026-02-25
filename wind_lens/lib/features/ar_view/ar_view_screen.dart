import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wind_lens/core/models/altitude_level.dart';
import 'package:wind_lens/core/models/sky_mask_data.dart';
import 'package:wind_lens/core/models/view_mode.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/scene_provider.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/core/providers/service_providers.dart';
import 'package:wind_lens/services/sky_detection/hsv_sky_detector.dart';
import 'widgets/altitude_slider.dart';
import 'widgets/camera_view.dart';
import 'widgets/compass_widget.dart';
import 'widgets/data_status_bar.dart';
import 'widgets/debug_panel.dart';
import 'widgets/info_bar.dart';
import 'widgets/particle_overlay.dart';

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
///
/// Uses Riverpod for state management:
/// - [sceneStateProvider] for composed wind/horizon/position data
/// - [selectedAltitudeProvider] for user-selected altitude level
/// - [stablePositionProvider] for GPS location display
/// - [sensorNotifiersProvider] for high-frequency heading/pitch (60Hz)
///
/// Local state (not managed by Riverpod):
/// - Debug panel visibility, view mode, FPS, particle count
///
/// Wind data comes from [sceneStateProvider] when available, falling back to
/// [WindData.zero()] while GPS fix is pending. Camera feed appears immediately.
class ARViewScreen extends ConsumerStatefulWidget {
  const ARViewScreen({super.key});

  @override
  ConsumerState<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends ConsumerState<ARViewScreen> {
  /// Current sky mask data, produced by the [HsvSkyDetector] from the provider.
  ///
  /// Starts empty (no sky) so particles don't render on a black screen
  /// before the camera feed initializes and sky detection runs.
  SkyMaskData _skyMaskData = SkyMaskData.noSky();

  /// Current sky fraction (0.0 to 1.0).
  double _skyFraction = 0;

  /// Whether the sky detector is calibrated.
  bool _isCalibrated = false;

  /// Cached wind data from the sceneStateProvider.
  ///
  /// Updated in build() from the composed SceneState. Falls back to
  /// WindData.zero() when SceneState is null (no GPS fix yet).
  WindData _windData = WindData.zero();

  /// Whether the debug panel is visible.
  ///
  /// Toggle with 3-finger tap or DBG button. Hidden by default.
  bool _showDebugPanel = false;

  /// Current FPS from ParticleOverlay (updated ~1/second).
  double _currentFps = 60.0;

  /// Current particle count (may be reduced by PerformanceManager).
  int _currentParticleCount = 2000;

  /// Current view mode for particle rendering.
  ///
  /// - dots: Traditional short line segments (default)
  /// - streamlines: Flowing trails with speed-based colors
  ViewMode _viewMode = ViewMode.dots;

  /// Handles camera frame updates for sky detection.
  ///
  /// Calls the underlying AutoCalibratingSkyDetector directly (sync, zero
  /// allocation) instead of going through HsvSkyDetector.detect() which
  /// allocates a new List<bool> + SkyMaskData Freezed object every frame.
  ///
  /// SkyMaskData is rebuilt from the cached mask after each frame (single
  /// array traversal, no per-cell method calls). setState only fires when
  /// sky fraction changes by >1% (for debug panel).
  void _onCameraFrame(CameraImage image) {
    final skyDetector = ref.read(skyDetectorInstanceProvider) as HsvSkyDetector;

    // Get current pitch from sensor notifiers
    final pitch = ref.read(sensorNotifiersProvider).pitch.value;

    // Call underlying detector directly: sync, zero allocation for detection
    skyDetector.updatePitchAndProcess(image, pitch);

    // Rebuild SkyMaskData from cached mask (single array copy, not 12K method calls)
    _skyMaskData = skyDetector.buildSkyMaskData();

    // Only setState when sky fraction changes meaningfully (for debug panel)
    final newFraction = skyDetector.skyFraction;
    final newCalibrated = skyDetector.isCalibrated;

    if ((newFraction - _skyFraction).abs() > 0.01 ||
        newCalibrated != _isCalibrated) {
      if (mounted) {
        setState(() {
          _skyFraction = newFraction;
          _isCalibrated = newCalibrated;
        });
      }
    }
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

  /// Handles altitude level changes from the slider.
  ///
  /// Updates the Riverpod [selectedAltitudeProvider] which will eventually
  /// trigger downstream wind data refetch when providers are fully wired.
  void _onAltitudeChanged(AltitudeLevel level) {
    ref.read(selectedAltitudeProvider.notifier).select(level);
  }

  @override
  Widget build(BuildContext context) {
    // Watch altitude from Riverpod (triggers rebuild on change)
    final altitudeLevel = ref.watch(selectedAltitudeProvider);

    // Watch sensor notifiers for heading/pitch values
    final sensorNotifiers = ref.watch(sensorNotifiersProvider);

    // Watch stable position for GPS display in debug panel
    final position = ref.watch(stablePositionProvider);

    // Watch sceneState for wind data (null while GPS/wind loading)
    final sceneState = ref.watch(sceneStateProvider);
    _windData = sceneState?.wind ?? WindData.zero();

    // Read heading/pitch from ValueNotifiers for non-particle widgets
    // (CompassWidget, DebugPanel). ParticleOverlay reads directly from
    // the notifiers at tick rate for zero-rebuild heading updates.
    final heading = sensorNotifiers.heading.value;
    final pitch = sensorNotifiers.pitch.value;

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
            // Layer 1: Camera feed as the base layer (always visible)
            CameraView(onFrame: _onCameraFrame),

            // Layer 2: Particle overlay for wind visualization
            // Uses headingNotifier for high-frequency heading updates
            // without triggering full widget rebuilds.
            ParticleOverlay(
              skyMask: _skyMaskData,
              windData: _windData,
              altitudeLevel: altitudeLevel,
              headingNotifier: sensorNotifiers.heading,
              pitchNotifier: sensorNotifiers.pitch,
              onFpsUpdate: _onFpsUpdate,
              viewMode: _viewMode,
              // Reduce particle count in streamlines mode for better performance
              particleCount: _viewMode == ViewMode.streamlines ? 1000 : 2000,
            ),

            // Layer 3: Debug panel (toggle button + conditionally visible panel)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: DebugPanel(
                heading: heading,
                pitch: pitch,
                skyFraction: _skyFraction,
                isCalibrated: _isCalibrated,
                altitudeLevel: altitudeLevel,
                windData: _windData,
                currentFps: _currentFps,
                currentParticleCount: _currentParticleCount,
                viewMode: _viewMode,
                showPanel: _showDebugPanel,
                onTogglePanel: _toggleDebugPanel,
                onToggleViewMode: _toggleViewMode,
                onRecalibrate: () {
                  final detector = ref.read(skyDetectorInstanceProvider) as HsvSkyDetector;
                  detector.forceRecalibrate();
                },
                latitude: position?.latitude,
                longitude: position?.longitude,
              ),
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
                    value: altitudeLevel,
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
                altitude: altitudeLevel,
              ),
            ),

            // Layer 7: Compass widget positioned above InfoBar
            Positioned(
              left: 16,
              bottom: bottomPadding + 92, // BUG-008: 16px margin + ~60px InfoBar height + 16px gap
              child: CompassWidget(heading: heading),
            ),

            // Layer 8: Data status bar (loading indicator)
            // Shown while GPS or wind data is resolving, hidden once ready.
            Positioned(
              top: MediaQuery.of(context).padding.top + 48,
              left: 0,
              right: 0,
              child: Center(
                child: DataStatusBar(
                  sceneState: sceneState,
                  hasPosition: position != null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
