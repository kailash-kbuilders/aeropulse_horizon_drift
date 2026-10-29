import 'package:flutter/material.dart';

/// A round glassmorphism control that reports press / release so the engine can
/// hold an input for as long as the player holds the button.
class HoldButton extends StatelessWidget {
  const HoldButton({
    super.key,
    required this.icon,
    required this.onDown,
    required this.onUp,
    required this.active,
    this.size = 68,
    this.accent = const Color(0xFF22D3EE),
    this.label,
  });

  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final bool active;
  final double size;
  final Color accent;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent.withValues(alpha: 0.30) : const Color(0x1AFFFFFF),
          border: Border.all(
            color: active ? accent : const Color(0x33FFFFFF),
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 2),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: size * 0.42, color: active ? Colors.white : const Color(0xCCFFFFFF)),
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0x99FFFFFF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
