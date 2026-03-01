import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../models/dome_constants.dart';
import '../models/dome_particle.dart';

/// CustomPainter that renders the 3D dome wireframe, particles, and user marker.
///
/// Does NOT own particle state -- particles are owned by the parent
/// [WindDomeScreen] StatefulWidget and passed in by reference. This follows
/// the CustomPainter State Survival Pattern documented in CLAUDE.md.
///
/// Rendering pipeline (ported from wind-dome.jsx prototype):
/// 1. Footprint circle on ground plane (y=0.03)
/// 2. Dome wireframe (8 latitude rings + 16 meridians)
/// 3. Vertical axis line
/// 4. Particles (trail segments with altitude + speed brightness)
/// 5. User position marker (inner dot + pulsing ring + accuracy halo)
///
/// Camera model: spherical orbit (phi, theta, camR) with manual lookAt
/// view matrix and perspective projection via focal length.
class DomePainter extends CustomPainter {
  /// Particle list owned by parent StatefulWidget.
  final List<DomeParticle> particles;

  /// Horizontal orbit angle (radians).
  final double theta;

  /// Vertical orbit angle (radians).
  final double phi;

  /// Camera orbit radius in render units.
  final double camR;

  /// Dome radius in render units.
  final double domeR;

  /// Dome height in render units.
  final double domeH;

  /// Elapsed time in seconds (for pulsing marker animation).
  final double time;

  // Pre-created paint objects to avoid allocation in paint()
  final Paint _wirePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..isAntiAlias = true;

  final Paint _particlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.0
    ..isAntiAlias = true;

  final Paint _markerFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  final Paint _markerStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  // Pre-allocated paints for ground disc (avoid allocation in paint loop)
  final Paint _groundDiscFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true
    ..color = Colors.black.withValues(alpha: DomeConstants.groundDiscFillOpacity);

  final Paint _groundDiscStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeWidth = DomeConstants.groundDiscStrokeWidth
    ..color =
        Colors.white.withValues(alpha: DomeConstants.groundDiscStrokeOpacity);

