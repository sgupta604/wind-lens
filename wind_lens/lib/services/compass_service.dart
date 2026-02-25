import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/compass_data.dart';

/// Service for managing compass heading and device pitch using device sensors.
///
/// Uses `flutter_compass` for heading (native OS compass API) and
/// `sensors_plus` accelerometer for pitch. Timer-based decoupled architecture:
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

  /// Raw pitch threshold (degrees) at which heading LOCKS.
  /// When |rawPitch| >= this value, heading freezes at the last stable value.
  /// Uses raw pitch (not smoothed) so the lock reacts instantly without lag.
  /// Device testing shows compass flips at ~42-47°, so lock before that.
  static const double headingLockPitch = 40.0;

  /// Raw pitch threshold (degrees) at which heading UNLOCKS (hysteresis).
  /// Heading stays locked until |rawPitch| drops below this value.
  /// The gap between lock (40) and unlock (30) prevents oscillation
  /// at the boundary from sensor noise.
  static const double headingUnlockPitch = 30.0;

  // --- Internal state ---

  /// Latest raw heading from magnetometer (updated at sensor hardware rate).
  double _rawHeading = 0;

  /// Latest raw pitch from accelerometer (updated at sensor hardware rate).
  double _rawPitch = 0;

  /// Current smoothed heading (updated at timer rate).
  double _smoothedHeading = 0;

  /// Current smoothed pitch (updated at timer rate).
  double _smoothedPitch = 0;

  /// Whether heading is currently locked due to high pitch (gimbal lock).
  /// Set to true when |rawPitch| >= [headingLockPitch], cleared when
  /// |rawPitch| < [headingUnlockPitch]. Hysteresis prevents oscillation.
  bool _isHeadingLocked = false;

  /// Last heading value from when pitch was comfortably below the lock
  /// threshold. Saved on every tick where heading is NOT locked, so that
  /// when the lock engages, we freeze at a heading from BEFORE any
  /// gimbal-lock contamination.
  double _lastStableHeading = 0;

  /// Subscription to native compass events (flutter_compass).
  StreamSubscription<CompassEvent>? _compassSub;

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

  /// Whether heading is currently locked due to gimbal lock (high pitch).
  ///
  /// Exposed for test observability. When true, heading is frozen at
  /// [_lastStableHeading] and ignores raw compass input.
  @visibleForTesting
  bool get isHeadingLocked => _isHeadingLocked;

  /// Starts listening to sensor events and begins the emission timer.
  ///
  /// Sensor callbacks only store raw values -- no smoothing, no emission.
  /// The periodic timer handles smoothing and emission at a fixed 20 Hz rate.
  ///
  /// Call [dispose] when done to release resources.
  void start() {
    _compassSub = FlutterCompass.events?.listen(
      (event) {
        // Only store raw heading if valid -- null heading retains previous value
        if (event.heading != null) {
          _rawHeading = event.heading!;
        }
      },
      onError: (e) => debugPrint('Compass error: $e'),
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
      // Smooth pitch -- pitch itself has no gimbal lock issue
      _smoothedPitch += (_rawPitch - _smoothedPitch) * smoothingFactor;

      // Gimbal lock mitigation v2: hysteresis-based heading lock.
      // Uses RAW pitch (not smoothed) for instant reaction -- smoothed pitch
      // lags behind, so by the time it crosses the threshold the heading
      // may have already chased the flipped value.
      // Only locks for positive pitch (tilting up toward sky). Negative pitch
      // (tilting down) is irrelevant — no sky to render particles on.
      if (!_isHeadingLocked && _rawPitch >= headingLockPitch) {
        // LOCK: save the PREVIOUS tick's heading (before any flip contamination)
        _isHeadingLocked = true;
        _smoothedHeading = _lastStableHeading;
      } else if (_isHeadingLocked && _rawPitch < headingUnlockPitch) {
        // UNLOCK: resume normal tracking
        _isHeadingLocked = false;
      }

      if (_isHeadingLocked) {
        // Heading frozen -- don't update _smoothedHeading
      } else {
        // Normal heading tracking
        _smoothedHeading =
            _lerpAngle(_smoothedHeading, _rawHeading, smoothingFactor);
        // Save as the last known-good heading for potential future lock
        _lastStableHeading = _smoothedHeading;
      }

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
  /// Logic MUST be identical to the timer callback body.
  @visibleForTesting
  void tick() {
    // Smooth pitch -- pitch itself has no gimbal lock issue
    _smoothedPitch += (_rawPitch - _smoothedPitch) * smoothingFactor;

    // Gimbal lock mitigation v2: hysteresis-based heading lock.
    // Uses RAW pitch for instant reaction (see timer callback for rationale).
    // Only positive pitch (tilting up) — negative pitch irrelevant for sky app.
    if (!_isHeadingLocked && _rawPitch >= headingLockPitch) {
      // LOCK: save the PREVIOUS tick's heading (before any flip contamination)
      _isHeadingLocked = true;
      _smoothedHeading = _lastStableHeading;
    } else if (_isHeadingLocked && _rawPitch < headingUnlockPitch) {
      // UNLOCK: resume normal tracking
      _isHeadingLocked = false;
    }

    if (_isHeadingLocked) {
      // Heading frozen -- don't update _smoothedHeading
    } else {
      // Normal heading tracking
      _smoothedHeading =
          _lerpAngle(_smoothedHeading, _rawHeading, smoothingFactor);
      // Save as the last known-good heading for potential future lock
      _lastStableHeading = _smoothedHeading;
    }

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
    _compassSub?.cancel();
    _accelerometerSub?.cancel();
    _controller.close();
  }
}
