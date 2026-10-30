import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../theme/app_theme.dart';

/// One card in the "Popular Now" row.
class FoodCard extends StatefulWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAdd,
  });

  final FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    widget.item.image,
                    width: 150,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                if (widget.item.tag != null)
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        widget.item.tag!,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: GestureDetector(
                    onTap: () => setState(() => _liked = !_liked),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _liked ? AppColors.red : const Color(0x99101012),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  '\$${widget.item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.orange,
                          AppColors.orangeLight
                        ],
                      ),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 17, color: Colors.white),
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
