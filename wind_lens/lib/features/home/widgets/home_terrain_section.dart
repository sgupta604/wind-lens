import 'package:flutter/material.dart';

import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';

import 'home_altitude_rail.dart';
import 'home_compass_bar.dart';
import 'home_particle_painter.dart';

/// The terrain panorama section that fills remaining vertical space.
///
/// Contains a [Stack] with layers (bottom to top):
/// 1. Grid overlay (faint lines)
/// 2. Terrain silhouette (procedural bezier)
/// 3. Animated particles
/// 4. Altitude rail (right edge)
/// 5. Compass bar (bottom edge)
///
/// Decorative painters are wrapped in [ExcludeSemantics] since they
/// provide no meaningful information to screen readers.
///
/// Stateful so it owns the [HomeParticleState] which must survive
/// across painter recreations (Flutter creates a new painter each build).
class HomeTerrainSection extends StatefulWidget {
  /// The animation controller driving particle rendering.
  final AnimationController particleController;

  /// Sensor notifiers for compass heading (used by compass bar).
  final SensorNotifiers sensorNotifiers;

  const HomeTerrainSection({
    super.key,
    required this.particleController,
    required this.sensorNotifiers,
  });

  @override
  State<HomeTerrainSection> createState() => _HomeTerrainSectionState();
}

class _HomeTerrainSectionState extends State<HomeTerrainSection> {
  final HomeParticleState _particleState = HomeParticleState();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: false,
      child: Stack(
        children: [
          // Layer 0: Grid overlay
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _HomeGridPainter(),
              ),
            ),
          ),

          // Layer 1: Terrain silhouette
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: HomeTerrainPainter(),
              ),
            ),
          ),

          // Layer 2: Animated particles
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: HomeParticlePainter(
                  state: _particleState,
                  animation: widget.particleController,
                ),
              ),
            ),
          ),

          // Layer 3: Altitude rail (right edge)
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: HomeAltitudeRail(),
          ),

          // Layer 4: Compass bar (bottom edge)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: HomeCompassBar(
              headingNotifier: widget.sensorNotifiers.heading,
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint grid overlay behind the terrain and particles.
///
/// Draws horizontal and vertical lines at 48px intervals with
/// very low opacity white (0.025). Static -- never repaints.
class _HomeGridPainter extends CustomPainter {
  final Paint _gridPaint = Paint()
    ..color = const Color.fromRGBO(255, 255, 255, 0.025)
    ..strokeWidth = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 48.0;

    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  @override
  bool shouldRepaint(_HomeGridPainter oldDelegate) => false;
}

/// Procedural terrain silhouette painter.
///
/// Draws a decorative mountain/terrain shape using bezier curves.
/// Accepts an optional [HorizonProfile] for future swap-in with
/// real terrain data from HeyWhatsThat.
///
/// When [profile] is null (default), uses a hardcoded decorative path.
/// When non-null, the path would be generated from real elevation data.
///
/// Fill: LinearGradient #2a2a2a (ridge) → #111111 (base).
/// Ridge glow: 2-pass — soft ambient (width 6, 4% white) then crisp (width 1, #666).
/// Horizon line: 1px at height * 0.60, rgba(255,255,255,0.08).
/// Sky atmosphere: subtle radial gradient in upper portion.
class HomeTerrainPainter extends CustomPainter {
  /// Optional horizon profile for real terrain data (future).
  final HorizonProfile? profile;

  HomeTerrainPainter({this.profile});

  @override
  void paint(Canvas canvas, Size size) {
    // Sky atmosphere — subtle radial gradient in upper sky area
    final atmospherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.3),
        radius: 0.6,
        colors: [
          const Color.fromRGBO(255, 255, 255, 0.02),
          const Color.fromRGBO(255, 255, 255, 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.6),
      atmospherePaint,
    );

    // Horizon reference line at 60% down
    final horizonPaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.08)
      ..strokeWidth = 1.0;
    final horizonY = size.height * 0.60;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      horizonPaint,
    );

    // Terrain fill — gradient from ridge (#2a2a2a) to base (#111111)
    final path = _buildTerrainPath(size);
    final bounds = path.getBounds();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2a2a2a), Color(0xFF111111)],
      ).createShader(bounds)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Ridge glow — pass 1: soft ambient
    final ridgePath = _buildRidgePath(size);
    final glowPaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(ridgePath, glowPaint);

    // Ridge glow — pass 2: crisp highlight
    final ridgePaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(ridgePath, ridgePaint);
  }

  /// Terrain moved up — tallest peak at ~35% from top (was 30% from bottom).
  Path _buildTerrainPath(Size size) {
    final path = Path();
    path.moveTo(0, size.height); // bottom-left

    // Left flat ground -> first rise
    path.lineTo(0, size.height * 0.66);
    path.quadraticBezierTo(
      size.width * 0.08, size.height * 0.64,
      size.width * 0.15, size.height * 0.55,
    );
    // Broad hill
    path.cubicTo(
      size.width * 0.20, size.height * 0.38,
      size.width * 0.28, size.height * 0.33,
      size.width * 0.35, size.height * 0.48,
    );
    // Valley / horizon dip
    path.quadraticBezierTo(
      size.width * 0.42, size.height * 0.58,
      size.width * 0.48, size.height * 0.53,
    );
    // First peak
    path.cubicTo(
      size.width * 0.52, size.height * 0.43,
      size.width * 0.56, size.height * 0.28,
      size.width * 0.60, size.height * 0.31,
    );
    // Jagged ridge cluster
    path.lineTo(size.width * 0.63, size.height * 0.41);
    path.lineTo(size.width * 0.66, size.height * 0.35); // tallest peak (~35%)
    path.lineTo(size.width * 0.69, size.height * 0.38);
    path.lineTo(size.width * 0.72, size.height * 0.27); // secondary peak
    path.lineTo(size.width * 0.75, size.height * 0.39);
    // Taper to right
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.53,
      size.width * 1.0, size.height * 0.62,
    );
    path.lineTo(size.width, size.height); // bottom-right
    path.close();

    return path;
  }

  Path _buildRidgePath(Size size) {
    final ridgePath = Path();
    ridgePath.moveTo(0, size.height * 0.66);
    ridgePath.quadraticBezierTo(
      size.width * 0.08, size.height * 0.64,
      size.width * 0.15, size.height * 0.55,
    );
    ridgePath.cubicTo(
      size.width * 0.20, size.height * 0.38,
      size.width * 0.28, size.height * 0.33,
      size.width * 0.35, size.height * 0.48,
    );
    ridgePath.quadraticBezierTo(
      size.width * 0.42, size.height * 0.58,
      size.width * 0.48, size.height * 0.53,
    );
    ridgePath.cubicTo(
      size.width * 0.52, size.height * 0.43,
      size.width * 0.56, size.height * 0.28,
      size.width * 0.60, size.height * 0.31,
    );
    ridgePath.lineTo(size.width * 0.63, size.height * 0.41);
    ridgePath.lineTo(size.width * 0.66, size.height * 0.35);
    ridgePath.lineTo(size.width * 0.69, size.height * 0.38);
    ridgePath.lineTo(size.width * 0.72, size.height * 0.27);
    ridgePath.lineTo(size.width * 0.75, size.height * 0.39);
    ridgePath.quadraticBezierTo(
      size.width * 0.85, size.height * 0.53,
      size.width * 1.0, size.height * 0.62,
    );
    return ridgePath;
  }

  @override
  bool shouldRepaint(HomeTerrainPainter oldDelegate) => false;
}
