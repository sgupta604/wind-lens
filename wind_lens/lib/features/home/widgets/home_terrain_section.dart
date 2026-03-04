import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/providers/data_providers.dart';
import 'package:wind_lens/core/providers/sensor_providers.dart';

import 'home_altitude_rail.dart';
import 'home_compass_bar.dart';
import 'home_particle_painter.dart';

/// The terrain panorama section that fills remaining vertical space.
///
/// Contains a [Stack] with layers (bottom to top):
/// 1. Grid overlay (faint lines)
/// 2. Terrain silhouette (procedural bezier or real HeyWhatsThat data)
/// 3. Animated particles
/// 4. Altitude rail (right edge)
/// 5. Compass bar (bottom edge)
/// 6. Loading indicator (during terrain fetch)
///
/// Decorative painters are wrapped in [ExcludeSemantics] since they
/// provide no meaningful information to screen readers.
///
/// ConsumerStatefulWidget so it can watch [horizonProfileProvider] and
/// own [HomeParticleState] which must survive across painter recreations
/// (Flutter creates a new painter each build).
class HomeTerrainSection extends ConsumerStatefulWidget {
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
  ConsumerState<HomeTerrainSection> createState() =>
      _HomeTerrainSectionState();
}

class _HomeTerrainSectionState extends ConsumerState<HomeTerrainSection> {
  final HomeParticleState _particleState = HomeParticleState();

  @override
  Widget build(BuildContext context) {
    final horizonAsync = ref.watch(horizonProfileProvider);
    final profile = horizonAsync.valueOrNull;
    final isLoading = horizonAsync is AsyncLoading;

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
                painter: HomeTerrainPainter(profile: profile),
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

          // Layer 5: Loading indicator (during terrain fetch)
          if (isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: Text(
                  'Computing terrain...',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 10,
                    color: const Color(0xFF888888),
                  ),
                ),
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

/// Terrain silhouette painter with real data and procedural fallback.
///
/// When [profile] is non-null, draws a terrain silhouette generated from
/// real HeyWhatsThat elevation data (360 bearing-to-elevation entries).
/// When [profile] is null, uses a hardcoded decorative bezier path.
///
/// Fill: LinearGradient #2a2a2a (ridge) -> #111111 (base).
/// Ridge glow: 2-pass -- soft ambient (width 6, 4% white) then crisp (width 1, #666).
/// Horizon line: 1px at height * 0.60, rgba(255,255,255,0.08).
/// Sky atmosphere: subtle radial gradient in upper portion.
class HomeTerrainPainter extends CustomPainter {
  /// Optional horizon profile for real terrain data.
  final HorizonProfile? profile;

  HomeTerrainPainter({this.profile});

  @override
  void paint(Canvas canvas, Size size) {
    // Sky atmosphere -- subtle radial gradient in upper sky area
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

    // Terrain fill -- gradient from ridge (#2a2a2a) to base (#111111)
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

    // Ridge glow -- pass 1: soft ambient
    final ridgePath = _buildRidgePath(size);
    final glowPaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(ridgePath, glowPaint);

    // Ridge glow -- pass 2: crisp highlight
    final ridgePaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(ridgePath, ridgePaint);
  }

  /// Builds the filled terrain path.
  ///
  /// When [profile] is non-null, generates path from real elevation data.
  /// When null, falls back to the hardcoded procedural bezier path.
  Path _buildTerrainPath(Size size) {
    if (profile != null) {
      return _buildProfileTerrainPath(size, profile!);
    }
    return _buildProceduralTerrainPath(size);
  }

  /// Builds the ridge (top edge) path for glow rendering.
  ///
  /// When [profile] is non-null, generates ridge from real elevation data.
  /// When null, falls back to the hardcoded procedural bezier ridge.
  Path _buildRidgePath(Size size) {
    if (profile != null) {
      return _buildProfileRidgePath(size, profile!);
    }
    return _buildProceduralRidgePath(size);
  }

  // ---- Real data paths from HorizonProfile ----

  /// Elevation range constants for mapping elevation angles to Y coordinates.
  ///
  /// Elevations below [_minElev] are clamped to the ground ceiling.
  /// Elevations above [_maxElev] are clamped to the sky floor.
  static const _minElev = -5.0;
  static const _maxElev = 30.0;

  /// Fraction of canvas height reserved as sky headroom at top.
  static const _skyFloor = 0.20;

  /// Fraction of canvas height where ground starts at bottom.
  static const _groundCeiling = 0.85;

  /// Maps an elevation angle to a Y coordinate on the canvas.
  ///
  /// Higher elevation = higher on screen (lower Y value).
  /// Clamps to [_minElev, _maxElev] range.
  double _elevToY(double elevation, double height) {
    final clamped = elevation.clamp(_minElev, _maxElev);
    final t = (clamped - _minElev) / (_maxElev - _minElev);
    // t=0 (min elev) -> groundCeiling, t=1 (max elev) -> skyFloor
    return height * (_groundCeiling - t * (_groundCeiling - _skyFloor));
  }

  /// Builds a filled terrain path from real elevation data.
  ///
  /// Loops 0-360 degrees, queries [profile.getElevationAtBearing] for
  /// each degree, and maps to canvas coordinates. The path is closed
  /// along the bottom edge.
  Path _buildProfileTerrainPath(Size size, HorizonProfile p) {
    final path = Path();
    path.moveTo(0, size.height); // bottom-left

    for (int bearing = 0; bearing < 360; bearing++) {
      final elev = p.getElevationAtBearing(bearing.toDouble());
      final x = (bearing / 360) * size.width;
      final y = _elevToY(elev, size.height);

      if (bearing == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, _elevToY(
      p.getElevationAtBearing(0), size.height,
    )); // wrap to bearing 0
    path.lineTo(size.width, size.height); // bottom-right
    path.close();

    return path;
  }

  /// Builds a ridge (top edge only) path from real elevation data.
  ///
  /// Same mapping as [_buildProfileTerrainPath] but without the bottom
  /// edge closure -- used for the glow/highlight stroke.
  Path _buildProfileRidgePath(Size size, HorizonProfile p) {
    final ridgePath = Path();

    for (int bearing = 0; bearing < 360; bearing++) {
      final elev = p.getElevationAtBearing(bearing.toDouble());
      final x = (bearing / 360) * size.width;
      final y = _elevToY(elev, size.height);

      if (bearing == 0) {
        ridgePath.moveTo(x, y);
      } else {
        ridgePath.lineTo(x, y);
      }
    }

    // Close to bearing 0 at the right edge
    ridgePath.lineTo(size.width, _elevToY(
      p.getElevationAtBearing(0), size.height,
    ));

    return ridgePath;
  }

  // ---- Procedural bezier paths (fallback when no profile) ----

  /// Hardcoded decorative terrain path with bezier curves.
  ///
  /// Tallest peak at ~35% from top (was 30% from bottom).
  Path _buildProceduralTerrainPath(Size size) {
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

  /// Hardcoded decorative ridge path with bezier curves.
  Path _buildProceduralRidgePath(Size size) {
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
  bool shouldRepaint(HomeTerrainPainter oldDelegate) =>
      profile != oldDelegate.profile;
}
