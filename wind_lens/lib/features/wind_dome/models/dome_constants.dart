import 'dart:math';

/// Constants for the Wind Dome 3D visualization.
///
/// All dome geometry is defined in dome-local render units that match the
/// React/THREE.js prototype exactly. Particle velocity is converted from
/// m/s to render-units/second via [velocityScale].
///
/// Pure Dart -- no Flutter imports needed.
class DomeConstants {
  // ─── Dome Geometry (render units) ──────────────────────────────

  /// Dome radius in render units (matches prototype DOME_R = 18).
  static const double domeR = 18.0;

  /// Dome height in render units (matches prototype DOME_H = 14).
  static const double domeH = 14.0;

  // ─── Real-World Mapping ────────────────────────────────────────

  /// Maximum altitude in meters that the dome top represents.
  ///
  /// Used by [DomeWindField.sample()] to convert render-space y
  /// to real-world altitude for wind layer interpolation.
  /// y=0 -> 0m (surface), y=domeH -> 1800m (between 1500m and 3000m layers).
  static const double maxAltitudeMeters = 1800.0;

  // ─── Simulation ───────────────────────────────────────────────

  /// Velocity conversion factor: render-units per m/s per second.
  ///
  /// Derived from prototype: 0.012 render-units per m/s per frame at 60fps.
  /// velocityScale = 0.012 * 60 = 0.72.
  /// Usage: x += wind.u * velocityScale * dt
  static const double velocityScale = 0.72;

  /// Base vertical drift rate in render-units per second.
  ///
  /// Derived from prototype: 0.002 per frame at 60fps.
  /// updraftBase = 0.002 * 60 = 0.12.
  static const double updraftBase = 0.12;

  /// Additional vertical drift per unit of normalized altitude, per second.
  ///
  /// Derived from prototype: 0.003 per frame at 60fps.
  /// updraftGradient = 0.003 * 60 = 0.18.
  static const double updraftGradient = 0.18;

  /// Number of trail segments per particle.
  static const int trailLength = 10;

  /// Initial (maximum) particle count.
  static const int particleCount = 2000;

  // ─── Camera Defaults ──────────────────────────────────────────

  /// Default horizontal orbit angle (radians).
  ///
  /// pi/6 ~ 30 degrees initial azimuth (prototype line 48).
  static final double defaultTheta = pi / 6;

  /// Default vertical orbit angle (radians).
  ///
  /// pi/2.8 ~ 64 degrees from horizontal, giving an oblique perspective
  /// (prototype line 48).
  static final double defaultPhi = pi / 2.8;

  /// Default camera orbit radius in render units.
  ///
  /// Computed as: domeR * 2.8 = 50.4 (prototype line 50: CAM_R = DOME_R * 2.8).
  static const double camR = domeR * 2.8;

  /// Vertical FOV in degrees (prototype line 45: PerspectiveCamera(48, ...)).
  static const double fovDegrees = 48.0;

  // ─── Camera Orbit Bounds ──────────────────────────────────────

  /// Minimum phi (most top-down view). Prototype line 67.
  static const double phiMin = 0.15;

  /// Maximum phi (most oblique view). Prototype line 67.
  static final double phiMax = pi * 0.46;

  /// Minimum camera orbit radius (closest zoom). domeR * 1.5 = 27.0.
  static const double camRMin = domeR * 1.5;

  /// Maximum camera orbit radius (furthest zoom). domeR * 5.0 = 90.0.
  static const double camRMax = domeR * 5.0;

  // ─── Wireframe ────────────────────────────────────────────────

  /// Number of latitude rings in wireframe (prototype line 171).
  static const int latRings = 8;

  /// Number of longitude meridians in wireframe (prototype line 189).
  static const int lonMeridians = 16;

  // ─── Dome Sizing ────────────────────────────────────────────

  /// Conversion factor: meters per render unit.
  ///
  /// Calibrated so 1000m (default dome size) maps to domeR (18) render units.
  /// 1000.0 / 18.0 = ~55.56.
  static const double metersPerRenderUnit = 1000.0 / domeR;

  // ─── Ground Disc ────────────────────────────────────────────

  /// Number of segments for the ground disc polygon.
  static const int groundDiscSegments = 64;

  /// Fill opacity for the ground disc (black).
  static const double groundDiscFillOpacity = 0.55;

  /// Stroke opacity for the ground disc edge (white).
  static const double groundDiscStrokeOpacity = 0.35;

  /// Stroke width for the ground disc edge.
  static const double groundDiscStrokeWidth = 1.0;

  // ─── Compass Rose ─────────────────────────────────────────────

  /// Radius multiplier for compass labels (placed just outside dome edge).
  static const double compassLabelRadiusMultiplier = 1.12;

  /// Y coordinate of compass labels on the ground plane.
  static const double compassLabelGroundY = 0.03;

  /// Font size for the North label.
  static const double compassNorthFontSize = 13.0;

  /// Font size for other cardinal direction labels (S, E, W).
  static const double compassCardinalFontSize = 11.0;

  /// Length of compass tick marks in render units (inward from dome edge).
  static const double compassTickLength = 2.5;

  /// Private constructor to prevent instantiation.
  DomeConstants._();
}
