import 'dart:ui';

/// Represents different altitude levels for wind visualization.
///
/// Each altitude level has distinct visual properties for particle rendering:
/// - Surface (10m): Close-up view with fast-moving white particles
/// - Mid-level (1,500m / 850 hPa): Cloud level with cyan particles
/// - Jet Stream (10,500m / 250 hPa): High altitude with purple particles
///
/// Example:
/// ```dart
/// final level = AltitudeLevel.midLevel;
/// print(level.displayName);           // "Cloud Level"
/// print(level.metersAGL);             // 1500.0
/// print(level.particleSpeedMultiplier); // 1.5
/// ```
enum AltitudeLevel {
  /// Surface level (10m AGL).
  ///
  /// Close-up view with maximum parallax effect and white particles.
  surface,

  /// Mid-level / Cloud level (~1,500m AGL / 850 hPa).
  ///
  /// Moderate distance with cyan-colored particles.
  midLevel,

  /// Jet stream level (~10,500m AGL / 250 hPa).
  ///
  /// Far view with minimal parallax and purple particles.
  jetStream,
}

/// Extension providing visual and physical properties for each altitude level.
extension AltitudeLevelProperties on AltitudeLevel {
  /// Human-readable display name for the altitude level.
  ///
  /// - surface: "Surface"
  /// - midLevel: "Cloud Level"
  /// - jetStream: "Jet Stream"
  String get displayName => switch (this) {
        AltitudeLevel.surface => 'Surface',
        AltitudeLevel.midLevel => 'Cloud Level',
        AltitudeLevel.jetStream => 'Jet Stream',
      };

  /// Altitude in meters above ground level (AGL).
  ///
  /// - surface: 10m
  /// - midLevel: 1,500m (approximately 850 hPa pressure level)
  /// - jetStream: 10,500m (approximately 250 hPa pressure level)
  double get metersAGL => switch (this) {
        AltitudeLevel.surface => 10.0,
        AltitudeLevel.midLevel => 1500.0,
        AltitudeLevel.jetStream => 10500.0,
      };

  /// Color used to render particles at this altitude.
  ///
  /// All colors have alpha 0xAA (170/255 = 67% opacity) for visibility
  /// against sky backgrounds while maintaining translucency.
  ///
  /// - surface: Ghostly white (0xAAFFFFFF)
  /// - midLevel: Cyan (0xAA00DDFF)
  /// - jetStream: Magenta/purple (0xAADD00FF)
  Color get particleColor => switch (this) {
        AltitudeLevel.surface => const Color(0xAAFFFFFF),
        AltitudeLevel.midLevel => const Color(0xAA00DDFF),
        AltitudeLevel.jetStream => const Color(0xAADD00FF),
      };

  /// Multiplier for wind speed at this altitude.
  ///
  /// Higher altitudes typically have stronger winds:
  /// - surface: 1.0x (baseline speed)
  /// - midLevel: 1.5x (50% faster)
  /// - jetStream: 3.0x (3x faster)
  double get particleSpeedMultiplier => switch (this) {
        AltitudeLevel.surface => 1.0,
        AltitudeLevel.midLevel => 1.5,
        AltitudeLevel.jetStream => 3.0,
      };

  /// Parallax factor for potential depth effects.
  ///
  /// NOTE: As of BUG-004 fix, this factor is NO LONGER used for world anchoring.
  /// All altitude levels now use 100% world anchoring (particles stay fixed in
  /// real-world space when phone rotates).
  ///
  /// Depth perception is achieved through other visual properties:
  /// - Particle color: white (surface) -> cyan (mid) -> purple (jet stream)
  /// - Trail scale: 1.0 -> 0.7 -> 0.5 (shorter = further)
  /// - Speed multiplier: 1.0x -> 1.5x -> 3.0x (faster at altitude)
  ///
  /// Values retained for potential future subtle parallax enhancement:
  /// - surface: 1.0
  /// - midLevel: 0.6
  /// - jetStream: 0.3
  double get parallaxFactor => switch (this) {
        AltitudeLevel.surface => 1.0,
        AltitudeLevel.midLevel => 0.6,
        AltitudeLevel.jetStream => 0.3,
      };

  /// Scale factor for particle trail length.
  ///
  /// Smaller values create shorter trails, making particles appear further away.
  /// - surface: 1.0 (full-size trails)
  /// - midLevel: 0.7 (70% of full size)
  /// - jetStream: 0.5 (50% of full size)
  ///
  /// This perspective scaling reinforces the depth illusion.
  double get trailScale => switch (this) {
        AltitudeLevel.surface => 1.0,
        AltitudeLevel.midLevel => 0.7,
        AltitudeLevel.jetStream => 0.5,
      };

  /// Number of trail points to use for streamlines rendering.
  ///
  /// Higher altitudes use more trail points for longer, more dramatic streamlines:
  /// - surface: 12 points (shorter trails, ~4-6% screen width)
  /// - midLevel: 18 points (medium trails, ~8-12% screen width)
  /// - jetStream: 25 points (long trails, ~15-20% screen width)
  ///
  /// This creates visual hierarchy where jet stream winds appear faster
  /// and more dramatic than surface winds.
  int get streamlineTrailPoints => switch (this) {
        AltitudeLevel.surface => 12,
        AltitudeLevel.midLevel => 18,
        AltitudeLevel.jetStream => 25,
      };
}
