import 'dart:async';

import 'package:flutter/material.dart';

import '../models/compass_data.dart';
import '../models/wind_data.dart';
import '../services/compass_service.dart';
import '../services/fake_wind_service.dart';
import '../services/sky_detection/pitch_based_sky_mask.dart';
import '../widgets/camera_view.dart';
import '../widgets/particle_overlay.dart';

/// The main AR view screen that displays the camera feed with wind visualization.
///
/// This screen provides a fullscreen camera preview with a black background,
/// designed for augmented reality wind visualization. It includes:
/// - Wind-driven particle animation
/// - World-fixed particle direction (adjusts for compass heading)
/// - Debug overlay showing heading, pitch, sky fraction, and wind data
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
  /// Updates heading, pitch, sky mask, and fetches new wind data.
  void _onCompassUpdate(CompassData data) {
    setState(() {
      _heading = data.heading;
      _pitch = data.pitch;
      _skyMask.updatePitch(_pitch);
      _skyFraction = _skyMask.skyFraction;

      // Update wind data on each compass update
      _windData = _windService.getWind();
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
          ),

          // Layer 3: Debug overlay positioned at top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildDebugOverlay(),
          ),
        ],
      ),
    );
  }

  /// Builds the debug overlay widget showing heading, pitch, sky, and wind values.
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
