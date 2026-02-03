import 'dart:math';
import 'dart:typed_data';

/// A single particle for the wind visualization system.
///
/// Particles use normalized coordinates (0.0 to 1.0) for screen-size independence.
/// The particle is designed to be mutable for in-place updates to avoid
/// garbage collection pressure in the render loop.
///
/// For streamline mode, the particle stores a circular buffer of trail positions
/// using pre-allocated Float32Lists to avoid allocations during animation.
///
/// Lifecycle:
/// - Created with initial position and age
/// - Updated each frame (age increments, position moves with wind)
/// - In streamlines mode: trail points recorded via [recordTrailPoint()]
/// - Reset when expired (age >= 1.0) or moves off-screen
/// - Trail cleared on reset via [resetTrail()]
class Particle {
  /// Maximum number of trail points stored per particle.
  ///
  /// This value (30) provides smooth curves for jet stream trails
  /// while keeping memory usage reasonable (~240 bytes per particle).
  static const int maxTrailPoints = 30;

  /// Normalized X position (0.0 = left edge, 1.0 = right edge).
  double x;

  /// Normalized Y position (0.0 = top edge, 1.0 = bottom edge).
  double y;

  /// Age from 0.0 (birth) to 1.0 (death).
  ///
  /// Used for fade in/out effects. Particle expires when age >= 1.0.
  double age;

  /// Trail length in screen pixels.
  ///
  /// Determines the length of the particle trail based on wind speed.
  double trailLength;

  /// Current wind speed in m/s.
  ///
  /// Used for color calculation in streamlines mode.
  double speed;

  /// Circular buffer of X coordinates for trail history.
  ///
  /// Pre-allocated to [maxTrailPoints] to avoid GC pressure.
  /// Access via [trailHead] and [trailCount] for circular buffer logic.
  final Float32List trailX;

  /// Circular buffer of Y coordinates for trail history.
  ///
  /// Pre-allocated to [maxTrailPoints] to avoid GC pressure.
  /// Access via [trailHead] and [trailCount] for circular buffer logic.
  final Float32List trailY;

  /// Current head index in the circular trail buffer.
  ///
  /// Points to the next write position. Wraps at [maxTrailPoints].
  int trailHead;

  /// Number of valid points in the trail buffer.
  ///
  /// Ranges from 0 to [maxTrailPoints]. Use this to know how many
  /// points to read from the buffer.
  int trailCount;

  /// Creates a new particle with the given parameters.
  ///
  /// All parameters have defaults, making it easy to create particles
  /// for the pre-allocated pool. Trail buffers are pre-allocated.
  Particle({
    this.x = 0,
    this.y = 0,
    this.age = 0,
    this.trailLength = 10,
    this.speed = 0.0,
  })  : trailX = Float32List(maxTrailPoints),
        trailY = Float32List(maxTrailPoints),
        trailHead = 0,
        trailCount = 0;

  /// Records the current position in the trail buffer.
  ///
  /// Call this each frame in streamlines mode to build up the trail.
  /// Uses a circular buffer, so old points are automatically overwritten.
  ///
  /// Performance: O(1), no allocations.
  void recordTrailPoint() {
    trailX[trailHead] = x;
    trailY[trailHead] = y;
    trailHead = (trailHead + 1) % maxTrailPoints;
    if (trailCount < maxTrailPoints) {
      trailCount++;
    }
  }

  /// Resets the trail buffer to empty state.
  ///
  /// Call this when recycling a particle to clear its trail history.
  /// Does not deallocate memory - just resets head and count.
  void resetTrail() {
    trailHead = 0;
    trailCount = 0;
  }

  /// Resets the particle to a random position with zero age.
  ///
  /// This method is used to recycle expired particles instead of creating
  /// new ones, which is critical for avoiding GC stutter in the render loop.
  ///
  /// Also clears the trail history via [resetTrail()].
  ///
  /// The [random] parameter should be a persistent Random instance
  /// (not created per-call) for better performance.
  void reset(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    age = 0.0;
    resetTrail();
  }

  /// Returns true if the particle has completed its lifecycle.
  ///
  /// Expired particles should be reset via [reset()] to avoid
  /// creating new particle objects.
  bool get isExpired => age >= 1.0;
}
