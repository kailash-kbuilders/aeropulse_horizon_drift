import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Top-down map of the circuit with a live marker for the player's car.
class Minimap extends StatelessWidget {
  const Minimap({
    super.key,
    required this.path,
    required this.car,
    required this.accent,
    this.heading = 0,
    this.size = const Size(190, 118),
  });

  /// Track centreline in world coordinates (x, z).
  final List<Offset> path;

  /// Car position in the same world coordinates.
  final Offset car;
  final double heading;
  final Color accent;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _MinimapPainter(
          path: path,
          car: car,
          heading: heading,
          accent: accent,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.path,
    required this.car,
    required this.heading,
    required this.accent,
  });

  final List<Offset> path;
  final Offset car;
  final double heading;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 3) return;

    double minX = path.first.dx, maxX = path.first.dx;
    double minY = path.first.dy, maxY = path.first.dy;
    for (final Offset p in path) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    for (final Offset p in <Offset>[car]) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final double pad = 10;
    final double spanX = math.max(1, maxX - minX);
    final double spanY = math.max(1, maxY - minY);
    final double scale = math.min(
      (size.width - pad * 2) / spanX,
      (size.height - pad * 2) / spanY,
    );
    final double offX = (size.width - spanX * scale) / 2;
    final double offY = (size.height - spanY * scale) / 2;

    Offset project(Offset p) => Offset(
          offX + (p.dx - minX) * scale,
          offY + (p.dy - minY) * scale,
        );

    final Path line = Path();
    for (int i = 0; i < path.length; i++) {
      final Offset p = project(path[i]);
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    line.close();

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x33FFFFFF),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = accent.withValues(alpha: 0.85),
    );

    // start / finish tick
    final Offset startP = project(path.first);
    canvas.drawCircle(startP, 3.2, Paint()..color = const Color(0xFF3DFF9A));

    // car marker
    final Offset carP = project(car);
    canvas.save();
    canvas.translate(carP.dx, carP.dy);
    canvas.rotate(heading);
    final Path arrow = Path()
      ..moveTo(0, -6)
      ..lineTo(4.5, 5)
      ..lineTo(0, 2.6)
      ..lineTo(-4.5, 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white);
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.car != car || old.heading != heading || old.path.length != path.length;
}
