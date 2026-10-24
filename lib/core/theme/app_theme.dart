import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      onPrimary: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      error: AppColors.wine,
      surface: AppColors.white,
      onSurface: AppColors.navy,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.navy,
        selectionHandleColor: AppColors.navy,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.navy
              : AppColors.white,
        ),
        side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        titleMedium: AppTextStyles.cardTitle,
      ),
    );
  }
}
