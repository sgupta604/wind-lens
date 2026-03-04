import 'dart:ui';

/// Represents different altitude levels for wind visualization.
///
/// Each altitude level has distinct visual properties for particle rendering.
/// The 6 levels correspond to standard meteorological pressure surfaces:
///
/// - Surface (10m): Close-up view with fast-moving white particles
/// - 850 hPa (1,500m): Lower troposphere with cyan particles
/// - 700 hPa (3,000m): Mid troposphere with blue particles
/// - 500 hPa (5,500m): Upper-mid troposphere with violet particles
/// - 300 hPa (9,000m): Upper troposphere with magenta particles
/// - 250 hPa (10,500m): Jet stream level with purple particles
///
/// Example:
/// ```dart
/// final level = AltitudeLevel.midLevel;
/// print(level.displayName);           // "850 hPa"
/// print(level.metersAGL);             // 1500.0
/// print(level.particleSpeedMultiplier); // 1.5
/// ```
enum AltitudeLevel {
  /// Surface level (10m AGL).
  ///
  /// Close-up view with maximum parallax effect and white particles.
  surface,

  /// 850 hPa pressure level (~1,500m AGL).
  ///
  /// Lower troposphere with cyan-colored particles.
  midLevel,

  /// 700 hPa pressure level (~3,000m AGL).
  ///
  /// Mid troposphere with blue-colored particles.
  level700,

  /// 500 hPa pressure level (~5,500m AGL).
  ///
  /// Upper-mid troposphere with violet-colored particles.
  level500,

  /// 300 hPa pressure level (~9,000m AGL).
  ///
  /// Upper troposphere with magenta-colored particles.
  level300,

  /// 250 hPa / Jet stream level (~10,500m AGL).
  ///
  /// Far view with minimal parallax and purple particles.
  jetStream,
}

/// Extension providing visual and physical properties for each altitude level.
extension AltitudeLevelProperties on AltitudeLevel {
  /// Human-readable display name for the altitude level.
  ///
  /// - surface: "Surface"
  /// - midLevel: "850 hPa"
  /// - level700: "700 hPa"
  /// - level500: "500 hPa"
  /// - level300: "300 hPa"
  /// - jetStream: "250 hPa"
  String get displayName => switch (this) {
        AltitudeLevel.surface => 'Surface',
        AltitudeLevel.midLevel => '850 hPa',
        AltitudeLevel.level700 => '700 hPa',
        AltitudeLevel.level500 => '500 hPa',
        AltitudeLevel.level300 => '300 hPa',
        AltitudeLevel.jetStream => '250 hPa',
      };

  /// Altitude in meters above ground level (AGL).
  ///
  /// - surface: 10m
  /// - midLevel: 1,500m (850 hPa pressure level)
  /// - level700: 3,000m (700 hPa pressure level)
  /// - level500: 5,500m (500 hPa pressure level)
  /// - level300: 9,000m (300 hPa pressure level)
  /// - jetStream: 10,500m (250 hPa pressure level)
  double get metersAGL => switch (this) {
        AltitudeLevel.surface => 10.0,
        AltitudeLevel.midLevel => 1500.0,
        AltitudeLevel.level700 => 3000.0,
        AltitudeLevel.level500 => 5500.0,
        AltitudeLevel.level300 => 9000.0,
        AltitudeLevel.jetStream => 10500.0,
      };

  /// Color used to render particles at this altitude.
  ///
  /// All colors have alpha 0xAA (170/255 = 67% opacity) for visibility
  /// against sky backgrounds while maintaining translucency.
  ///
  /// Colors form a spectral gradient from low to high altitude:
  /// - surface: Ghostly white (0xAAFFFFFF)
  /// - midLevel: Cyan (0xAA00DDFF)
  /// - level700: Blue (0xAA00AAFF)
  /// - level500: Violet (0xAA8855FF)
  /// - level300: Magenta (0xAABB33FF)
  /// - jetStream: Purple (0xAADD00FF)
  Color get particleColor => switch (this) {
        AltitudeLevel.surface => const Color(0xAAFFFFFF),
        AltitudeLevel.midLevel => const Color(0xAA00DDFF),
        AltitudeLevel.level700 => const Color(0xAA00AAFF),
        AltitudeLevel.level500 => const Color(0xAA8855FF),
        AltitudeLevel.level300 => const Color(0xAABB33FF),
        AltitudeLevel.jetStream => const Color(0xAADD00FF),
      };

