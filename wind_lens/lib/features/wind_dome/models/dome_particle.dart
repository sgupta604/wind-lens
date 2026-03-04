import 'dart:math';

import 'dome_constants.dart';
import 'dome_wind_field.dart';

/// Mutable particle for the dome wind visualization.
///
/// NOT Freezed -- this is a hot-path object updated 2000x per frame at 60 FPS.
/// Trail uses parallel arrays (trailX/trailY/trailZ) with a ring buffer to
/// achieve zero allocation in the tick loop.
///
/// Particle positions are in render-space coordinates, dome-local:
/// - x: east-west [-domeR, domeR]
/// - y: altitude [0, domeH]
/// - z: north-south [-domeR, domeR]
class DomeParticle {
  /// East-west position in render units.
  double x;

  /// Altitude position in render units.
  double y;

  /// North-south position in render units.
  double z;

  // ─── Trail Ring Buffer ─────────────────────────────────────────

  /// Trail X coordinates (fixed size, ring buffer).
  final List<double> trailX;

  /// Trail Y coordinates (fixed size, ring buffer).
  final List<double> trailY;

  /// Trail Z coordinates (fixed size, ring buffer).
  final List<double> trailZ;

  /// Write index into the ring buffer.
  int trailHead;

  /// Number of valid trail entries (up to [DomeConstants.trailLength]).
  int trailCount;

  /// Creates a particle at the origin with empty trail.
  DomeParticle()
      : x = 0,
        y = 0,
        z = 0,
        trailX = List<double>.filled(DomeConstants.trailLength, 0),
        trailY = List<double>.filled(DomeConstants.trailLength, 0),
        trailZ = List<double>.filled(DomeConstants.trailLength, 0),
        trailHead = 0,
        trailCount = 0;

  /// Creates a particle at a random position inside the dome.
  factory DomeParticle.random(Random rng, double domeR, double domeH) {
    final p = DomeParticle();
    p.respawn(rng, domeR, domeH);
    return p;
  }

  /// Tests whether a point is inside the half-ellipsoid dome.
  ///
  /// The dome is defined by: (x^2 + z^2) / r^2 + y^2 / h^2 <= 1
  /// with the additional constraint y >= 0 (upper half only).
  static bool insideDome(
      double x, double y, double z, double r, double h) {
    if (y < 0) return false;
    return (x * x + z * z) / (r * r) + (y * y) / (h * h) <= 1.0;
  }

  /// Respawns the particle at a random position inside the dome.
  ///
  /// Uses rejection sampling for uniform volume distribution.
  /// Clears the trail on respawn.
  void respawn(Random rng, double domeR, double domeH) {
    // Rejection sampling -- simple and correct for an ellipsoid
    for (int attempt = 0; attempt < 500; attempt++) {
      final rx = (rng.nextDouble() * 2 - 1) * domeR;
      final ry = rng.nextDouble() * domeH;
      final rz = (rng.nextDouble() * 2 - 1) * domeR;
      if (insideDome(rx, ry, rz, domeR, domeH)) {
        x = rx;
        y = ry;
        z = rz;
        _clearTrail();
        return;
      }
    }
    // Fallback to center if rejection sampling fails
    x = 0;
    y = domeH * 0.2;
    z = 0;
    _clearTrail();
  }

  /// Updates the particle position for one frame.
  ///
  /// Samples the wind field at the current position, applies wind velocity
  /// and a gentle updraft, checks dome containment, and records the
  /// position in the trail ring buffer.
  ///
  /// Physics ported from prototype wind-dome.jsx lines 244-259:
  /// - Wind velocity: x += wind.u * velocityScale * dt
  /// - Updraft: y += (updraftBase + (y/domeH) * updraftGradient) * dt
  /// - Containment: respawn when outside 1.02x dome boundary
  ///
  /// [field] is the current wind field to sample.
  /// [dt] is the time delta in seconds since the last frame.
  /// [domeR] and [domeH] are the dome dimensions in render units.
  void tick(
    DomeWindField field,
    double dt,
    double domeR,
    double domeH, {
    Random? rng,
  }) {
    final wind = field.sample(x, y, z);

    // Apply wind velocity (render-units/second via velocityScale)
    // Scale by dome size: larger domes need proportionally larger displacement
    // to maintain the same visual crossing speed.
    // +u = eastward  -> +x = East  (same sign, no flip needed)
    // +v = northward -> -z = North (opposite sign, negate v)
    final renderScale = domeR / DomeConstants.domeR;
    x += wind.u * DomeConstants.velocityScale * renderScale * dt;
    z -= wind.v * DomeConstants.velocityScale * renderScale * dt;

    // Gentle updraft: increases with altitude (prototype line 249)
    // Scale by renderScale to match horizontal velocity scaling.
    y += (DomeConstants.updraftBase +
            (y / domeH) * DomeConstants.updraftGradient) *
        renderScale * dt;

    // Check dome containment with 2% margin (prototype line 252)
    if (!insideDome(x, y, z, domeR * 1.02, domeH * 1.02) || y < 0) {
      respawn(rng ?? Random(), domeR, domeH);
      return;
    }

    // Record position in trail ring buffer (zero allocation)
    _pushTrail(x, y, z);
  }

  /// Returns the i-th trail point (0 = most recent).
  ///
  /// Returns (x, y, z) coordinates.
  (double, double, double) trailAt(int i) {
    // 0 = most recent, trailCount-1 = oldest
    final idx =
        (trailHead - 1 - i + DomeConstants.trailLength * 2) %
            DomeConstants.trailLength;
    return (trailX[idx], trailY[idx], trailZ[idx]);
  }

  // ─── Private Helpers ───────────────────────────────────────────

  void _pushTrail(double px, double py, double pz) {
    trailX[trailHead] = px;
    trailY[trailHead] = py;
    trailZ[trailHead] = pz;
    trailHead = (trailHead + 1) % DomeConstants.trailLength;
    if (trailCount < DomeConstants.trailLength) trailCount++;
  }

  void _clearTrail() {
    trailHead = 0;
    trailCount = 0;
  }
}
