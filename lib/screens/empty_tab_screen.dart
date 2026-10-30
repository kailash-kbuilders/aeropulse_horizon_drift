import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Shown for the tabs that have no content in this build.
class EmptyTabScreen extends StatelessWidget {
  const EmptyTabScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.85, -1.05),
          radius: 1.35,
          colors: <Color>[Color(0xFF2A1A0E), AppColors.bg],
          stops: <double>[0.0, 0.62],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.rp(40),
              vertical: context.rp(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Responsive.maxContentWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: context.rp(76),
                    height: context.rp(76),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x1AFF7A18),
                      border: Border.all(color: const Color(0x33FF7A18)),
                    ),
                    child: Icon(
                      icon,
                      size: context.rp(30),
                      color: AppColors.orange,
                    ),
                  ),
                  SizedBox(height: context.rp(18)),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.rp(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.rp(6)),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.rp(12),
                      height: 1.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
