import 'dart:math';

/// A single particle for the wind visualization system.
///
/// Particles use normalized coordinates (0.0 to 1.0) for screen-size independence.
/// The particle is designed to be mutable for in-place updates to avoid
/// garbage collection pressure in the render loop.
///
/// Lifecycle:
/// - Created with initial position and age
/// - Updated each frame (age increments, position moves with wind)
/// - Reset when expired (age >= 1.0) or moves off-screen
class Particle {
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

  /// Creates a new particle with the given parameters.
  ///
  /// All parameters have defaults, making it easy to create particles
  /// for the pre-allocated pool.
  Particle({
    this.x = 0,
    this.y = 0,
    this.age = 0,
    this.trailLength = 10,
  });

  /// Resets the particle to a random position with zero age.
  ///
  /// This method is used to recycle expired particles instead of creating
  /// new ones, which is critical for avoiding GC stutter in the render loop.
  ///
  /// The [random] parameter should be a persistent Random instance
  /// (not created per-call) for better performance.
  void reset(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    age = 0.0;
  }

  /// Returns true if the particle has completed its lifecycle.
  ///
  /// Expired particles should be reset via [reset()] to avoid
  /// creating new particle objects.
  bool get isExpired => age >= 1.0;
}
