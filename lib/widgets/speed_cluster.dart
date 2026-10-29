import 'package:flutter/material.dart';

/// Digital speed + gear + RPM arc, drawn to sit on top of the 3D scene.
class SpeedCluster extends StatelessWidget {
  const SpeedCluster({
    super.key,
    required this.speed,
    required this.gear,
    required this.rpm,
    required this.drifting,
    this.maxRpm = 8000,
    this.width = 210,
  });

  final int speed;
  final int gear;
  final int rpm;
  final bool drifting;
  final int maxRpm;
  final double width;

  @override
  Widget build(BuildContext context) {
    final Color accent = drifting ? const Color(0xFFFF9D3C) : const Color(0xFF22D3EE);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x66070C13),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 8,
            width: double.infinity,
            child: CustomPaint(
              painter: _RpmBar(rpm: rpm, maxRpm: maxRpm, accent: accent),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$speed',
                style: const TextStyle(
                  fontSize: 42,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'KM/H',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: 0.75)),
                ),
                child: Text(
                  gear == 0 ? 'N' : '$gear',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RpmBar extends CustomPainter {
  _RpmBar({required this.rpm, required this.maxRpm, required this.accent});

  final int rpm;
  final int maxRpm;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double ratio = (rpm / maxRpm).clamp(0.0, 1.0);
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(rrect, Paint()..color = const Color(0x22FFFFFF));

    final Rect fill = Rect.fromLTWH(0, 0, size.width * ratio, size.height);
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[accent.withValues(alpha: 0.5), accent],
      ).createShader(fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, const Radius.circular(4)),
      paint,
    );

    // redline marker at 82%
    final double x = size.width * 0.82;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = const Color(0xFFFF3D68)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_RpmBar old) => old.rpm != rpm;
}
