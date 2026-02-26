import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:wind_lens/core/models/wind_data.dart';

/// Max trail positions stored per particle.
const _kTrailLength = 20;

/// Number of particles rendered on the home screen.
const kHomeParticleCount = 40;

/// Mutable particle used by [HomeParticlePainter].
///
/// NOT Freezed -- this is a hot-path object updated every frame.
/// Trail uses a fixed-size [Float64List] circular buffer — zero allocation
/// in the render loop.
class HomeParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  double radius;
  double waveOffset;

  /// Circular buffer for trail X coordinates (fixed size).
  final Float64List trailX = Float64List(_kTrailLength);

  /// Circular buffer for trail Y coordinates (fixed size).
  final Float64List trailY = Float64List(_kTrailLength);

  /// Write index into the circular buffer.
  int trailHead = 0;

  /// Number of valid trail entries (up to [_kTrailLength]).
  int trailCount = 0;

  HomeParticle()
      : x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        life = 0,
        maxLife = 1,
        radius = 1,
        waveOffset = 0;

  void resetTrail() {
    trailHead = 0;
    trailCount = 0;
  }

  void pushTrail(double px, double py) {
    trailX[trailHead] = px;
    trailY[trailHead] = py;
    trailHead = (trailHead + 1) % _kTrailLength;
    if (trailCount < _kTrailLength) trailCount++;
  }

  /// Returns the i-th trail point (0 = oldest).
  (double, double) trailAt(int i) {
    final idx = (trailHead - trailCount + i) % _kTrailLength;
    return (trailX[idx], trailY[idx]);
  }
}

/// Long-lived particle state that survives painter recreation.
///
/// Flutter creates a new [HomeParticlePainter] each build, but this
/// state object is created once and passed in, so particles keep their
/// positions across frames.
class HomeParticleState {
  final Random _rng = Random();
  late final List<HomeParticle> particles;
  Size lastSize = Size.zero;

  HomeParticleState() {
    particles = List.generate(kHomeParticleCount, (_) => HomeParticle());
  }

  /// Initializes all particles for a given canvas size.
  void initForSize(Size size) {
    if (size == lastSize) return;
    lastSize = size;
    for (final p in particles) {
      spawnParticle(p, size);
      // Stagger initial life so they don't all start at once.
      p.life = _rng.nextDouble() * p.maxLife;
    }
  }

  /// Resets a single particle with random spawn parameters.
  void spawnParticle(HomeParticle p, Size size) {
    final fromLeft = _rng.nextDouble() < 0.95;
    p.x = fromLeft
        ? -_rng.nextDouble() * 20
        : size.width + _rng.nextDouble() * 20;
    // Particles span full section height (5% to 90%)
    p.y = size.height * 0.05 + _rng.nextDouble() * size.height * 0.85;
    p.vx = fromLeft
        ? 0.6 + _rng.nextDouble() * 1.2
        : -(0.6 + _rng.nextDouble() * 1.2);
    p.vy = (_rng.nextDouble() - 0.5) * 0.3;
    p.life = 0;
    p.maxLife = 0.5 + _rng.nextDouble() * 0.5;
    p.radius = 1.2 + _rng.nextDouble() * 0.6;
    p.waveOffset = _rng.nextDouble() * pi * 2;
    p.resetTrail();
  }
}

/// CustomPainter that renders decorative wind particles on the home screen.
///
/// Particles flow left-to-right with sinusoidal wiggle, fade in and out
/// over their lifetime, and leave tapered trails. No object allocation
/// occurs in the render loop.
///
/// **Critical:** The mutable [HomeParticleState] is owned by the parent
/// widget and passed in, so it survives across painter recreations.
/// The [Animation] is passed as the repaint listenable.
class HomeParticlePainter extends CustomPainter {
  final HomeParticleState state;
  final WindData? windData;

  /// Reusable paint object to avoid allocation in the render loop.
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  /// Reusable paint for trail lines.
  final Paint _trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  HomeParticlePainter({
    required this.state,
    required Animation<double> animation,
    this.windData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    state.initForSize(size);

    for (final p in state.particles) {
      // Update position
      p.vy += sin(p.waveOffset + p.x * 0.015) * 0.1;
      p.x += p.vx;
      p.y += p.vy;
      p.vy *= 0.95; // Dampen vertical velocity
      p.life += 0.005;

      // Push current position to trail circular buffer
      p.pushTrail(p.x, p.y);

      // Reset if expired or out of bounds
      if (p.life >= p.maxLife || p.x > size.width + 30 || p.x < -30) {
        state.spawnParticle(p, size);
        continue;
      }

      // Calculate alpha based on lifetime (fade in, then fade out)
      final alpha = sin(p.life / p.maxLife * pi) * 0.7;
      if (alpha <= 0) continue;

      // Draw trail lines with tapered opacity
      for (int i = 1; i < p.trailCount; i++) {
        final t = i / p.trailCount;
        _trailPaint.color = Color.fromRGBO(255, 255, 255, t * alpha * 0.5);
        _trailPaint.strokeWidth = p.radius * t * 0.9;
        final (x0, y0) = p.trailAt(i - 1);
        final (x1, y1) = p.trailAt(i);
        canvas.drawLine(Offset(x0, y0), Offset(x1, y1), _trailPaint);
      }

      // Draw head dot
      _paint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(HomeParticlePainter oldDelegate) => true;
}
