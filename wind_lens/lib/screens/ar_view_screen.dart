import 'dart:async';

import 'package:flutter/material.dart';

import '../models/compass_data.dart';
import '../services/compass_service.dart';
import '../services/sky_detection/pitch_based_sky_mask.dart';
import '../widgets/camera_view.dart';

/// The main AR view screen that displays the camera feed with compass overlay.
///
/// This screen provides a fullscreen camera preview with a black background,
/// designed for augmented reality wind visualization. It includes a debug overlay
/// showing current compass heading and device pitch values.
class ARViewScreen extends StatefulWidget {
  const ARViewScreen({super.key});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  /// The compass service for managing sensor data.
  late CompassService _compassService;

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

  @override
  void initState() {
    super.initState();
    _compassService = CompassService();
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
  void _onCompassUpdate(CompassData data) {
    setState(() {
      _heading = data.heading;
      _pitch = data.pitch;
      _skyMask.updatePitch(_pitch);
      _skyFraction = _skyMask.skyFraction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed as the base layer
          const CameraView(),

          // Debug overlay positioned at top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildDebugOverlay(),
          ),
        ],
      ),
    );
  }

  /// Builds the debug overlay widget showing heading and pitch values.
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
            'Heading: ${_heading.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pitch: ${_pitch.toStringAsFixed(1)}°',
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
        ],
      ),
    );
  }
}
