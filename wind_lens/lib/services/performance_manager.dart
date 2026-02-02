/// Adaptive performance manager for particle count optimization.
///
/// Monitors frame rate and automatically adjusts the particle count
/// to maintain smooth rendering. Uses a circular buffer of frame times
/// to calculate average FPS and adjusts particle count accordingly.
///
/// Performance adjustment rules:
/// - If avgFPS < 45: reduce particles to 70% (min 500)
/// - If avgFPS > 58: increase particles by 10% (max 2000)
/// - No change if FPS is between 45-58 (stable range)
///
/// Example:
/// ```dart
/// final manager = PerformanceManager();
///
/// // In animation tick:
/// manager.recordFrame(elapsed, lastElapsed);
/// final particleCount = manager.particleCount;
/// ```
class PerformanceManager {
  /// Current adaptive particle count.
  int _particleCount = 2000;

  /// Number of frames to average for FPS calculation.
  static const int _fpsWindowSize = 30;

  /// Circular buffer of recent FPS values for averaging.
  /// Pre-allocated with fixed size to avoid allocations in hot path.
  final List<double> _recentFps = List.filled(_fpsWindowSize, 0.0);

  /// Current index in the circular buffer.
  int _fpsIndex = 0;

  /// Number of FPS samples recorded (0 to _fpsWindowSize).
  int _fpsCount = 0;

  /// Running sum of FPS values for O(1) average calculation.
  double _fpsSum = 0.0;

  /// Most recent calculated FPS for display purposes.
  double _currentFps = 60.0;

  /// Minimum allowed particle count.
  static const int _minParticles = 500;

  /// Maximum allowed particle count.
  static const int _maxParticles = 2000;

  /// FPS threshold below which particles are reduced.
  static const double _lowFpsThreshold = 45.0;

  /// FPS threshold above which particles can be increased.
  static const double _highFpsThreshold = 58.0;

  /// Returns the current adaptive particle count.
  ///
  /// This value is automatically adjusted based on measured FPS.
  /// Use this value when creating/resizing particle pools.
  int get particleCount => _particleCount;

  /// Returns the current calculated FPS.
  ///
  /// This is the average FPS over the last [_fpsWindowSize] frames.
  /// Use this for debug display purposes.
  double get currentFps => _currentFps;

  /// Records a frame and updates FPS calculation.
  ///
  /// Should be called once per frame in the animation tick.
  /// [elapsed] is the total elapsed time since animation start.
  /// [lastElapsed] is the elapsed time from the previous frame.
  ///
  /// Example:
  /// ```dart
  /// void _onTick(Duration elapsed) {
  ///   manager.recordFrame(elapsed, _lastFrameTime);
  ///   _lastFrameTime = elapsed;
  /// }
  /// ```
  void recordFrame(Duration elapsed, Duration lastElapsed) {
    // Calculate frame duration
    final dt = elapsed - lastElapsed;

    // Calculate FPS from frame duration
    // Guard against zero/negative duration (default to 60 FPS)
    final fps = dt.inMicroseconds > 0
        ? 1000000 / dt.inMicroseconds
        : 60.0;

    // Clamp FPS to reasonable range (0-120)
    final clampedFps = fps.clamp(0.0, 120.0);

    // Circular buffer update with O(1) average calculation
    if (_fpsCount < _fpsWindowSize) {
      // Buffer not yet full - just add to next slot
      _recentFps[_fpsCount] = clampedFps;
      _fpsSum += clampedFps;
      _fpsCount++;
    } else {
      // Buffer full - remove oldest value from sum, add new value
      _fpsSum -= _recentFps[_fpsIndex];
      _recentFps[_fpsIndex] = clampedFps;
      _fpsSum += clampedFps;
      _fpsIndex = (_fpsIndex + 1) % _fpsWindowSize;
    }

    // O(1) average calculation
    _currentFps = _fpsCount > 0 ? _fpsSum / _fpsCount : 60.0;

    // Only adjust after we have a full window
    if (_fpsCount == _fpsWindowSize) {
      _adjustParticleCount();
    }
  }

  /// Adjusts particle count based on average FPS.
  ///
  /// - Below 45 FPS: reduce to 70% (aggressive reduction for performance)
  /// - Above 58 FPS: increase by 10% (gradual recovery)
  /// - Between 45-58: no change (stable operating range)
  void _adjustParticleCount() {
    if (_currentFps < _lowFpsThreshold && _particleCount > _minParticles) {
      // Performance struggling, reduce particles aggressively
      _particleCount = (_particleCount * 0.7).round().clamp(_minParticles, _maxParticles);
      // Reset circular buffer to avoid rapid-fire adjustments
      _resetBuffer();
    } else if (_currentFps > _highFpsThreshold && _particleCount < _maxParticles) {
      // Room for more particles, slowly increase
      _particleCount = (_particleCount * 1.1).round().clamp(_minParticles, _maxParticles);
      // Reset circular buffer to avoid rapid-fire adjustments
      _resetBuffer();
    }
    // If FPS is between 45-58, do nothing (stable range)
  }

  /// Resets the circular buffer without reallocating.
  void _resetBuffer() {
    _fpsIndex = 0;
    _fpsCount = 0;
    _fpsSum = 0.0;
  }

  /// Resets the manager to default values.
  ///
  /// Useful for testing or when restarting the animation.
  void reset() {
    _particleCount = 2000;
    _currentFps = 60.0;
    _resetBuffer();
  }
}