  /// Multiplier for wind speed at this altitude.
  ///
  /// Higher altitudes typically have stronger winds:
  /// - surface: 1.0x (baseline speed)
  /// - midLevel: 1.5x
  /// - level700: 1.8x
  /// - level500: 2.2x
  /// - level300: 2.7x
  /// - jetStream: 3.0x (3x faster)
  double get particleSpeedMultiplier => switch (this) {
        AltitudeLevel.surface => 1.0,
        AltitudeLevel.midLevel => 1.5,
        AltitudeLevel.level700 => 1.8,
        AltitudeLevel.level500 => 2.2,
        AltitudeLevel.level300 => 2.7,
        AltitudeLevel.jetStream => 3.0,
      };

  /// Parallax factor for potential depth effects.
  ///
  /// NOTE: As of BUG-004 fix, this factor is NO LONGER used for world anchoring.
  /// All altitude levels now use 100% world anchoring (particles stay fixed in
  /// real-world space when phone rotates).
  ///
  /// Depth perception is achieved through other visual properties:
  /// - Particle color: white -> cyan -> blue -> violet -> magenta -> purple
  /// - Trail scale: 1.0 -> 0.5 (shorter = further)
  /// - Speed multiplier: 1.0x -> 3.0x (faster at altitude)
  ///
  /// Values retained for potential future subtle parallax enhancement:
  /// - surface: 1.0
  /// - midLevel: 0.6
  /// - level700: 0.5
  /// - level500: 0.4
  /// - level300: 0.35
  /// - jetStream: 0.3
  double get parallaxFactor => switch (this) {
        AltitudeLevel.surface => 1.0,
        AltitudeLevel.midLevel => 0.6,
        AltitudeLevel.level700 => 0.5,
        AltitudeLevel.level500 => 0.4,
        AltitudeLevel.level300 => 0.35,
        AltitudeLevel.jetStream => 0.3,
      };

  /// Scale factor for particle trail length.
  ///
  /// Smaller values create shorter trails, making particles appear further away.
  /// - surface: 1.0 (full-size trails)
  /// - midLevel: 0.7 (70% of full size)
  /// - level700: 0.65
  /// - level500: 0.6
  /// - level300: 0.55
  /// - jetStream: 0.5 (50% of full size)
  ///
  /// This perspective scaling reinforces the depth illusion.
  double get trailScale => switch (this) {
        AltitudeLevel.surface => 1.0,
        AltitudeLevel.midLevel => 0.7,
        AltitudeLevel.level700 => 0.65,
        AltitudeLevel.level500 => 0.6,
        AltitudeLevel.level300 => 0.55,
        AltitudeLevel.jetStream => 0.5,
      };

  /// Number of trail points to use for streamlines rendering.
  ///
  /// Higher altitudes use more trail points for longer, more dramatic streamlines:
  /// - surface: 12 points (shorter trails, ~4-6% screen width)
  /// - midLevel: 18 points
  /// - level700: 20 points
  /// - level500: 22 points
  /// - level300: 24 points
  /// - jetStream: 25 points (long trails, ~15-20% screen width)
  ///
  /// This creates visual hierarchy where jet stream winds appear faster
  /// and more dramatic than surface winds.
  int get streamlineTrailPoints => switch (this) {
        AltitudeLevel.surface => 12,
        AltitudeLevel.midLevel => 18,
        AltitudeLevel.level700 => 20,
        AltitudeLevel.level500 => 22,
        AltitudeLevel.level300 => 24,
        AltitudeLevel.jetStream => 25,
      };
}
