import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
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
    final Size screen = MediaQuery.sizeOf(context);
    final double heroHeight = (screen.height * 0.38).clamp(170.0, 360.0);
    final double contentWidth = Responsive.contentWidth(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              SizedBox(
                width: contentWidth,
                child: Column(
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
                          padding: EdgeInsets.fromLTRB(
                            context.rp(22),
                            context.rp(18),
                            context.rp(22),
                            context.rp(26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  _TagPill(label: widget.item.tag ?? 'Popular'),
                                  const Spacer(),
                                  Container(
                                    width: context.rp(32),
                                    height: context.rp(32),
                                    decoration: BoxDecoration(
                                      color: const Color(0x14FFFFFF),
                                      borderRadius: BorderRadius.circular(
                                        context.rp(10),
                                      ),
                                      border: Border.all(
                                        color: AppColors.stroke,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      size: context.rp(15),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rp(14)),
                              Text(
                                widget.item.name,
                                style: TextStyle(
                                  fontSize: context.rp(22),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: context.rp(8)),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.star_rounded,
                                    size: context.rp(16),
                                    color: AppColors.amber,
                                  ),
                                  SizedBox(width: context.rp(4)),
                                  Text(
                                    widget.item.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: context.rp(12),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(width: context.rp(4)),
                                  Text(
                                    '(${widget.item.reviews})',
                                    style: TextStyle(
                                      fontSize: context.rp(11),
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const Spacer(),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '\$${widget.item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: context.rp(18),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rp(12)),
                              Text(
                                widget.item.description,
                                style: TextStyle(
                                  fontSize: context.rp(12),
                                  height: 1.6,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: context.rp(18)),
                              const Divider(color: AppColors.stroke, height: 1),
                              SizedBox(height: context.rp(16)),
                              Text(
                                'Customize',
                                style: TextStyle(
                                  fontSize: context.rp(13.5),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: context.rp(12)),
                              Row(
                                children: <Widget>[
                                  Text(
                                    'Size',
                                    style: TextStyle(
                                      fontSize: context.rp(12),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(width: context.rp(12)),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          for (int i = 0;
                                              i < _sizes.length;
                                              i++)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left:
                                                    i == 0 ? 0 : context.rp(8),
                                              ),
                                              child: SizeChip(
                                                label: _sizes[i],
                                                selected: _sizeIndex == i,
                                                onTap: () => setState(
                                                  () => _sizeIndex = i,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.rp(12)),
                              ToggleRow(
                                label: 'Add Cheese',
                                value: _addCheese,
                                onChanged: (bool v) =>
                                    setState(() => _addCheese = v),
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
                                onChanged: (bool v) =>
                                    setState(() => _addBacon = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.rp(18),
                      context.rp(10),
                      context.rp(18),
                      0,
                    ),
                    child: Row(
                      children: <Widget>[
                        CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          size: context.rp(44),
                          iconSize: context.rp(16),
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        CircleIconButton(
                          icon: _liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: context.rp(44),
                          iconSize: context.rp(18),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.sheet,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.rp(18),
                  context.rp(12),
                  context.rp(18),
                  context.rp(16),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: context.rp(54),
                      padding: EdgeInsets.symmetric(horizontal: context.rp(4)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.rp(16)),
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
                            width: context.rp(22),
                            child: Center(
                              child: Text(
                                '$_quantity',
                                style: TextStyle(
                                  fontSize: context.rp(14),
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
                    SizedBox(width: context.rp(12)),
                    Expanded(
                      child: GestureDetector(
                        onTap: _addToCart,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: context.rp(54),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.rp(16)),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                AppColors.orange,
                                AppColors.orangeLight,
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
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.rp(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      fontSize: context.rp(13.5),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: context.rp(18),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: context.rp(12),
                                    ),
                                    color: const Color(0x4DFFFFFF),
                                  ),
                                  Text(
                                    '\$${_total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: context.rp(13.5),
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
                    ),
                  ],
                ),
              ),
            ),
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
      padding: EdgeInsets.symmetric(
        horizontal: context.rp(12),
        vertical: context.rp(5),
      ),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(context.rp(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.rp(10),
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
        width: context.rp(40),
        height: context.rp(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(context.rp(12)),
        ),
        child: Icon(
          icon,
          size: context.rp(17),
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
