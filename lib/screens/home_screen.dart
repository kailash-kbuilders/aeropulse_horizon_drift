import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../widgets/category_strip.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/food_card.dart';
import '../widgets/promo_card.dart';
import '../widgets/search_field.dart';
import 'food_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenTab});

  /// Lets the home screen ask the shell to switch tabs.
  final ValueChanged<int>? onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodItem> get _visibleItems {
    if (_query.trim().isEmpty) {
      return MenuData.popular;
    }
    final String q = _query.trim().toLowerCase();
    return MenuData.popular
        .where((FoodItem item) => item.name.toLowerCase().contains(q))
        .toList();
  }

  void _openDetail(FoodItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FoodDetailScreen(item: item)),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF232329),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<FoodItem> items = _visibleItems;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.85, -1.05),
                radius: 1.35,
                colors: <Color>[Color(0xFF34200F), AppColors.bg],
                stops: <double>[0.0, 0.62],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () => _showSnack('Menu is on the way'),
                  ),
                  const Spacer(),
                  _AvatarBadge(
                    onTap: () => _showSnack('Hi Alex, welcome back!'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Hi, Alex 👋',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                const TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: 'Good Food\nGood '),
                    TextSpan(
                      text: 'Mood!',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              SearchField(
                controller: _searchController,
                onChanged: (String value) => setState(() => _query = value),
                onFilterTap: () => _showSnack('Filters coming soon'),
              ),
              const SizedBox(height: 18),
              CategoryStrip(
                selectedIndex: _selectedCategory,
                onSelect: (int index) =>
                    setState(() => _selectedCategory = index),
              ),
              const SizedBox(height: 18),
              PromoCard(
                  onOrder: () => _openDetail(MenuData.spicyChickenBurger)),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  const Text(
                    'Popular Now',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSnack('More items coming soon'),
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No dish matches that search.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 208,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (BuildContext context, int index) {
                      final FoodItem item = items[index];
                      return FoodCard(
                        item: item,
                        onTap: () => _openDetail(item),
                        onAdd: () => _showSnack('${item.name} added to cart'),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FFFFFF), width: 1.2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF4A3423), Color(0xFF22160E)],
                ),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orangeLight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
