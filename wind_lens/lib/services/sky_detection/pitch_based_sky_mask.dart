import 'package:flutter/foundation.dart';

import 'sky_mask.dart';

/// Level 1 sky detection using device pitch angle.
///
/// This simple implementation assumes:
/// - When phone is tilted up (pitch > 10), top of screen is sky
/// - Sky fraction increases linearly from pitch 10 to 70
/// - Above 70, we're looking almost straight up (95% sky)
///
/// Pros: Dead simple, O(1), no image processing
/// Cons: Doesn't detect buildings/trees blocking sky
class PitchBasedSkyMask implements SkyMask {
  /// Minimum pitch (degrees) before any sky is visible.
  static const double _minPitch = 10.0;

  /// Maximum pitch (degrees) for full sky coverage.
  static const double _maxPitch = 70.0;

  /// Maximum sky fraction (never 100% to leave room for horizon).
  static const double _maxSkyFraction = 0.95;

  /// Current device pitch in degrees.
  double _pitch = 0;

  /// Updates the pitch value and logs the resulting sky fraction.
  ///
  /// Call this method when receiving new pitch data from the compass service.
  void updatePitch(double pitchDegrees) {
    _pitch = pitchDegrees;
    debugPrint('Sky fraction: ${(skyFraction * 100).toStringAsFixed(1)}%');
  }

  @override
  double get skyFraction {
    if (_pitch < _minPitch) return 0.0;
    if (_pitch > _maxPitch) return _maxSkyFraction;
    return ((_pitch - _minPitch) / (_maxPitch - _minPitch) * _maxSkyFraction)
        .clamp(0.0, _maxSkyFraction);
  }

  @override
  bool isPointInSky(double normalizedX, double normalizedY) {
    // Y=0 is top of screen, Y=1 is bottom
    // Point is in sky if it's above the sky/ground boundary
    // Note: normalizedX is ignored in pitch-based detection (uniform horizontal boundary)
    return normalizedY < skyFraction;
  }
}