  DomePainter({
    required this.particles,
    required this.theta,
    required this.phi,
    required this.camR,
    required this.domeR,
    required this.domeH,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final viewMatrix = _buildViewMatrix(theta, phi, camR, domeH);
    final focal = _focalLength(size);

    _drawGroundDisc(canvas, size, viewMatrix, focal);
    _drawCompassRose(canvas, size, viewMatrix, focal);
    _drawFootprint(canvas, size, viewMatrix, focal);
    _drawWireframe(canvas, size, viewMatrix, focal);
    _drawVerticalAxis(canvas, size, viewMatrix, focal);
    _drawParticles(canvas, size, viewMatrix, focal);
    _drawUserMarker(canvas, size, viewMatrix, focal);
  }

  // ─── Ground Disc ────────────────────────────────────────────

  /// Draws a dark filled ellipse at ground level (y=0) to visually ground
  /// the dome on top of the map.
  ///
  /// Uses [DomeConstants.groundDiscSegments] projected points around
  /// the dome footprint. Drawn FIRST in paint() so it appears behind
  /// all other dome elements.
  void _drawGroundDisc(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    final points = <Offset>[];
    for (int i = 0; i < DomeConstants.groundDiscSegments; i++) {
      final angle = (i / DomeConstants.groundDiscSegments) * 2 * pi;
      final p = _project3D(
        cos(angle) * domeR,
        0, // y=0 is ground
        sin(angle) * domeR,
        viewMatrix,
        focal,
        size,
      );
      if (p != null) {
        points.add(p);
      }
    }

    // Need at least 3 points to form a polygon
    if (points.length < 3) return;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    // Fill: dark ground plane
    canvas.drawPath(path, _groundDiscFillPaint);
    // Stroke: subtle white edge ring
    canvas.drawPath(path, _groundDiscStrokePaint);
  }

  // ─── Compass Rose ──────────────────────────────────────────────

  /// Draws cardinal and intercardinal direction labels and tick marks on the
  /// ground plane, just outside the dome footprint.
  ///
  /// Labels sit at [DomeConstants.compassLabelRadiusMultiplier] * domeR on the
  /// ground plane (y = [DomeConstants.compassLabelGroundY]). Tick marks extend
  /// inward from domeR by [DomeConstants.compassTickLength] render units.
  ///
  /// Called AFTER [_drawGroundDisc] but BEFORE [_drawWireframe] so the labels
  /// sit on the ground behind the wireframe but above the dark disc.
  void _drawCompassRose(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    final labelR = domeR * DomeConstants.compassLabelRadiusMultiplier;
    final groundY = DomeConstants.compassLabelGroundY;

    // Cardinal directions in dome-local 3D space:
    // N = -z, S = +z, E = +x, W = -x (standard right-hand coordinate system)
    const cardinals = <(String, double, double)>[
      ('N', 0.0, -1.0),
      ('S', 0.0, 1.0),
      ('E', 1.0, 0.0),
      ('W', -1.0, 0.0),
    ];

    // Intercardinal directions for tick marks only
    const intercardinals = <(double, double)>[
      (0.7071, -0.7071), // NE
      (0.7071, 0.7071),  // SE
      (-0.7071, 0.7071), // SW
      (-0.7071, -0.7071), // NW
    ];

    // Draw tick marks at all 8 compass positions
    _wirePaint.strokeWidth = 1.0;

    for (final (label, dx, dz) in cardinals) {
      // Tick mark: from dome edge inward
      final outerX = dx * domeR;
      final outerZ = dz * domeR;
      final innerX = dx * (domeR - DomeConstants.compassTickLength);
      final innerZ = dz * (domeR - DomeConstants.compassTickLength);

      final pOuter =
          _project3D(outerX, groundY, outerZ, viewMatrix, focal, size);
      final pInner =
          _project3D(innerX, groundY, innerZ, viewMatrix, focal, size);

      if (pOuter != null && pInner != null) {
        final isNorth = label == 'N';
        _wirePaint.color = isNorth
            ? const Color(0xBBFF6633) // orange-red at 73% opacity
            : Colors.white.withValues(alpha: 0.4);
        canvas.drawLine(pOuter, pInner, _wirePaint);
      }

      // Label: placed just outside the dome footprint
      final labelX = dx * labelR;
      final labelZ = dz * labelR;
      final pLabel =
          _project3D(labelX, groundY, labelZ, viewMatrix, focal, size);

      if (pLabel != null) {
        final isNorth = label == 'N';
        _drawLabel(
          canvas,
          pLabel,
          label,
          isNorth
              ? const Color(0xDDFF6633) // orange-red at 87% opacity
              : Colors.white.withValues(alpha: 0.6),
          isNorth
              ? DomeConstants.compassNorthFontSize
              : DomeConstants.compassCardinalFontSize,
        );
      }
    }

    // Intercardinal tick marks only (no labels)
    _wirePaint.color = Colors.white.withValues(alpha: 0.25);
    for (final (dx, dz) in intercardinals) {
      final outerX = dx * domeR;
      final outerZ = dz * domeR;
      final innerX = dx * (domeR - DomeConstants.compassTickLength * 0.6);
      final innerZ = dz * (domeR - DomeConstants.compassTickLength * 0.6);

      final pOuter =
          _project3D(outerX, groundY, outerZ, viewMatrix, focal, size);
      final pInner =
          _project3D(innerX, groundY, innerZ, viewMatrix, focal, size);

      if (pOuter != null && pInner != null) {
        canvas.drawLine(pOuter, pInner, _wirePaint);
      }
    }
  }

  /// Draws a centered text label at the given screen position.
  void _drawLabel(
      Canvas canvas, Offset pos, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  // ─── Camera ──────────────────────────────────────────────────

  /// Builds a lookAt view matrix from spherical camera coordinates.
  ///
  /// Ported from prototype lines 52-58:
  /// camera.position.set(
  ///   CAM_R * sin(phi) * sin(theta),
  ///   CAM_R * cos(phi),
  ///   CAM_R * sin(phi) * cos(theta)
  /// );
  /// camera.lookAt(0, DOME_H * 0.2, 0);
  vm.Matrix4 _buildViewMatrix(
      double theta, double phi, double camR, double domeH) {
    // Camera position from spherical coordinates
    final cx = camR * sin(phi) * sin(theta);
    final cy = camR * cos(phi);
    final cz = camR * sin(phi) * cos(theta);

    final eye = vm.Vector3(cx, cy, cz);
    final target = vm.Vector3(0, domeH * 0.2, 0);
    final worldUp = vm.Vector3(0, 1, 0);

    // Build lookAt matrix
    final forward = (target - eye)..normalize();
    final right = forward.cross(worldUp)..normalize();
    final up = right.cross(forward);

    // View matrix: transforms world coords to eye coords
    // [  right.x    right.y    right.z   -dot(right, eye) ]
    // [  up.x       up.y       up.z      -dot(up, eye)    ]
    // [ -forward.x  -forward.y -forward.z  dot(forward, eye) ]
    // [  0           0          0          1                ]
    return vm.Matrix4(
      right.x, up.x, -forward.x, 0,
      right.y, up.y, -forward.y, 0,
      right.z, up.z, -forward.z, 0,
      -right.dot(eye), -up.dot(eye), forward.dot(eye), 1,
    );
  }

  /// Computes focal length from canvas size and FOV.
  ///
  /// focal = (canvas.height / 2) / tan(fovRadians / 2)
  /// This converts the 48-degree vertical FOV from the prototype
  /// (THREE.js PerspectiveCamera fov) to a focal length for
  /// perspective division.
  double _focalLength(Size size) {
    final fovRadians = DomeConstants.fovDegrees * pi / 180;
    return (size.height / 2) / tan(fovRadians / 2);
  }

  /// Projects a 3D point to 2D screen coordinates.
  ///
  /// Returns null if the point is behind the camera.
  /// Uses standard OpenGL view matrix convention where the camera looks
  /// along -Z, so visible points have negative eyeSpace.z.
  Offset? _project3D(
      double x, double y, double z,
      vm.Matrix4 viewMatrix, double focal, Size size) {
    // Transform point by view matrix to eye-space
    final v = vm.Vector4(x, y, z, 1.0);
    final eyeSpace = viewMatrix.transform(v);

    // In OpenGL convention, camera looks along -Z axis.
    // Points in front of camera have negative z.
    // depth = -eyeSpace.z gives positive value for visible points.
    final depth = -eyeSpace.z;
    if (depth <= 0.1) return null;

    // Perspective divide and map to screen
    final screenX = size.width / 2 + eyeSpace.x * focal / depth;
    final screenY = size.height * 0.45 - eyeSpace.y * focal / depth;

    return Offset(screenX, screenY);
  }

  // ─── Footprint Circle ──────────────────────────────────────────

  /// Draws the dome footprint circle on the ground plane.
  ///
  /// Ported from prototype lines 114-124: 128-segment circle at y=0.03,
  /// radius=DOME_R, white with opacity 0.5.
  void _drawFootprint(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    _wirePaint.color = Colors.white.withValues(alpha: 0.5);
    _wirePaint.strokeWidth = 1.0;

    const segments = 128;
    Offset? prev;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * pi;
      final p = _project3D(
        cos(angle) * domeR, 0.03, sin(angle) * domeR,
        viewMatrix, focal, size,
      );
      if (p != null && prev != null) {
        canvas.drawLine(prev, p, _wirePaint);
      }
      prev = p;
    }
  }

  // ─── Dome Wireframe ──────────────────────────────────────────

  /// Draws latitude rings and meridian lines.
  ///
  /// Ported from prototype lines 170-202.
  void _drawWireframe(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    _wirePaint.strokeWidth = 0.8;

    // 8 latitude rings (prototype lines 171-186)
    for (int li = 1; li <= DomeConstants.latRings; li++) {
      final normY = li / DomeConstants.latRings;
      final y = normY * domeH;
      final r = domeR * sqrt(max(0, 1 - normY * normY));
      if (r < 0.5) continue;

      // Top ring (li == latRings): opacity 0.0, skip
      if (li == DomeConstants.latRings) continue;

      final opacity = 0.06 + (1 - normY) * 0.04;
      _wirePaint.color = Colors.white.withValues(alpha: opacity);

      const segments = 80;
      Offset? prev;
      for (int i = 0; i <= segments; i++) {
        final angle = (i / segments) * 2 * pi;
        final p = _project3D(
          cos(angle) * r, y, sin(angle) * r,
          viewMatrix, focal, size,
        );
        if (p != null && prev != null) {
          canvas.drawLine(prev, p, _wirePaint);
        }
        prev = p;
      }
    }

    // 16 meridian lines (prototype lines 189-202)
    _wirePaint.color = Colors.white.withValues(alpha: 0.05);
    for (int li = 0; li < DomeConstants.lonMeridians; li++) {
      final angle = (li / DomeConstants.lonMeridians) * 2 * pi;

      const segments = 32;
      Offset? prev;
      for (int j = 0; j <= segments; j++) {
        final normY = j / segments;
        final r = domeR * sqrt(max(0, 1 - normY * normY));
        final p = _project3D(
          cos(angle) * r, normY * domeH, sin(angle) * r,
          viewMatrix, focal, size,
        );
        if (p != null && prev != null) {
          canvas.drawLine(prev, p, _wirePaint);
        }
        prev = p;
      }
    }
  }

  // ─── Vertical Axis ─────────────────────────────────────────────

  /// Draws the vertical axis line from ground to near dome apex.
  ///
  /// Ported from prototype lines 160-166.
  void _drawVerticalAxis(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    _wirePaint.color = Colors.white.withValues(alpha: 0.08);
    _wirePaint.strokeWidth = 0.8;

    final p0 = _project3D(0, 0.1, 0, viewMatrix, focal, size);
    final p1 = _project3D(0, domeH * 0.95, 0, viewMatrix, focal, size);

    if (p0 != null && p1 != null) {
      canvas.drawLine(p0, p1, _wirePaint);
    }
  }

  // ─── Particles ───────────────────────────────────────────────

  /// Draws particle trail segments with per-segment brightness.
  ///
  /// Brightness formula from prototype lines 272-274:
  /// altBright = 0.4 + (h0.y / DOME_H) * 0.6
  /// trailFade = 1.0 - (seg / TRAIL_LENGTH) * 0.93
  /// speedFactor = 0.5 + speedNorm * 0.5
  /// brightness = trailFade * altBright * speedFactor
  void _drawParticles(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    for (final p in particles) {
      if (p.trailCount < 2) continue;

      // Compute speed norm from current trail head position
      // Use the most recent trail position to sample wind
      final (hx, hy, hz) = p.trailAt(0);
      // speedNorm: approximate from particle velocity (distance between
      // last two trail positions)
      double speedNorm = 0.0;
      if (p.trailCount >= 2) {
        final (h1x, h1y, h1z) = p.trailAt(1);
        final dx = hx - h1x;
        final dz = hz - h1z;
        final spd = sqrt(dx * dx + dz * dz);
        // Normalize: 0.22 is max speed in render units per frame at 60fps
        // (from prototype line 262: spd / 0.22)
        speedNorm = (spd / 0.22).clamp(0.0, 1.0);
      }

      for (int seg = 0; seg < p.trailCount - 1; seg++) {
        final (ax, ay, az) = p.trailAt(seg);
        final (bx, by, bz) = p.trailAt(seg + 1);

        final pa = _project3D(ax, ay, az, viewMatrix, focal, size);
        final pb = _project3D(bx, by, bz, viewMatrix, focal, size);

        // Skip segment if either endpoint is behind camera
        if (pa == null || pb == null) continue;

        // Altitude-based brightness (brighter at higher altitude)
        final altBright = 0.4 + (ay / domeH).clamp(0.0, 1.0) * 0.6;
        // Trail fade: newer segments are brighter
        final trailFade = 1.0 - (seg / DomeConstants.trailLength) * 0.93;
        // Speed factor (prototype line 274)
        final speedFactor = 0.5 + speedNorm * 0.5;
        final brightness =
            (trailFade * altBright * speedFactor).clamp(0.0, 1.0);

        _particlePaint.color =
            Colors.white.withValues(alpha: brightness);
        canvas.drawLine(pa, pb, _particlePaint);
      }
    }
  }

  // ─── User Marker ─────────────────────────────────────────────

  /// Draws the user position marker at dome center.
  ///
  /// Three elements ported from prototype lines 134-157, 238-239:
  /// 1. Inner filled dot (r=0.7, y=0.06)
  /// 2. Pulsing ring (r=1.1-1.5, y=0.05, pulsing opacity)
  /// 3. Accuracy halo (r=2.5-2.8, y=0.04, subtle pulsing opacity)
  void _drawUserMarker(
      Canvas canvas, Size size, vm.Matrix4 viewMatrix, double focal) {
    // Inner dot
    final dotCenter = _project3D(0, 0.06, 0, viewMatrix, focal, size);
    if (dotCenter != null) {
      // Compute projected radius by projecting an offset point
      final dotEdge = _project3D(0.7, 0.06, 0, viewMatrix, focal, size);
      final dotRadius = dotEdge != null
          ? (dotEdge - dotCenter).distance
          : 3.0;

      _markerFillPaint.color = Colors.white;
      canvas.drawCircle(dotCenter, dotRadius, _markerFillPaint);
    }

    // Pulsing ring (prototype line 238)
    final ringCenter = _project3D(0, 0.05, 0, viewMatrix, focal, size);
    if (ringCenter != null) {
      final ringOpacity = (0.6 + sin(time * 2.5) * 0.3).clamp(0.0, 1.0);

      // Inner radius 1.1, outer radius 1.5 -> average 1.3, stroke width difference
      final ringInner = _project3D(1.1, 0.05, 0, viewMatrix, focal, size);
      final ringOuter = _project3D(1.5, 0.05, 0, viewMatrix, focal, size);
      if (ringInner != null && ringOuter != null) {
        final innerR = (ringInner - ringCenter).distance;
        final outerR = (ringOuter - ringCenter).distance;
        final avgR = (innerR + outerR) / 2;
        final strokeW = (outerR - innerR).abs().clamp(0.5, 4.0);

        _markerStrokePaint.color =
            Colors.white.withValues(alpha: ringOpacity);
        _markerStrokePaint.strokeWidth = strokeW;
        _markerStrokePaint.style = PaintingStyle.stroke;
        canvas.drawCircle(ringCenter, avgR, _markerStrokePaint);
      }
    }

    // Accuracy halo (prototype line 239)
    final haloCenter = _project3D(0, 0.04, 0, viewMatrix, focal, size);
    if (haloCenter != null) {
      final haloOpacity =
          (0.08 + sin(time * 1.8 + 1) * 0.06).clamp(0.0, 1.0);

      final haloInner = _project3D(2.5, 0.04, 0, viewMatrix, focal, size);
      final haloOuter = _project3D(2.8, 0.04, 0, viewMatrix, focal, size);
      if (haloInner != null && haloOuter != null) {
        final innerR = (haloInner - haloCenter).distance;
        final outerR = (haloOuter - haloCenter).distance;
        final avgR = (innerR + outerR) / 2;
        final strokeW = (outerR - innerR).abs().clamp(0.5, 4.0);

        _markerStrokePaint.color =
            Colors.white.withValues(alpha: haloOpacity);
        _markerStrokePaint.strokeWidth = strokeW;
        _markerStrokePaint.style = PaintingStyle.stroke;
        canvas.drawCircle(haloCenter, avgR, _markerStrokePaint);
      }
    }
  }

  /// Exposes projection for testing. NOT for production use.
  @visibleForTesting
  Offset? project3DForTest(double x, double y, double z, Size size) {
    final viewMatrix = _buildViewMatrix(theta, phi, camR, domeH);
    final focal = _focalLength(size);
    return _project3D(x, y, z, viewMatrix, focal, size);
  }

  @override
  bool shouldRepaint(DomePainter oldDelegate) => true;
}
