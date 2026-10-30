import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../theme/app_theme.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(MenuData.categories.length, (int i) {
        return _CategoryTile(
          label: MenuData.categories[i].label,
          icon: MenuData.categories[i].icon,
          selected: i == selectedIndex,
          onTap: () => onSelect(i),
        );
      }),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: selected ? const Color(0x33FF7A18) : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
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
              size: 26,
              color: selected ? AppColors.orange : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
