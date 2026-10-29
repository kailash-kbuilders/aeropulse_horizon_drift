import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/car_model.dart';

/// Side-profile of the car, drawn from a parametric path so all four cars read
/// differently without shipping any image assets.
class CarSilhouette extends StatelessWidget {
  const CarSilhouette({
    super.key,
    required this.car,
    required this.paint,
    required this.rim,
    this.finish = 'gloss',
  });

  final CarModel car;
  final Color paint;
  final int rim;
  final String finish;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CarPainter(car: car, bodyColor: paint, rim: rim, finish: finish),
      size: Size.infinite,
    );
  }
}

class _Profile {
  const _Profile({
    required this.noseY,
    required this.tailY,
    required this.roofFront,
    required this.roofBack,
    required this.roofY,
    required this.ride,
    required this.wheelR,
  });

  final double noseY;
  final double tailY;
  final double roofFront;
  final double roofBack;
  final double roofY;
  final double ride;
  final double wheelR;
}

class _CarPainter extends CustomPainter {
  _CarPainter({
    required this.car,
    required this.bodyColor,
    required this.rim,
    required this.finish,
  });

  final CarModel car;
  final Color bodyColor;
  final int rim;
  final String finish;

  _Profile get _p {
    switch (car.carClass) {
      case CarClass.sports:
        return const _Profile(noseY: 0.62, tailY: 0.58, roofFront: 0.36, roofBack: 0.70, roofY: 0.30, ride: 0.76, wheelR: 0.135);
      case CarClass.muscle:
        return const _Profile(noseY: 0.58, tailY: 0.54, roofFront: 0.30, roofBack: 0.68, roofY: 0.26, ride: 0.78, wheelR: 0.155);
      case CarClass.hyper:
        return const _Profile(noseY: 0.66, tailY: 0.60, roofFront: 0.38, roofBack: 0.72, roofY: 0.34, ride: 0.80, wheelR: 0.145);
      case CarClass.rally:
        return const _Profile(noseY: 0.54, tailY: 0.52, roofFront: 0.28, roofBack: 0.74, roofY: 0.22, ride: 0.70, wheelR: 0.165);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = _p;

    // ground shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.86), width: w * 0.82, height: h * 0.09),
      shadow,
    );

    final body = Path()
      ..moveTo(w * 0.05, h * p.noseY)
      ..lineTo(w * 0.10, h * (p.noseY - 0.10))
      ..lineTo(w * 0.22, h * (p.noseY - 0.14))
      ..lineTo(w * p.roofFront, h * p.roofY)
      ..lineTo(w * p.roofBack, h * p.roofY)
      ..lineTo(w * 0.88, h * (p.tailY - 0.10))
      ..lineTo(w * 0.96, h * p.tailY)
      ..lineTo(w * 0.96, h * (p.ride - 0.02))
      ..lineTo(w * 0.05, h * (p.ride - 0.02))
      ..close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(bodyColor, Colors.white, finish == 'metallic' ? 0.45 : 0.22)!,
          bodyColor,
          Color.lerp(bodyColor, Colors.black, 0.35)!,
        ],
      ).createShader(Rect.fromLTWH(0, h * p.roofY, w, h * (p.ride - p.roofY)));

    canvas.drawPath(body, bodyPaint);

    // window
    final glass = Path()
      ..moveTo(w * (p.roofFront + 0.02), h * (p.roofY + 0.015))
      ..lineTo(w * (p.roofBack - 0.02), h * (p.roofY + 0.015))
      ..lineTo(w * (p.roofBack - 0.06), h * (p.roofY + 0.075))
      ..lineTo(w * (p.roofFront + 0.04), h * (p.roofY + 0.075))
      ..close();
    canvas.drawPath(glass, Paint()..color = const Color(0xFF0B1220).withValues(alpha: 0.92));

    // spoiler on everything but the rally car
    if (car.carClass != CarClass.rally) {
      final wing = Paint()..color = Color.lerp(bodyColor, Colors.black, 0.55)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.80, h * (p.tailY - 0.20), w * 0.17, h * 0.035),
          const Radius.circular(3),
        ),
        wing,
      );
      canvas.drawRect(Rect.fromLTWH(w * 0.84, h * (p.tailY - 0.18), w * 0.02, h * 0.08), wing);
    }

    // wheels
    final tyre = Paint()..color = const Color(0xFF0D0F13);
    final rimPaint = Paint()..color = _rimColor();
    final r = h * p.wheelR;

    for (final cx in <double>[w * 0.25, w * 0.76]) {
      final center = Offset(cx, h * p.ride - r * 0.35);
      canvas.drawCircle(center, r, tyre);
      canvas.drawCircle(center, r * 0.52, rimPaint);
      if (rim == 2) {
        final spoke = Paint()
          ..color = rimPaint.color
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final angle = i * 3.14159 / 4;
          canvas.drawLine(
            center + Offset(math.cos(angle) * r * 0.5, math.sin(angle) * r * 0.5),
            center - Offset(math.cos(angle) * r * 0.5, math.sin(angle) * r * 0.5),
            spoke,
          );
        }
      }
    }
  }

  Color _rimColor() {
    switch (rim) {
      case 1:
        return const Color(0xFFD8B45A);
      case 2:
        return const Color(0xFF2A2F3A);
      default:
        return const Color(0xFFC9D3E0);
    }
  }

  @override
  bool shouldRepaint(_CarPainter old) =>
      old.bodyColor != bodyColor || old.rim != rim || old.car.id != car.id || old.finish != finish;
}
