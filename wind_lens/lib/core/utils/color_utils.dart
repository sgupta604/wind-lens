import 'dart:math' as math;
import '../models/hsv.dart';

/// Reusable RGB color values to avoid List allocation.
///
/// Used by [ColorUtils.yuvToRgb] to return RGB values without creating
/// a new List on each call. This is critical for performance when
/// processing many pixels per frame.
class RGB {
  /// Red component (0-255).
  int r;

  /// Green component (0-255).
  int g;

  /// Blue component (0-255).
  int b;

  /// Creates an RGB instance with optional initial values.
  RGB([this.r = 0, this.g = 0, this.b = 0]);
}

/// Utility functions for color conversion and image processing.
///
/// Provides platform-independent color space conversions used by sky detection.
class ColorUtils {
  ColorUtils._(); // Private constructor - static methods only

  /// Pre-allocated RGB result to avoid allocation in hot path.
  static final RGB _rgbResult = RGB();

  /// Converts RGB color values to HSV color space.
  ///
  /// Parameters:
  /// - [r] Red component (0-255)
  /// - [g] Green component (0-255)
  /// - [b] Blue component (0-255)
  ///
  /// Returns [HSV] with:
  /// - h: Hue in degrees (0-360)
  /// - s: Saturation (0.0-1.0)
  /// - v: Value/Brightness (0.0-1.0)
  ///
  /// Uses the standard RGB to HSV conversion algorithm.
  static HSV rgbToHsv(int r, int g, int b) {
    // Normalize RGB to 0.0-1.0 range
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final maxVal = math.max(rf, math.max(gf, bf));
    final minVal = math.min(rf, math.min(gf, bf));
    final delta = maxVal - minVal;

    // Calculate hue
    double h;
    if (delta == 0) {
      // Achromatic (gray) - hue is undefined, use 0
      h = 0;
    } else if (maxVal == rf) {
      // Red is dominant
      h = 60 * (((gf - bf) / delta) % 6);
    } else if (maxVal == gf) {
      // Green is dominant
      h = 60 * (((bf - rf) / delta) + 2);
    } else {
      // Blue is dominant
      h = 60 * (((rf - gf) / delta) + 4);
    }

    // Handle negative hue (wrap around to positive)
    if (h < 0) h += 360;

    // Calculate saturation
    final s = maxVal == 0 ? 0.0 : delta / maxVal;

    // Value is simply the max component
    final v = maxVal;

    return HSV(h, s, v);
  }

  /// Converts YUV420 color values to RGB.
  ///
  /// Parameters:
  /// - [y] Luminance (0-255)
  /// - [u] U chrominance (0-255, centered at 128)
  /// - [v] V chrominance (0-255, centered at 128)
  ///
  /// Returns a reusable [RGB] instance with the converted values.
  /// **WARNING:** The returned instance is shared and will be overwritten
  /// on the next call. Copy values immediately if needed.
  ///
  /// Used for Android camera image format conversion.
  static RGB yuvToRgb(int y, int u, int v) {
    // Standard YUV to RGB conversion (BT.601)
    // U and V are centered at 128
    final yf = y.toDouble();
    final uf = u - 128;
    final vf = v - 128;

    // Calculate and clamp RGB values, storing in pre-allocated result
    _rgbResult.r = (yf + 1.402 * vf).round().clamp(0, 255);
    _rgbResult.g = (yf - 0.344 * uf - 0.714 * vf).round().clamp(0, 255);
    _rgbResult.b = (yf + 1.772 * uf).round().clamp(0, 255);

    return _rgbResult;
  }
}
