import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'empty_tab_screen.dart';
import 'home_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      HomeScreen(onOpenTab: _select),
      const EmptyTabScreen(
        icon: Icons.local_offer_rounded,
        title: 'No offers right now',
        message: 'Fresh deals drop every week. Check back soon.',
      ),
      const EmptyTabScreen(
        icon: Icons.receipt_long_rounded,
        title: 'No orders yet',
        message: 'Your past orders will appear here once you order.',
      ),
      const EmptyTabScreen(
        icon: Icons.favorite_rounded,
        title: 'Nothing saved yet',
        message: 'Tap the heart on any dish to save it here.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SafeArea(
          top: false,
          child: AppBottomNav(currentIndex: _index, onSelect: _select),
        ),
      ),
    );
  }
}
