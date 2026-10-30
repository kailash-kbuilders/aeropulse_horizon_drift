import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// The five square category tiles under the search bar.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final double gap = context.rp(8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < MenuData.categories.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _CategoryTile(
              label: MenuData.categories[i].label,
              icon: MenuData.categories[i].icon,
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double size = constraints.maxWidth;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: selected ? const Color(0x33FF7A18) : AppColors.surface,
                  borderRadius: BorderRadius.circular(size * 0.31),
                  border: Border.all(
                    color: selected ? AppColors.orange : AppColors.stroke,
                    width: selected ? 1.4 : 1,
                  ),
                  boxShadow: selected
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x4DFF7A18),
                            blurRadius: 18,
                            spreadRadius: -6,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: size * 0.42,
                  color: selected ? AppColors.orange : AppColors.textSecondary,
                ),
              );
            },
          ),
          SizedBox(height: context.rp(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: context.rp(11),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color:
                    selected ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
