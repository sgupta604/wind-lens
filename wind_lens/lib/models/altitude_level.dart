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

  /// Parallax factor for creating depth perception.
  ///
  /// Lower values = objects appear further away (less movement when rotating phone).
  /// - surface: 1.0 (close, moves most when phone rotates)
  /// - midLevel: 0.6 (moderate distance)
  /// - jetStream: 0.3 (far away, barely moves when phone rotates)
  ///
  /// This creates the illusion that higher altitude particles are further
  /// from the viewer, similar to how distant mountains appear to move
  /// less than nearby trees when you turn your head.
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
}
