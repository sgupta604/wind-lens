import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/altitude_level.dart';
import '../models/particle.dart';
import '../models/wind_data.dart';
import '../services/performance_manager.dart';
import '../services/sky_detection/sky_mask.dart';

/// Callback type for FPS and particle count updates.
///
/// [fps] is the current average frames per second.
/// [particleCount] is the current adaptive particle count.
typedef FpsUpdateCallback = void Function(double fps, int particleCount);

/// A widget that renders animated wind particles over the camera view.
///
/// Particles are rendered only in sky regions as determined by the [skyMask].
/// The animation uses a Ticker for smooth 60 FPS updates, and particles are
/// pre-allocated to avoid garbage collection pressure.
///
/// Key features:
/// - Pre-allocated particle pool (no allocations in render loop)
/// - 2-pass glow rendering for visual appeal
/// - Sky mask integration for realistic AR effect
/// - Wind-driven particle movement
/// - World-fixed direction (adjusts for compass heading)
/// - Altitude-specific coloring and parallax effects
/// - Adaptive performance with PerformanceManager integration
/// - FPS callback for debug display
class ParticleOverlay extends StatefulWidget {
  /// The sky mask for filtering particles to sky region.
  final SkyMask skyMask;

  /// Number of particles in the pool (default 2000).
  ///
  /// Note: This is the initial/maximum particle count. The actual count
  /// may be reduced by the PerformanceManager if FPS drops below 45.
  final int particleCount;

  /// Wind data containing u/v components, speed, and direction.
  ///
  /// Used to determine particle movement direction and speed.
  /// Defaults to zero wind if not specified.
  final WindData windData;

  /// Compass heading in degrees (0-360, clockwise from North).
  ///
  /// Used to make particles appear "world-fixed" - they maintain
  /// their real-world direction as the phone rotates.
  final double compassHeading;

  /// The altitude level for particle visualization.
  ///
  /// Determines particle color, trail scale, and parallax factor.
  /// Defaults to [AltitudeLevel.surface].
  final AltitudeLevel altitudeLevel;

  /// Previous compass heading for parallax calculation.
  ///
  /// The difference between current heading and previous heading is used
  /// to calculate parallax offset, creating a depth illusion where higher
  /// altitude particles appear to move less when the phone rotates.
  final double previousHeading;

  /// Callback for FPS and particle count updates.
  ///
  /// Called approximately once per second with the current average FPS
  /// and adaptive particle count. Useful for debug display.
  final FpsUpdateCallback? onFpsUpdate;

  /// Optional PerformanceManager for testing.
  ///
  /// If not provided, a new instance will be created internally.
  final PerformanceManager? performanceManager;

  /// Creates a new ParticleOverlay.
  ///
  /// The [skyMask] is required and determines which screen regions
  /// will display particles. Wind data and compass heading control
  /// particle movement direction. Altitude level affects visual appearance.
  ///
  /// Optional [onFpsUpdate] callback provides FPS/particle count updates
  /// for debug display purposes.
  ParticleOverlay({
    super.key,
    required this.skyMask,
    this.particleCount = 2000,
    WindData? windData,
    this.compassHeading = 0.0,
    this.altitudeLevel = AltitudeLevel.surface,
    this.previousHeading = 0.0,
    this.onFpsUpdate,
    this.performanceManager,
  }) : windData = windData ?? WindData.zero();

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  /// Animation ticker for 60 FPS updates.
  late Ticker _ticker;

  /// Pre-allocated particle pool (NO allocations in render loop).
  late List<Particle> _particles;

  /// Random number generator for particle resets.
  late Random _random;

  /// Last frame time for delta calculation.
  Duration _lastFrameTime = Duration.zero;

  /// Performance manager for adaptive particle count.
  late PerformanceManager _performanceManager;

  /// Last time FPS callback was fired.
  DateTime _lastFpsCallback = DateTime.now();

  /// Current particle count (may differ from widget.particleCount due to performance adaptation).
  int _currentParticleCount = 2000;

  /// Cached screen angle (computed each frame, not allocated).
  double _screenAngle = 0.0;

  /// Notifier to trigger repaints without setState.
  /// Incrementing the value triggers CustomPaint to repaint.
  late ValueNotifier<int> _repaintNotifier;

  @override
  void initState() {
    super.initState();
    _random = Random();
    _repaintNotifier = ValueNotifier<int>(0);

    // Use provided performance manager or create a new one
    _performanceManager = widget.performanceManager ?? PerformanceManager();
    _currentParticleCount = widget.particleCount;

    // Pre-allocate entire particle pool with staggered ages
    // to avoid all particles appearing at once
    _particles = List.generate(
      _currentParticleCount,
      (_) => Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        age: _random.nextDouble(), // Stagger initial ages 0-1
        trailLength: 10,
      ),
    );

