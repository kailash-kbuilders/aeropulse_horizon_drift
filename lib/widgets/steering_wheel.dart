import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draggable steering wheel. Drag left/right and it reports -1..1; letting go
/// springs the wheel back to centre.
class SteeringWheel extends StatefulWidget {
  const SteeringWheel({
    super.key,
    required this.onChanged,
    required this.accent,
    this.size = 108,
  });

  /// -1 (full left) .. 1 (full right)
  final ValueChanged<double> onChanged;
  final Color accent;
  final double size;

  @override
  State<SteeringWheel> createState() => _SteeringWheelState();
}

class _SteeringWheelState extends State<SteeringWheel>
    with SingleTickerProviderStateMixin {
  static const double _maxAngle = 2.1; // radians at full lock

  late final AnimationController _controller;
  Animation<double>? _returnAnimation;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        final Animation<double>? anim = _returnAnimation;
        if (anim == null) return;
        setState(() => _angle = anim.value);
        widget.onChanged(_angle / _maxAngle);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _release() {
    _returnAnimation = Tween<double>(begin: _angle, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _controller.stop(),
      onHorizontalDragUpdate: (DragUpdateDetails d) {
        setState(() {
          _angle = (_angle + d.delta.dx * 0.014).clamp(-_maxAngle, _maxAngle);
        });
        widget.onChanged(_angle / _maxAngle);
      },
      onHorizontalDragEnd: (_) => _release(),
      onHorizontalDragCancel: _release,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _WheelPainter(angle: _angle, accent: widget.accent),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.angle, required this.accent});

  final double angle;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2 - 3;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0xCC0E141C);
    canvas.drawCircle(Offset.zero, r, rim);

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.75),
    );

    final Paint spoke = Paint()
      ..color = const Color(0xFFB9C4D2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (final double a in <double>[0, math.pi * 0.75, math.pi * 1.25]) {
      canvas.drawLine(
        Offset(math.cos(a) * r * 0.32, math.sin(a) * r * 0.32),
        Offset(math.cos(a) * r * 0.94, math.sin(a) * r * 0.94),
        spoke,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      r * 0.3,
      Paint()..color = const Color(0xFF141A22),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.8),
    );

    // top marker so the wheel angle is readable
    canvas.drawLine(
      Offset(0, -r * 0.92),
      Offset(0, -r * 0.62),
      Paint()
        ..color = accent
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle;
}
