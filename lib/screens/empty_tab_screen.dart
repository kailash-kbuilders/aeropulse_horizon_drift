import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1AFF7A18),
                  border: Border.all(color: const Color(0x33FF7A18)),
                ),
                child: Icon(icon, size: 30, color: AppColors.orange),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
