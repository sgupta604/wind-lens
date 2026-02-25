import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// A compass widget that displays the current heading direction.
///
/// Shows a circular compass dial with cardinal directions (N, S, E, W)
/// that rotates based on the device heading. Uses glassmorphism styling
/// consistent with other UI elements in the app.
///
/// The dial rotates so that the cardinal direction labels stay fixed
/// relative to the real world, while a red indicator at the top shows
/// which direction the camera is pointing.
///
/// Example:
/// ```dart
/// CompassWidget(heading: 45.0) // Facing NE
/// ```
class CompassWidget extends StatelessWidget {
  /// Current compass heading in degrees (0-360, 0 = North).
  final double heading;

  /// Creates a CompassWidget.
  ///
  /// [heading] should be a value between 0 and 360 degrees,
  /// where 0/360 is North, 90 is East, 180 is South, 270 is West.
  const CompassWidget({
    super.key,
    required this.heading,
  });

  /// Diameter of the compass widget.
  static const double _diameter = 68.0;

  /// Border radius (half diameter for circular shape).
  static const double _borderRadius = 34.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: _diameter,
            height: _diameter,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: CustomPaint(
              painter: CompassPainter(heading: heading),
              size: Size(_diameter, _diameter),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering the compass dial.
///
/// Draws:
/// - Outer ring with tick marks
/// - Cardinal direction labels (N in red, S/E/W in white)
/// - Direction indicator (red triangle at top)
///
/// The dial rotates by -heading degrees so that labels stay fixed
/// relative to the real world (N points to actual North).
class CompassPainter extends CustomPainter {
  /// Current compass heading in degrees.
  final double heading;

  /// Creates a CompassPainter with the given heading.
  CompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // Padding from edge

    // Draw outer ring
    _drawOuterRing(canvas, center, radius);

    // Draw tick marks (every 30 degrees)
    _drawTickMarks(canvas, center, radius);

    // Draw cardinal labels (rotated by -heading)
    _drawCardinalLabels(canvas, center, radius);

    // Draw direction indicator (fixed at top)
    _drawDirectionIndicator(canvas, center, radius);
  }

  /// Draws the outer ring of the compass.
  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, paint);
  }

  /// Draws tick marks around the compass (every 30 degrees).
  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * pi / 180);

    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180;
      final tickLength = (i % 3 == 0) ? 6.0 : 3.0; // Longer ticks at cardinals
      final innerRadius = radius - tickLength;

      final start = Offset(
        innerRadius * sin(angle),
        -innerRadius * cos(angle),
      );
      final end = Offset(
        radius * sin(angle),
        -radius * cos(angle),
      );

      canvas.drawLine(start, end, paint);
    }

    canvas.restore();
  }

  /// Draws the cardinal direction labels (N, S, E, W).
  void _drawCardinalLabels(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * pi / 180);

    const labelOffset = 12.0; // Distance from center for labels
    final labelRadius = radius - labelOffset;

    // Cardinal directions: N (top), E (right), S (bottom), W (left)
    final cardinals = [
      _CardinalLabel('N', 0, Colors.red),
      _CardinalLabel('E', 90, Colors.white.withValues(alpha: 0.9)),
      _CardinalLabel('S', 180, Colors.white.withValues(alpha: 0.9)),
      _CardinalLabel('W', 270, Colors.white.withValues(alpha: 0.9)),
    ];

    for (final cardinal in cardinals) {
      final angle = cardinal.degrees * pi / 180;
      final offset = Offset(
        labelRadius * sin(angle),
        -labelRadius * cos(angle),
      );

      _drawLabel(canvas, cardinal.label, offset, cardinal.color,
          isNorth: cardinal.label == 'N');
    }

    canvas.restore();
  }

  /// Draws a single label at the given offset.
  void _drawLabel(Canvas canvas, String label, Offset offset, Color color,
      {bool isNorth = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: isNorth ? 14.0 : 12.0,
          fontWeight: isNorth ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Center the text at the offset
    final textOffset = Offset(
      offset.dx - textPainter.width / 2,
      offset.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  /// Draws the direction indicator (red triangle at top).
  void _drawDirectionIndicator(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Triangle pointing down at the top of the compass
    final triangleSize = 8.0;
    final topY = center.dy - radius + 2;

    final path = Path()
      ..moveTo(center.dx, topY + triangleSize) // Bottom point
      ..lineTo(center.dx - triangleSize / 2, topY) // Top left
      ..lineTo(center.dx + triangleSize / 2, topY) // Top right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.heading != heading;
  }
}

/// Helper class for cardinal direction label data.
class _CardinalLabel {
  final String label;
  final double degrees;
  final Color color;

  const _CardinalLabel(this.label, this.degrees, this.color);
}
