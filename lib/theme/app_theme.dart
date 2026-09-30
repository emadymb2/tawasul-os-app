import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFF4F0E8);
  static const ink = Color(0xFF123C28);
  static const pine = Color(0xFF0D3A24);
  static const pineSoft = Color(0xFF1C4D32);
  static const gold = Color(0xFFE1B652);
  static const red = Color(0xFFE7514C);
  static const mint = Color(0xFFDDEDE5);
  static const sage = Color(0xFFD7E3C5);
  static const green = Color(0xFF5A9B73);
  static const panel = Color(0xFFFEFDF9);
  static const line = Color(0xFFE0DED8);
  static const muted = Color(0xFF718177);
  static const mintText = Color(0xCCDDEDE5);
}

class AppRadii {
  // Numeric radii for BorderRadius.circular(...)
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;

  static const small = Radius.circular(14);
  static const medium = Radius.circular(24);
  static const large = Radius.circular(34);
  static const huge = Radius.circular(52);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, fontFamily: 'Roboto');
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pine,
        brightness: Brightness.light,
        primary: AppColors.pine,
        secondary: AppColors.gold,
        surface: AppColors.panel,
        error: AppColors.red,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
