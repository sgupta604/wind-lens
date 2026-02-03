import 'dart:ui';

/// Utility class for wind speed-based color calculations.
///
/// Provides color gradients based on wind speed (m/s) for streamline visualization.
/// Colors follow the Windy.com style gradient:
/// - Blue (calm) -> Cyan -> Green -> Yellow -> Orange -> Red -> Purple (extreme)
///
/// Example:
/// ```dart
/// final color = WindColors.getSpeedColor(15); // Green-ish
/// final colorWithAlpha = WindColors.getSpeedColorWithOpacity(15, 0.7);
/// ```
class WindColors {
  // Private constructor to prevent instantiation
  WindColors._();

  // Color constants from spec (Windy.com style)
  static const Color _blue = Color(0xFF3B82F6);   // 0-5 m/s
  static const Color _cyan = Color(0xFF06B6D4);   // 5-10 m/s
  static const Color _green = Color(0xFF22C55E);  // 10-20 m/s
  static const Color _yellow = Color(0xFFEAB308); // 20-35 m/s
  static const Color _orange = Color(0xFFF97316); // 35-50 m/s
  static const Color _red = Color(0xFFEF4444);    // 50+ m/s
  static const Color _purple = Color(0xFFA855F7); // 100+ m/s (extreme)

  /// The color for low/calm wind speeds (blue).
  static const Color lowSpeedColor = _blue;

  /// The color for extreme wind speeds (purple).
  static const Color highSpeedColor = _purple;

  /// Returns a color for the given wind speed in meters per second.
  ///
  /// Speed ranges and their colors:
  /// - < 5 m/s: Blue (#3B82F6)
  /// - 5-10 m/s: Blue -> Cyan interpolation
  /// - 10-20 m/s: Cyan -> Green interpolation
  /// - 20-35 m/s: Green -> Yellow interpolation
  /// - 35-50 m/s: Yellow -> Orange interpolation
  /// - 50-100 m/s: Orange -> Red -> Purple interpolation
  /// - > 100 m/s: Purple (clamped)
  ///
  /// Negative speeds return blue (same as calm winds).
  static Color getSpeedColor(double speedMs) {
    // Handle negative or very low speeds
    if (speedMs < 5) {
      return _blue;
    }

    // 5-10 m/s: Blue -> Cyan
    if (speedMs < 10) {
      final t = (speedMs - 5) / 5;
      return Color.lerp(_blue, _cyan, t)!;
    }

    // 10-20 m/s: Cyan -> Green
    if (speedMs < 20) {
      final t = (speedMs - 10) / 10;
      return Color.lerp(_cyan, _green, t)!;
    }

    // 20-35 m/s: Green -> Yellow
    if (speedMs < 35) {
      final t = (speedMs - 20) / 15;
      return Color.lerp(_green, _yellow, t)!;
    }

    // 35-50 m/s: Yellow -> Orange
    if (speedMs < 50) {
      final t = (speedMs - 35) / 15;
      return Color.lerp(_yellow, _orange, t)!;
    }

    // 50-100 m/s: Orange -> Red -> Purple
    if (speedMs < 100) {
      final t = (speedMs - 50) / 50;
      // First half: Orange -> Red, Second half: Red -> Purple
      if (t < 0.5) {
        return Color.lerp(_orange, _red, t * 2)!;
      } else {
        return Color.lerp(_red, _purple, (t - 0.5) * 2)!;
      }
    }

    // 100+ m/s: Purple (clamped)
    return _purple;
  }

  /// Returns a color for the given wind speed with specified opacity.
  ///
  /// Opacity is clamped to [0.0, 1.0] range.
  /// This is useful for trail fade effects where older trail points
  /// should be more transparent.
  static Color getSpeedColorWithOpacity(double speedMs, double opacity) {
    final color = getSpeedColor(speedMs);
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    return color.withValues(alpha: clampedOpacity);
  }
}