    // Start the animation ticker
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  /// Resets a particle to a random position within sky regions.
  ///
  /// Tries up to [maxAttempts] times to find a valid sky position.
  /// Falls back to a random position if no sky is found to prevent
  /// infinite loops when the user is pointing at mostly non-sky.
  ///
  /// Performance optimization: When sky fraction is very high (>90%),
  /// skips the expensive loop since almost any random position is valid.
  ///
  /// Parameters:
  /// - [p]: The particle to reset
  /// - [skyMask]: The current sky detection mask
  /// - [maxAttempts]: Maximum sampling attempts (default: 10)
  void _resetToSkyPosition(Particle p, SkyMask skyMask, {int maxAttempts = 10}) {
    // Quick path: if sky fraction is very high, skip expensive checks
    // Almost any position will be valid, so just pick random and verify once
    if (skyMask.skyFraction > 0.9) {
      p.x = _random.nextDouble();
      p.y = _random.nextDouble();
      p.age = 0.0;
      return;
    }

    for (int i = 0; i < maxAttempts; i++) {
      final x = _random.nextDouble();
      final y = _random.nextDouble();
      if (skyMask.isPointInSky(x, y)) {
        p.x = x;
        p.y = y;
        p.age = 0.0;
        return;
      }
    }
    // Fallback: random position (will be hidden by render check)
    p.x = _random.nextDouble();
    p.y = _random.nextDouble();
    p.age = 0.0;
  }

