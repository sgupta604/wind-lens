import 'dart:async';

import 'package:flutter/material.dart';

import '../models/altitude_level.dart';
import '../models/compass_data.dart';
import '../models/wind_data.dart';
import '../services/compass_service.dart';
import '../services/fake_wind_service.dart';
import '../services/sky_detection/pitch_based_sky_mask.dart';
import '../widgets/altitude_slider.dart';
import '../widgets/camera_view.dart';
import '../widgets/particle_overlay.dart';

/// The main AR view screen that displays the camera feed with wind visualization.
///
/// This screen provides a fullscreen camera preview with a black background,
/// designed for augmented reality wind visualization. It includes:
/// - Wind-driven particle animation
/// - World-fixed particle direction (adjusts for compass heading)
/// - Altitude selection with visual depth effects (parallax)
/// - Debug overlay showing heading, pitch, sky fraction, altitude, and wind data
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

  /// The sky mask for determining sky regions based on device pitch.
  late PitchBasedSkyMask _skyMask;

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

  @override
  void initState() {
    super.initState();
    _compassService = CompassService();
    _windService = FakeWindService();
    _skyMask = PitchBasedSkyMask();
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
  /// Updates heading, pitch, sky mask, and fetches altitude-specific wind data.
  /// Stores previous heading before update for parallax calculation.
  void _onCompassUpdate(CompassData data) {
    setState(() {
      // Store previous heading BEFORE updating for parallax calculation
      _previousHeading = _heading;

      _heading = data.heading;
      _pitch = data.pitch;
      _skyMask.updatePitch(_pitch);
      _skyFraction = _skyMask.skyFraction;

      // Update wind data for current altitude level
      _windData = _windService.getWindForAltitude(_altitudeLevel);
    });
  }

  /// Handles altitude level changes from the slider.
  void _onAltitudeChanged(AltitudeLevel level) {
    setState(() {
      _altitudeLevel = level;
      // Immediately update wind data for the new altitude
      _windData = _windService.getWindForAltitude(_altitudeLevel);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: Camera feed as the base layer
          const CameraView(),

          // Layer 2: Particle overlay for wind visualization
          ParticleOverlay(
            skyMask: _skyMask,
            windData: _windData,
            compassHeading: _heading,
            altitudeLevel: _altitudeLevel,
            previousHeading: _previousHeading,
          ),

          // Layer 3: Debug overlay positioned at top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildDebugOverlay(),
          ),

          // Layer 4: Altitude slider positioned at right edge, vertically centered
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: AltitudeSlider(
                value: _altitudeLevel,
                onChanged: _onAltitudeChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the debug overlay widget showing heading, pitch, sky, altitude, and wind values.
  Widget _buildDebugOverlay() {
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
          Text(
            'Heading: ${_heading.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pitch: ${_pitch.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sky: ${(_skyFraction * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Altitude: ${_altitudeLevel.displayName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wind: ${_windData.speed.toStringAsFixed(1)}m/s @ ${_windData.directionDegrees.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
