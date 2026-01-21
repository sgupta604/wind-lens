/// Represents a color in HSV (Hue, Saturation, Value) color space.
///
/// HSV is used for sky detection because it separates color information (hue)
/// from brightness (value), making it more robust to lighting changes than RGB.
///
/// - [h] Hue: 0-360 degrees (0=red, 120=green, 240=blue)
/// - [s] Saturation: 0.0-1.0 (0=gray, 1=pure color)
/// - [v] Value/Brightness: 0.0-1.0 (0=black, 1=brightest)
class HSV {
  /// Hue in degrees (0-360).
  final double h;

  /// Saturation (0.0-1.0).
  final double s;

  /// Value/Brightness (0.0-1.0).
  final double v;

  /// Creates an HSV color with the given [h]ue, [s]aturation, and [v]alue.
  const HSV(this.h, this.s, this.v);

  @override
  String toString() => 'HSV(h: ${h.toStringAsFixed(1)}, s: ${s.toStringAsFixed(2)}, v: ${v.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HSV &&
          runtimeType == other.runtimeType &&
          h == other.h &&
          s == other.s &&
          v == other.v;

  @override
  int get hashCode => h.hashCode ^ s.hashCode ^ v.hashCode;
}
