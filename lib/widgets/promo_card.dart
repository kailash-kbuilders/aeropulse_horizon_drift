import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// "Limited Time Offer" banner with the burger combo artwork.
class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final double height = context.rp(162);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.rp(24)),
        border: Border.all(color: const Color(0x26FF7A18)),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFF3B2413), Color(0xFF22140A)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.rp(24)),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            return Stack(
              children: <Widget>[
                Positioned(
                  right: -context.rp(18),
                  top: -context.rp(6),
                  bottom: -context.rp(6),
                  width: width * 0.46,
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
                  padding: EdgeInsets.fromLTRB(
                    context.rp(18),
                    context.rp(14),
                    context.rp(18),
                    context.rp(14),
                  ),
                  // Every row below is either flexible or wrapped in a
                  // FittedBox, so the banner cannot overflow at any font size.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: width * 0.60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: context.rp(13),
                                color: AppColors.orange,
                              ),
                              SizedBox(width: context.rp(4)),
                              Expanded(
                                child: Text(
                                  'Limited Time Offer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.rp(9.5),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: AppColors.orangeLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rp(8)),
                          Text(
                            'Spicy Burger\nCombo',
                            style: TextStyle(
                              fontSize: context.rp(19),
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: context.rp(10)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: onOrder,
                                  child: Container(
                                    height: context.rp(36),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.rp(18),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        context.rp(11),
                                      ),
                                      gradient: const LinearGradient(
                                        colors: <Color>[
                                          AppColors.orange,
                                          AppColors.orangeLight,
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
                                    child: Center(
                                      child: Text(
                                        'Order Now',
                                        style: TextStyle(
                                          fontSize: context.rp(11.5),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.rp(12)),
                                Container(
                                  width: context.rp(42),
                                  height: context.rp(42),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xCC1A1210),
                                    border: Border.all(
                                      color: const Color(0x33FFFFFF),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '20%\nOFF',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: context.rp(8.5),
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
