import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/compass_data.dart';

/// Service for managing compass heading and device pitch using device sensors.
///
/// Uses the magnetometer for heading (compass direction) and accelerometer
/// for pitch (device tilt). Implements smoothing and dead zones to reduce
/// jitter when the device is stationary.
///
/// Usage:
/// ```dart
/// final compassService = CompassService();
/// compassService.start();
/// compassService.stream.listen((data) {
///   print('Heading: ${data.heading}, Pitch: ${data.pitch}');
/// });
/// // When done:
/// compassService.dispose();
/// ```
class CompassService {
  /// Smoothing factor for low-pass filter.
  /// Lower value = smoother but more lag.
  static const double smoothingFactor = 0.1;

  /// Dead zone threshold for heading changes in degrees.
  /// Changes smaller than this are ignored to prevent jitter.
  static const double headingDeadZone = 1.0;

  /// Dead zone threshold for pitch changes in degrees.
  /// Changes smaller than this are ignored to prevent jitter.
  static const double pitchDeadZone = 2.0;

  /// Current smoothed heading value (0-360 degrees from north).
  double _smoothedHeading = 0;

  /// Current smoothed pitch value (degrees of tilt).
  double _smoothedPitch = 0;

  /// Subscription to magnetometer sensor events.
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;

  /// Subscription to accelerometer sensor events.
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  /// Stream controller for broadcasting compass updates.
  final _controller = StreamController<CompassData>.broadcast();

  /// Stream of [CompassData] updates.
  ///
  /// This is a broadcast stream, allowing multiple listeners.
  /// Emits whenever heading or pitch changes beyond their dead zones.
  Stream<CompassData> get stream => _controller.stream;

  /// Current smoothed heading in degrees (0-360).
  double get heading => _smoothedHeading;

  /// Current smoothed pitch in degrees.
  double get pitch => _smoothedPitch;

  /// Starts listening to sensor events.
  ///
  /// Call this method to begin receiving compass updates.
  /// Remember to call [dispose] when done to release resources.
  void start() {
    _magnetometerSub = magnetometerEventStream().listen(_onMagnetometerEvent);
    _accelerometerSub = accelerometerEventStream().listen(_onAccelerometerEvent);
  }

  /// Handles magnetometer sensor events.
  ///
  /// Calculates heading from magnetic field x and y components,
  /// applies dead zone filtering and smoothing.
  void _onMagnetometerEvent(MagnetometerEvent event) {
    // Calculate raw heading from magnetometer data
    // atan2(y, x) gives angle in radians, convert to degrees
    double rawHeading = atan2(event.y, event.x) * 180 / pi;

    // Normalize to 0-360 range
    rawHeading = (rawHeading + 360) % 360;

    // Handle wraparound (e.g., 359 to 1 degrees)
    // Calculate the shortest delta around the circle
    double delta = rawHeading - _smoothedHeading;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    // Dead zone: ignore small changes to prevent jitter
    if (delta.abs() < headingDeadZone) {
      return;
    }

    // Apply smoothing filter
    _smoothedHeading = (_smoothedHeading + delta * smoothingFactor + 360) % 360;

    _emitUpdate();
  }

  /// Handles accelerometer sensor events.
  ///
  /// Calculates pitch from accelerometer z and y components,
  /// applies dead zone filtering and smoothing.
  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate raw pitch from accelerometer data
    // Using -z and y to get phone tilt angle
    // When phone is flat (screen up): z is negative (gravity), y is ~0
    // When phone is vertical: z is ~0, y is negative (gravity)
    double rawPitch = atan2(-event.z, event.y) * 180 / pi;

    // Calculate delta from current smoothed value
    double delta = rawPitch - _smoothedPitch;

    // Dead zone: ignore small changes to prevent jitter
    if (delta.abs() < pitchDeadZone) {
      return;
    }

    // Apply smoothing filter
    _smoothedPitch += delta * smoothingFactor;

    _emitUpdate();
  }

  /// Emits a compass update with current heading and pitch values.
  void _emitUpdate() {
    debugPrint(
      'Heading: ${_smoothedHeading.toStringAsFixed(1)}°, '
      'Pitch: ${_smoothedPitch.toStringAsFixed(1)}°',
    );

    _controller.add(CompassData(
      heading: _smoothedHeading,
      pitch: _smoothedPitch,
    ));
  }

  /// Releases resources and stops listening to sensor events.
  ///
  /// Always call this method when the service is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _magnetometerSub?.cancel();
    _accelerometerSub?.cancel();
    _controller.close();
  }
}
