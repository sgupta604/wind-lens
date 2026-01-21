/// Abstract interface for sky detection implementations.
///
/// The SkyMask determines which portions of the screen represent sky
/// where wind particles should be rendered. Different implementations
/// can use various detection methods (pitch-based, color-based, ML).
///
/// This is the Strategy pattern - ARViewScreen depends on the abstract
/// SkyMask interface, allowing different detection algorithms to be
/// swapped without changing the screen code.
abstract class SkyMask {
  /// Returns what fraction of screen (from top) is sky.
  ///
  /// Value range: 0.0 (no sky visible) to 1.0 (entire screen is sky).
  /// Note: Typically capped at 0.95 to always leave some ground.
  double get skyFraction;

  /// Check if a normalized screen point is in the sky region.
  ///
  /// Parameters:
  /// - [normalizedX]: 0.0 = left edge, 1.0 = right edge
  /// - [normalizedY]: 0.0 = top edge, 1.0 = bottom edge
  ///
  /// Returns true if the point should display particles.
  bool isPointInSky(double normalizedX, double normalizedY);
}
