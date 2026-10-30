import 'package:flutter/material.dart';

/// Every colour used in CraveCart lives here.
class AppColors {
  static const Color bg = Color(0xFF0B0B0D);
  static const Color sheet = Color(0xFF121216);
  static const Color surface = Color(0xFF1B1B21);
  static const Color surfaceSoft = Color(0xFF232329);
  static const Color stroke = Color(0x1AFFFFFF);

  static const Color orange = Color(0xFFFF7A18);
  static const Color orangeLight = Color(0xFFFFA24A);
  static const Color amber = Color(0xFFFFC107);
  static const Color red = Color(0xFFFF3B30);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA4);
  static const Color textTertiary = Color(0xFF6E6E78);
}

class AppTheme {
  static const String fontFamily = 'Poppins';

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        secondary: AppColors.orangeLight,
        surface: AppColors.surface,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.orange,
        selectionColor: Color(0x55FF7A18),
        selectionHandleColor: AppColors.orange,
      ),
    );
  }
}
