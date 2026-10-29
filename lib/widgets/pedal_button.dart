import 'package:flutter/material.dart';

/// A pedal-shaped hold button (gas / brake).
class PedalButton extends StatelessWidget {
  const PedalButton({
    super.key,
    required this.label,
    required this.onDown,
    required this.onUp,
    required this.active,
    required this.accent,
    this.width = 74,
    this.height = 116,
  });

  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final bool active;
  final Color accent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: active ? accent.withValues(alpha: 0.28) : const Color(0x1AFFFFFF),
          border: Border.all(
            color: active ? accent : const Color(0x33FFFFFF),
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 1),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox(height: 10),
            Column(
              children: List<Widget>.generate(4, (int i) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2.5),
                  width: width * 0.5,
                  height: 2,
                  color: active ? accent : const Color(0x44FFFFFF),
                );
              }),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : const Color(0xAAFFFFFF),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
