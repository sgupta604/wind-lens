import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/particle.dart';
import '../models/wind_data.dart';
import '../services/sky_detection/sky_mask.dart';

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
/// - FPS logging for performance monitoring
class ParticleOverlay extends StatefulWidget {
  /// The sky mask for filtering particles to sky region.
  final SkyMask skyMask;

  /// Number of particles in the pool (default 2000).
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

  /// Creates a new ParticleOverlay.
  ///
  /// The [skyMask] is required and determines which screen regions
  /// will display particles. Wind data and compass heading control
  /// particle movement direction.
  ParticleOverlay({
    super.key,
    required this.skyMask,
    this.particleCount = 2000,
    WindData? windData,
    this.compassHeading = 0.0,
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

  /// Frame counter for FPS calculation.
  int _frameCount = 0;

  /// Last time FPS was logged.
  DateTime _lastFpsLog = DateTime.now();

  /// Cached screen angle (computed each frame, not allocated).
  double _screenAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _random = Random();

    // Pre-allocate entire particle pool with staggered ages
    // to avoid all particles appearing at once
    _particles = List.generate(
      widget.particleCount,
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
    super.dispose();
  }

  /// Called every frame by the Ticker.
  ///
  /// Updates particle positions based on wind direction, ages particles,
  /// resets expired particles, and triggers a repaint.
  void _onTick(Duration elapsed) {
    // Calculate delta time since last frame
    final dt = (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = elapsed;

    // Calculate screen-space angle (wind direction adjusted for compass)
    // windDirection is in radians (meteorological: direction wind comes FROM)
    // compassHeading is in degrees (0-360, clockwise from North)
    final windAngle = widget.windData.directionRadians;
    final compassRad = widget.compassHeading * pi / 180;
    _screenAngle = windAngle - compassRad;

    // Calculate speed factor (m/s -> screen fraction per second)
    // Multiplier of 0.002 from spec gives reasonable visual speed
    final speedFactor = widget.windData.speed * 0.002;

    // Update all particles
    for (final p in _particles) {
      // Move particle based on wind direction
      p.x += cos(_screenAngle) * speedFactor * dt;
      p.y -= sin(_screenAngle) * speedFactor * dt; // Y inverted in screen coords

      // Update trail length based on wind speed
      p.trailLength = widget.windData.speed * 0.5;

      // Age the particle (~3 second lifespan with 0.3 multiplier)
      p.age += dt * 0.3;

      // Wrap around screen edges (instead of just resetting)
      if (p.x < 0) p.x += 1.0;
      if (p.x > 1) p.x -= 1.0;
      if (p.y < 0) p.y += 1.0;
      if (p.y > 1) p.y -= 1.0;

      // Reset expired particles
      if (p.isExpired) {
        p.reset(_random);
      }
    }

    // FPS logging (every second)
    _frameCount++;
    final now = DateTime.now();
    if (now.difference(_lastFpsLog).inSeconds >= 1) {
      debugPrint(
          'Rendering ${widget.particleCount} particles at $_frameCount FPS');
      _frameCount = 0;
      _lastFpsLog = now;
    }

    // Trigger repaint
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticleOverlayPainter(
        particles: _particles,
        skyMask: widget.skyMask,
        windAngle: _screenAngle,
        color: Colors.white,
      ),
      size: Size.infinite,
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

  /// Creates a new ParticleOverlayPainter.
  ParticleOverlayPainter({
    required this.particles,
    required this.skyMask,
    required this.windAngle,
    required this.color,
  });

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

      // Convert normalized coordinates to screen coordinates
      final startX = p.x * size.width;
      final startY = p.y * size.height;

      // Calculate trail end point based on wind angle
      final endX = startX - cos(windAngle) * p.trailLength;
      final endY = startY + sin(windAngle) * p.trailLength;

      final start = Offset(startX, startY);
      final end = Offset(endX, endY);

      // PASS 1: The glow (wider, blurred, lower opacity)
      _glowPaint.color = color.withValues(alpha: baseOpacity * 0.3);
      canvas.drawLine(start, end, _glowPaint);

      // PASS 2: The core (thinner, sharper, higher opacity)
      _corePaint.color = color.withValues(alpha: baseOpacity * 0.9);
      canvas.drawLine(start, end, _corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleOverlayPainter oldDelegate) {
    // Always repaint since particles animate every frame
    return true;
  }
}
