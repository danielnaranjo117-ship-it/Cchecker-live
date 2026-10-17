import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0B0F);
  static const panel = Color(0xFF12141C);
  static const stroke = Color(0xFF1E2230);
  static const lime = Color(0xFFBAFF54);
  static const cyan = Color(0xFF54E0FF);
  static const violet = Color(0xFF9B7BFF);
  static const amber = Color(0xFFFFC65C);
  static const red = Color(0xFFFF6B6B);
  static const textHi = Color(0xFFEDF0F7);
  static const textMid = Color(0xFF9AA3B5);
}

class AppTextStyles {
  static const title = TextStyle(
    color: AppColors.textHi,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  static const body = TextStyle(color: AppColors.textHi, fontSize: 14);
  static const caption = TextStyle(color: AppColors.textMid, fontSize: 12);
  static const tiny = TextStyle(color: AppColors.textMid, fontSize: 10, letterSpacing: 0.6);
  static const mono = TextStyle(
    color: AppColors.textHi,
    fontSize: 13,
    fontFamily: 'monospace',
    letterSpacing: 0.4,
  );
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.lime,
      secondary: AppColors.cyan,
      surface: AppColors.panel,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.stroke),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.stroke),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lime),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      labelStyle: AppTextStyles.caption,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.lime),
  );
}
