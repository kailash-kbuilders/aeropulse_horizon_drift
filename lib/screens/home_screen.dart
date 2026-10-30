import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<FoodItem> items = _visibleItems;
    final double pad = context.rp(20);
    final double cardWidth = context.rp(150);
    final double cardHeight = context.rp(216);

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Responsive.maxContentWidth,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  pad,
                  context.rp(6),
                  pad,
                  context.rp(120),
                ),
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleIconButton(
                        icon: Icons.menu_rounded,
                        size: context.rp(44),
                        iconSize: context.rp(20),
                        onTap: () => _showSnack('Menu is on the way'),
                      ),
                      const Spacer(),
                      _AvatarBadge(
                        size: context.rp(44),
                        onTap: () => _showSnack('Hi Alex, welcome back!'),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rp(18)),
                  Text(
                    'Hi, Alex 👋',
                    style: TextStyle(
                      fontSize: context.rp(12.5),
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: context.rp(4)),
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
                    style: TextStyle(
                      fontSize: context.rp(32),
                      height: 1.14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.rp(18)),
                  SearchField(
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _query = value),
                    onFilterTap: () => _showSnack('Filters coming soon'),
                  ),
                  SizedBox(height: context.rp(18)),
                  CategoryStrip(
                    selectedIndex: _selectedCategory,
                    onSelect: (int index) =>
                        setState(() => _selectedCategory = index),
                  ),
                  SizedBox(height: context.rp(18)),
                  PromoCard(
                    onOrder: () => _openDetail(MenuData.spicyChickenBurger),
                  ),
                  SizedBox(height: context.rp(20)),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'Popular Now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rp(17),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showSnack('More items coming soon'),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: context.rp(11.5),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rp(14)),
                  if (items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.rp(40)),
                      child: Center(
                        child: Text(
                          'No dish matches that search.',
                          style: TextStyle(
                            fontSize: context.rp(12),
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(width: context.rp(14)),
                        itemBuilder: (BuildContext context, int index) {
                          final FoodItem item = items[index];
                          return FoodCard(
                            item: item,
                            width: cardWidth,
                            height: cardHeight,
                            onTap: () => _openDetail(item),
                            onAdd: () =>
                                _showSnack('${item.name} added to cart'),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size + 4,
        height: size + 4,
        child: Stack(
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FFFFFF), width: 1.2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF4A3423), Color(0xFF22160E)],
                ),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: context.rp(16),
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
                width: context.rp(11),
                height: context.rp(11),
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
