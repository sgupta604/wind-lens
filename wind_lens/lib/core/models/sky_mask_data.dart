/// Method used to detect sky regions.
///
/// Different detection algorithms produce SkyMaskData with different methods:
/// - [hsv]: Auto-calibrating HSV color-based detection
/// - [terrain]: Terrain horizon profile-based detection
/// - [combined]: HSV + terrain combined detection
enum SkyDetectionMethod { hsv, terrain, combined }

/// Lightweight data class representing a sky detection mask.
///
/// NOT Freezed — this is a per-frame hot-path object (same category as
/// Particle and HSV). Freezed's immutability + equality checks would create
/// unnecessary allocation pressure at 30 FPS.
///
/// The [pixels] list is a row-major boolean array where `true` means "sky"
/// and `false` means "not sky". Dimensions are [width] x [height].
///
/// [skyFraction] is pre-computed at construction time to avoid iterating
/// 12,288 pixels on every access in the particle tick loop.
class SkyMaskData {
  /// Width of the mask in pixels.
  final int width;

  /// Height of the mask in pixels.
  final int height;

  /// Row-major boolean array: true = sky, false = not sky.
  /// Length must equal [width] * [height].
  final List<bool> pixels;

  /// The detection method that produced this mask.
  final SkyDetectionMethod method;

  /// Pre-computed sky fraction (0.0 to 1.0).
  /// Computed once at construction, not on every access.
  final double skyFraction;

  /// Creates a SkyMaskData with pre-computed sky fraction.
  SkyMaskData({
    required this.width,
    required this.height,
    required this.pixels,
    required this.method,
  }) : skyFraction = pixels.isEmpty
            ? 0.0
            : pixels.where((p) => p).length / pixels.length;

  /// Creates a full-sky mask where every pixel is sky.
  ///
  /// Useful as a fallback when no sky detection is available yet.
  /// Default dimensions match the AutoCalibratingSkyDetector (128x96).
  factory SkyMaskData.fullSky({int width = 128, int height = 96}) {
    return SkyMaskData(
      width: width,
      height: height,
      pixels: List.filled(width * height, true),
      method: SkyDetectionMethod.hsv,
    );
  }

  /// Creates an empty mask where no pixel is sky.
  ///
  /// Used as the initial state before sky detection has run,
  /// so particles don't render on a black screen before the camera starts.
  factory SkyMaskData.noSky({int width = 128, int height = 96}) {
    return SkyMaskData(
      width: width,
      height: height,
      pixels: List.filled(width * height, false),
      method: SkyDetectionMethod.hsv,
    );
  }

  /// Checks if a point (in normalized coordinates) is in the sky region.
  ///
  /// [normalizedX] and [normalizedY] are in the range 0.0 to 1.0, where
  /// (0,0) is the top-left corner and (1,1) is the bottom-right corner.
  ///
  /// Returns true if the pixel at the given coordinates is sky.
  bool isPointInSky(double normalizedX, double normalizedY) {
    // Clamp to valid range
    final clampedX = normalizedX.clamp(0.0, 0.999);
    final clampedY = normalizedY.clamp(0.0, 0.999);

    // Convert normalized coordinates to pixel indices
    final pixelX = (clampedX * width).floor();
    final pixelY = (clampedY * height).floor();
    final index = pixelY * width + pixelX;

    // Bounds check
    if (index < 0 || index >= pixels.length) return false;

    return pixels[index];
  }
}
