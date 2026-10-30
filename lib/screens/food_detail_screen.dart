import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/size_chip.dart';
import '../widgets/toggle_row.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, required this.item});

  final FoodItem item;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  static const List<String> _sizes = <String>['Regular', 'Large', 'X Large'];
  static const List<double> _sizePrices = <double>[0.0, 1.00, 1.80];

  int _sizeIndex = 0;
  int _quantity = 1;
  bool _liked = false;
  bool _addCheese = true;
  bool _extraPatty = false;
  bool _addBacon = true;

  double get _unitPrice {
    double price = widget.item.price + _sizePrices[_sizeIndex];
    if (_addCheese) {
      price += 0.99;
    }
    if (_extraPatty) {
      price += 1.60;
    }
    if (_addBacon) {
      price += 1.40;
    }
    return price;
  }

  double get _total => _unitPrice * _quantity;

  void _addToCart() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$_quantity x ${widget.item.name} added to cart',
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
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final double heroHeight = MediaQuery.of(context).size.height * 0.38;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.asset(
                      MenuData.heroImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x66000000),
                            Color(0x00000000),
                            Color(0xCC0B0B0D),
                            AppColors.sheet,
                          ],
                          stops: <double>[0.0, 0.35, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.sheet,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _TagPill(label: widget.item.tag ?? 'Popular'),
                            const Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.stroke),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${widget.item.reviews})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${widget.item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: AppColors.stroke, height: 1),
                        const SizedBox(height: 16),
                        const Text(
                          'Customize',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Text(
                              'Size',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    for (int i = 0; i < _sizes.length; i++)
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: i == 0 ? 0 : 8),
                                        child: SizeChip(
                                          label: _sizes[i],
                                          selected: _sizeIndex == i,
                                          onTap: () =>
                                              setState(() => _sizeIndex = i),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ToggleRow(
                          label: 'Add Cheese',
                          value: _addCheese,
                          onChanged: (bool v) => setState(() => _addCheese = v),
                        ),
                        ToggleRow(
                          label: 'Extra Patty',
                          value: _extraPatty,
                          onChanged: (bool v) =>
                              setState(() => _extraPatty = v),
                        ),
                        ToggleRow(
                          label: 'Add Bacon',
                          value: _addBacon,
                          onChanged: (bool v) => setState(() => _addBacon = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Row(
                  children: <Widget>[
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 16,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    CircleIconButton(
                      icon: _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconSize: 18,
                      background:
                          _liked ? AppColors.red : const Color(0xCC101012),
                      borderColor:
                          _liked ? AppColors.red : const Color(0x33FFFFFF),
                      onTap: () => setState(() => _liked = !_liked),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: const BoxDecoration(
          color: AppColors.sheet,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: <Widget>[
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _StepButton(
                      icon: Icons.remove_rounded,
                      enabled: _quantity > 1,
                      onTap: () => setState(() => _quantity -= 1),
                    ),
                    SizedBox(
                      width: 22,
                      child: Center(
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add_rounded,
                      enabled: true,
                      onTap: () => setState(() => _quantity += 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _addToCart,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.orange,
                          AppColors.orangeLight
                        ],
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66FF7A18),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 18,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: const Color(0x4DFFFFFF),
                          ),
                          Text(
                            '\$${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
