import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/compass_data.dart';

/// Service for managing compass heading and device pitch using device sensors.
///
/// Uses a timer-based decoupled architecture where:
/// - **Sensor callbacks** only store the latest raw values (no processing)
/// - **A periodic timer at 20 Hz** smooths toward raw values and always emits
/// - **No dead zones** -- the low-pass filter itself provides jitter suppression
///
/// This architecture eliminates the convergence trap from the event-driven
/// dead zone approach (BUG-009). The timer always emits, so the stream never
/// goes silent after the smoothed value converges to the raw value.
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
  /// Smoothing factor for the low-pass filter (0.0 = no change, 1.0 = instant).
  /// 0.15 at 20 Hz provides smooth, responsive tracking.
  /// Raised from 0.1 to compensate for lower tick rate (20 Hz vs 50-100 Hz).
  static const double smoothingFactor = 0.15;

  /// Emission rate: 20 Hz (50ms interval). Matches typical UI refresh needs
  /// without overwhelming the widget tree with 50-100 Hz sensor data.
  static const Duration emitInterval = Duration(milliseconds: 50);

  // --- Internal state ---

  /// Latest raw heading from magnetometer (updated at sensor hardware rate).
  double _rawHeading = 0;

  /// Latest raw pitch from accelerometer (updated at sensor hardware rate).
  double _rawPitch = 0;

  /// Current smoothed heading (updated at timer rate).
  double _smoothedHeading = 0;

  /// Current smoothed pitch (updated at timer rate).
  double _smoothedPitch = 0;

  /// Subscription to magnetometer sensor events.
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;

  /// Subscription to accelerometer sensor events.
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  /// Periodic timer for smoothing and emission.
  Timer? _emitTimer;

  /// Stream controller for broadcasting compass updates.
  final _controller = StreamController<CompassData>.broadcast();

  // --- Public API ---

  /// Stream of [CompassData] updates.
  ///
  /// This is a broadcast stream, allowing multiple listeners.
  /// Emits at a fixed 20 Hz rate as long as the service is started.
  Stream<CompassData> get stream => _controller.stream;

  /// Current smoothed heading in degrees (0-360).
  double get heading => _smoothedHeading;

  /// Current smoothed pitch in degrees.
  double get pitch => _smoothedPitch;

  /// Starts listening to sensor events and begins the emission timer.
  ///
  /// Sensor callbacks only store raw values -- no smoothing, no emission.
  /// The periodic timer handles smoothing and emission at a fixed 20 Hz rate.
  ///
  /// Call [dispose] when done to release resources.
  void start() {
    _magnetometerSub = magnetometerEventStream().listen(
      (event) {
        // Only store raw heading -- no smoothing, no emission
        _rawHeading = (atan2(event.y, event.x) * 180 / pi + 360) % 360;
      },
      onError: (e) => debugPrint('Magnetometer error: $e'),
    );

    _accelerometerSub = accelerometerEventStream().listen(
      (event) {
        // Only store raw pitch -- no smoothing, no emission
        _rawPitch = atan2(-event.z, event.y) * 180 / pi;
      },
      onError: (e) => debugPrint('Accelerometer error: $e'),
    );

    // Fixed-rate timer: smooth toward raw values and always emit
    _emitTimer = Timer.periodic(emitInterval, (_) {
      _smoothedHeading =
          _lerpAngle(_smoothedHeading, _rawHeading, smoothingFactor);
      _smoothedPitch += (_rawPitch - _smoothedPitch) * smoothingFactor;

      _controller.add(CompassData(
        heading: _smoothedHeading,
        pitch: _smoothedPitch,
      ));
    });
  }

  /// Circular interpolation handling 0/360 wraparound correctly.
  ///
  /// Uses shortest-path angular interpolation:
  /// - 350 -> 10 interpolates clockwise through 0 (+20 degrees)
  /// - 10 -> 350 interpolates counterclockwise through 0 (-20 degrees)
  double _lerpAngle(double from, double to, double t) {
    double diff = (to - from + 540) % 360 - 180;
    return (from + diff * t + 360) % 360;
  }

  // --- Test helpers ---

  /// Directly sets the raw heading value for unit testing.
  ///
  /// Use with [tick] to test smoothing behavior without platform channels.
  @visibleForTesting
  void setRawHeading(double heading) {
    _rawHeading = heading;
  }

  /// Directly sets the raw pitch value for unit testing.
  ///
  /// Use with [tick] to test smoothing behavior without platform channels.
  @visibleForTesting
  void setRawPitch(double pitch) {
    _rawPitch = pitch;
  }

  /// Runs one cycle of smoothing + emission for unit testing.
  ///
  /// This is equivalent to one timer tick. Always emits a CompassData event.
  @visibleForTesting
  void tick() {
    _smoothedHeading =
        _lerpAngle(_smoothedHeading, _rawHeading, smoothingFactor);
    _smoothedPitch += (_rawPitch - _smoothedPitch) * smoothingFactor;

    _controller.add(CompassData(
      heading: _smoothedHeading,
      pitch: _smoothedPitch,
    ));
  }

  /// Simulates a magnetometer event with raw x and y magnetic field values.
  ///
  /// Computes raw heading from atan2(y, x), stores it, then runs one [tick].
  /// Backward-compatible with existing BUG-009 regression tests.
  @visibleForTesting
  void simulateMagnetometerEvent(double x, double y) {
    _rawHeading = (atan2(y, x) * 180 / pi + 360) % 360;
    tick();
  }

  /// Simulates an accelerometer event with raw y and z acceleration values.
  ///
  /// Computes raw pitch from atan2(-z, y), stores it, then runs one [tick].
  /// Backward-compatible with existing BUG-009 regression tests.
  @visibleForTesting
  void simulateAccelerometerEvent(double y, double z) {
    _rawPitch = atan2(-z, y) * 180 / pi;
    tick();
  }

  /// Releases resources and stops listening to sensor events.
  ///
  /// Cancels the emission timer, sensor subscriptions, and closes the stream.
  /// Always call this method when the service is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _emitTimer?.cancel();
    _magnetometerSub?.cancel();
    _accelerometerSub?.cancel();
    _controller.close();
  }
}
