import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// A label on the left and an orange switch on the right.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rp(2)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rp(12),
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: context.rp(8)),
          Transform.scale(
            scale: context.rp(1).clamp(0.85, 1.15),
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.orange,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF3A3A42),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