  /// Adjusts the particle pool size when performance manager changes count.
  void _adjustParticlePool(int newCount) {
    if (newCount == _currentParticleCount) return;

    if (newCount < _currentParticleCount) {
      // Reduce: just truncate the list
      _particles = _particles.sublist(0, newCount);
    } else {
      // Increase: add new particles
      final additionalParticles = List.generate(
        newCount - _currentParticleCount,
        (_) => Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          age: _random.nextDouble(),
          trailLength: 10,
        ),
      );
      _particles.addAll(additionalParticles);
    }
    _currentParticleCount = newCount;
  }

  /// Called every frame by the Ticker.
  ///
  /// Updates particle positions based on wind direction, ages particles,
  /// applies parallax effect based on heading change, and triggers a repaint.
  /// Also records frame timing with PerformanceManager and calls FPS callback.
  void _onTick(Duration elapsed) {
    // Record frame with performance manager BEFORE processing
    _performanceManager.recordFrame(elapsed, _lastFrameTime);

    // Calculate delta time since last frame
    final dt = (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = elapsed;

    // Check if particle count needs adjustment
    final targetParticleCount = _performanceManager.particleCount;
    if (targetParticleCount != _currentParticleCount) {
      _adjustParticlePool(targetParticleCount);
    }

    // Calculate screen-space angle (wind direction adjusted for compass)
    // windDirection is in radians (meteorological: direction wind comes FROM)
    // compassHeading is in degrees (0-360, clockwise from North)
    final windAngle = widget.windData.directionRadians;
    final compassRad = widget.compassHeading * pi / 180;
    _screenAngle = windAngle - compassRad;

    // Calculate speed factor (m/s -> screen fraction per second)
    // Multiplier of 0.002 from spec gives reasonable visual speed
    final speedFactor = widget.windData.speed * 0.002;

    // Calculate heading delta for parallax effect
    // Normalize to -180 to 180 range to handle wraparound (359 -> 1 degrees)
    double headingDelta = widget.compassHeading - widget.previousHeading;
    if (headingDelta > 180) headingDelta -= 360;
    if (headingDelta < -180) headingDelta += 360;

    // Get altitude-specific properties
    // NOTE: parallaxFactor is intentionally unused after BUG-004 fix
    // Kept for potential future subtle depth effects
    // ignore: unused_local_variable
    final parallaxFactor = widget.altitudeLevel.parallaxFactor;
    final trailScale = widget.altitudeLevel.trailScale;

    // Update all particles
    for (final p in _particles) {
      // WORLD ANCHORING: All particles are 100% anchored to world space
      // When phone rotates X degrees, particles shift X/360 of screen width
      // This creates the AR illusion of particles fixed in the real sky
      // Spec: "Particles should appear to stay fixed in world space" (Section 11)
      // BUG-004 Fix: Removed parallaxFactor multiplication that broke world anchoring
      p.x -= (headingDelta / 360.0);

      // Move particle based on wind direction
      p.x += cos(_screenAngle) * speedFactor * dt;
      p.y -= sin(_screenAngle) * speedFactor * dt; // Y inverted in screen coords

      // Update trail length based on wind speed and altitude scale
      // Shorter trails at higher altitudes create depth illusion
      p.trailLength = widget.windData.speed * 0.5 * trailScale;

      // Age the particle (~3 second lifespan with 0.3 multiplier)
      p.age += dt * 0.3;

      // Wrap around screen edges (instead of just resetting)
      if (p.x < 0) p.x += 1.0;
      if (p.x > 1) p.x -= 1.0;
      if (p.y < 0) p.y += 1.0;
      if (p.y > 1) p.y -= 1.0;

      // Reset expired particles OR particles that drifted out of sky
      if (p.isExpired || !widget.skyMask.isPointInSky(p.x, p.y)) {
        _resetToSkyPosition(p, widget.skyMask);
      }
    }

    // FPS callback (throttled to ~1/second)
    final now = DateTime.now();
    if (now.difference(_lastFpsCallback).inSeconds >= 1) {
      // Call FPS callback if provided
      widget.onFpsUpdate?.call(
        _performanceManager.currentFps,
        _currentParticleCount,
      );
      _lastFpsCallback = now;
    }

    // Trigger repaint without full widget rebuild
    _repaintNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ParticleOverlayPainter(
          repaintNotifier: _repaintNotifier,
          particles: _particles,
          skyMask: widget.skyMask,
          windAngle: _screenAngle,
          color: widget.altitudeLevel.particleColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// CustomPainter that renders particles with a 2-pass glow effect.
///
/// For each particle:
/// 1. Checks if the particle is in the sky region (via SkyMask)
/// 2. Calculates opacity based on age (fade in/out)
/// 3. Renders a glow pass (wider, blurred, lower opacity)
/// 4. Renders a core pass (thinner, sharper, higher opacity)
///
/// Paint objects are pre-allocated to avoid GC pressure.
/// Colors are cached for common opacity levels to avoid withValues() calls.
class ParticleOverlayPainter extends CustomPainter {
  /// The list of particles to render.
  final List<Particle> particles;

  /// The sky mask for filtering particles.
  final SkyMask skyMask;

  /// Wind direction angle in radians (screen-space, adjusted for compass).
  final double windAngle;

  /// Base color for particles.
  final Color color;

  /// Pre-allocated glow paint (width=4.0, blur).
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 4.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

  /// Pre-allocated core paint (width=1.5).
  final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.5;

  /// Cached glow colors for opacity levels 0.0-1.0 in 0.1 increments.
  /// Avoids Color.withValues() allocations in render loop.
  late final List<Color> _glowColors;

  /// Cached core colors for opacity levels 0.0-1.0 in 0.1 increments.
  /// Avoids Color.withValues() allocations in render loop.
  late final List<Color> _coreColors;

  /// Creates a new ParticleOverlayPainter.
  ///
  /// The [repaintNotifier] triggers repaints when its value changes,
  /// avoiding the need for setState() in the parent widget.
  ParticleOverlayPainter({
    required Listenable repaintNotifier,
    required this.particles,
    required this.skyMask,
    required this.windAngle,
    required this.color,
  }) : super(repaint: repaintNotifier) {
    // Pre-compute colors for common opacity levels (0.0 to 1.0 in 0.1 steps)
    // This avoids calling withValues() 2000+ times per frame
    _glowColors = List.generate(11, (i) {
      final baseOpacity = i / 10.0;
      return color.withValues(alpha: baseOpacity * 0.3);
    });
    _coreColors = List.generate(11, (i) {
      final baseOpacity = i / 10.0;
      return color.withValues(alpha: baseOpacity * 0.9);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // SKY MASK CHECK: Only render if this point is in sky
      if (!skyMask.isPointInSky(p.x, p.y)) {
        continue; // Skip particles over buildings/ground
      }

      // Calculate opacity from age (fade in, peak, fade out)
      // sin(age * pi) creates a smooth curve: 0 -> 1 -> 0
      final baseOpacity = sin(p.age * 3.14159).clamp(0.0, 1.0);

      // Skip nearly invisible particles
      if (baseOpacity < 0.01) continue;

      // Quantize opacity to cached color index (0-10 for 0.0-1.0 range)
      final opacityIndex = (baseOpacity * 10).round().clamp(0, 10);

      // Convert normalized coordinates to screen coordinates
      final startX = p.x * size.width;
      final startY = p.y * size.height;

      // Calculate trail end point based on wind angle
      final endX = startX - cos(windAngle) * p.trailLength;
      final endY = startY + sin(windAngle) * p.trailLength;

      final start = Offset(startX, startY);
      final end = Offset(endX, endY);

      // PASS 1: The glow (wider, blurred, lower opacity) - use cached color
      _glowPaint.color = _glowColors[opacityIndex];
      canvas.drawLine(start, end, _glowPaint);

      // PASS 2: The core (thinner, sharper, higher opacity) - use cached color
      _corePaint.color = _coreColors[opacityIndex];
      canvas.drawLine(start, end, _corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleOverlayPainter oldDelegate) {
    // Always repaint since particles animate every frame
    return true;
  }
}
