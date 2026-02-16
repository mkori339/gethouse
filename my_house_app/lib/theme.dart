import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY BLUE THEME
  static const Color primary = Color(0xFF1565C0);      // Deep Blue
  static const Color secondary = Color(0xFF42A5F5);    // Light Blue
  static const Color scaffoldBg = Color(0xFFF5F8FF);   // Soft Blue-White
  static const Color accentOrange = Color(0xFFF97316); // Keep for alerts
}

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
  ),
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.scaffoldBg,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.accentOrange,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
