import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The small frosted circle used for the menu button, the back button and the
/// favourite hearts.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.background = const Color(0x14FFFFFF),
    this.iconColor = AppColors.textPrimary,
    this.borderColor = AppColors.stroke,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
