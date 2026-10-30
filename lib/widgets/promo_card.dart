import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../theme/app_theme.dart';

/// "Limited Time Offer" banner with the burger combo artwork.
class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x26FF7A18)),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFF3B2413), Color(0xFF22140A)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -18,
              top: -6,
              bottom: -6,
              width: 190,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[Colors.transparent, Colors.white],
                    stops: <double>[0.0, 0.45],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  MenuData.comboImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: AppColors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Limited Time Offer',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.orangeLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Spicy Burger\nCombo',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: onOrder,
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                AppColors.orange,
                                AppColors.orangeLight
                              ],
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x66FF7A18),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Order Now',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xCC1A1210),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Center(
                          child: Text(
                            '20%\nOFF',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 8.5,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
