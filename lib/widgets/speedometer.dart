import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Digital + needle speed gauge. Everything is drawn, no assets.
class Speedometer extends StatelessWidget {
  const Speedometer({
    super.key,
    required this.speed,
    required this.gear,
    required this.drifting,
    this.maxSpeed = 260,
    this.size = 168,
  });

  final int speed;
  final String gear;
  final bool drifting;
  final int maxSpeed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = drifting ? const Color(0xFFFF9D3C) : const Color(0xFF22D3EE);
    return SizedBox(
      width: size,
      height: size * 0.78,
      child: CustomPaint(
        painter: _GaugePainter(speed: speed, maxSpeed: maxSpeed, accent: accent),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$speed',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'KM/H',
                style: TextStyle(
                  fontSize: size * 0.062,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                  color: const Color(0x99FFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  gear,
                  style: TextStyle(
                    fontSize: size * 0.07,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.speed, required this.maxSpeed, required this.accent});

  final int speed;
  final int maxSpeed;
  final Color accent;

  static const double _start = math.pi * 0.78;
  static const double _sweep = math.pi * 1.44;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = math.min(size.width, size.height) * 0.52;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x1AFFFFFF);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      _sweep,
      false,
      track,
    );

    final ratio = (speed / maxSpeed).clamp(0.0, 1.0);
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: _start,
        endAngle: _start + _sweep,
        colors: <Color>[accent.withValues(alpha: 0.35), accent],
        transform: GradientRotation(_start),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      _sweep * ratio,
      false,
      value,
    );

    // ticks
    final tick = Paint()
      ..strokeWidth = 2
      ..color = const Color(0x33FFFFFF)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i <= 10; i++) {
      final a = _start + _sweep * (i / 10);
      final outer = center + Offset(math.cos(a), math.sin(a)) * (radius - 2);
      final inner = center + Offset(math.cos(a), math.sin(a)) * (radius - (i % 5 == 0 ? 12 : 7));
      canvas.drawLine(inner, outer, tick);
    }

    // needle
    final na = _start + _sweep * ratio;
    final needle = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(na), math.sin(na)) * (radius - 16),
      needle,
    );
    canvas.drawCircle(center, 5, Paint()..color = accent);
    canvas.drawCircle(center, 2.4, Paint()..color = const Color(0xFF05070D));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.speed != speed || old.accent != accent;
}
