import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class NavDestination {
  const NavDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const List<NavDestination> kDestinations = <NavDestination>[
  NavDestination(label: 'Home', icon: Icons.home_rounded),
  NavDestination(label: 'Offers', icon: Icons.local_offer_rounded),
  NavDestination(label: 'Orders', icon: Icons.receipt_long_rounded),
  NavDestination(label: 'Favorite', icon: Icons.favorite_rounded),
];

/// The floating pill navigation bar.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.rp(68),
      decoration: BoxDecoration(
        color: const Color(0xFF15151A),
        borderRadius: BorderRadius.circular(context.rp(26)),
        border: Border.all(color: AppColors.stroke),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(kDestinations.length, (int i) {
          final NavDestination d = kDestinations[i];
          final bool selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    d.icon,
                    size: context.rp(21),
                    color: selected ? AppColors.orange : AppColors.textTertiary,
                  ),
                  SizedBox(height: context.rp(4)),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        d.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: context.rp(9.5),
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? AppColors.orange
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
