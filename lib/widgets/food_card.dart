import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// One card in the "Popular Now" row.
class FoodCard extends StatefulWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAdd,
    required this.width,
    required this.height,
  });

  final FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final double width;
  final double height;

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final double imageHeight = widget.height * 0.58;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.rp(22)),
                  child: Image.asset(
                    widget.item.image,
                    width: widget.width,
                    height: imageHeight,
                    fit: BoxFit.cover,
                  ),
                ),
                if (widget.item.tag != null)
                  Positioned(
                    top: context.rp(9),
                    left: context.rp(9),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rp(8),
                        vertical: context.rp(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(context.rp(9)),
                      ),
                      child: Text(
                        widget.item.tag!,
                        style: TextStyle(
                          fontSize: context.rp(8.5),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: context.rp(9),
                  right: context.rp(9),
                  child: GestureDetector(
                    onTap: () => setState(() => _liked = !_liked),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: context.rp(28),
                      height: context.rp(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _liked ? AppColors.red : const Color(0x99101012),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: context.rp(14),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rp(10)),
            // Expanded keeps the card free of overflow on any font size.
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  widget.item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rp(12.5),
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: context.rp(6)),
            Row(
              children: <Widget>[
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\$${widget.item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.rp(12.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.rp(6)),
                GestureDetector(
                  onTap: widget.onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: context.rp(26),
                    height: context.rp(26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.rp(9)),
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.orange,
                          AppColors.orangeLight,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: context.rp(17),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
