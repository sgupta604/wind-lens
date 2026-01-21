import 'dart:math';

import '../models/altitude_level.dart';
import '../models/wind_data.dart';

/// A service that provides simulated wind data for development and testing.
///
/// This service generates time-varying wind data using sinusoidal functions
/// to create realistic-looking wind patterns without requiring a real API.
///
/// The wind data simulates surface-level conditions (10m altitude) with
/// gentle variations typical of a light breeze (1-6 m/s range).
///
/// Example:
/// ```dart
/// final service = FakeWindService();
/// final wind = service.getWind();
/// print('Wind: ${wind.speed.toStringAsFixed(1)} m/s @ ${wind.directionDegrees.toStringAsFixed(0)}');
/// ```
class FakeWindService {
  /// Gets the current simulated wind data.
  ///
  /// Returns [WindData] with:
  /// - u-component: 1-5 m/s (oscillates with time)
  /// - v-component: 0.5-3.5 m/s (oscillates with time)
  /// - altitude: 10m (surface level)
  /// - timestamp: current time
  ///
  /// The wind varies smoothly over time using sine/cosine functions
  /// with different frequencies to create natural-looking patterns.
  WindData getWind() {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;

    // Calculate u-component: 3.0 + sin(time * 0.1) * 2.0 = range [1, 5] m/s
    final u = 3.0 + sin(time * 0.1) * 2.0;

    // Calculate v-component: 2.0 + cos(time * 0.15) * 1.5 = range [0.5, 3.5] m/s
    final v = 2.0 + cos(time * 0.15) * 1.5;

    final wind = WindData(
      uComponent: u,
      vComponent: v,
      altitude: 10,
      timestamp: DateTime.now(),
    );

    // Debug logging for verification
    debugPrint(
        'Wind: ${wind.speed.toStringAsFixed(1)}m/s @ ${wind.directionDegrees.toStringAsFixed(0)}deg');

    return wind;
  }

  /// Gets simulated wind data for a specific altitude level.
  ///
  /// Returns [WindData] with wind speed multiplied by the altitude's
  /// speed multiplier, simulating the stronger winds at higher altitudes.
  ///
  /// - Surface: ~3-6 m/s (base speed)
  /// - Mid-level: ~4.5-9 m/s (1.5x multiplier)
  /// - Jet Stream: ~9-18 m/s (3.0x multiplier)
  ///
  /// The altitude value in the returned WindData is set to the altitude
  /// level's meters AGL value.
  ///
  /// Example:
  /// ```dart
  /// final service = FakeWindService();
  /// final wind = service.getWindForAltitude(AltitudeLevel.jetStream);
  /// print('Jet stream wind: ${wind.speed.toStringAsFixed(1)} m/s at ${wind.altitude}m');
  /// ```
  WindData getWindForAltitude(AltitudeLevel level) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;

    // Calculate base u-component: 3.0 + sin(time * 0.1) * 2.0 = range [1, 5] m/s
    final baseU = 3.0 + sin(time * 0.1) * 2.0;

    // Calculate base v-component: 2.0 + cos(time * 0.15) * 1.5 = range [0.5, 3.5] m/s
    final baseV = 2.0 + cos(time * 0.15) * 1.5;

    // Apply altitude speed multiplier
    final multiplier = level.particleSpeedMultiplier;
    final u = baseU * multiplier;
    final v = baseV * multiplier;

    final wind = WindData(
      uComponent: u,
      vComponent: v,
      altitude: level.metersAGL,
      timestamp: DateTime.now(),
    );

    // Debug logging for verification
    debugPrint(
        'Wind (${level.displayName}): ${wind.speed.toStringAsFixed(1)}m/s @ ${wind.directionDegrees.toStringAsFixed(0)}deg at ${wind.altitude}m');

    return wind;
  }
}

/// Debug print function (only prints in debug mode).
void debugPrint(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
