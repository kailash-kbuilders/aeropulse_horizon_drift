import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class SizeChip extends StatelessWidget {
  const SizeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: context.rp(14),
          vertical: context.rp(8),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(context.rp(10)),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: context.rp(10.5),
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
