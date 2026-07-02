import 'package:flutter/material.dart';

/// App color palette. Dark Material 3, mirroring the web cabinet's tokens
/// (`--bg`, `--card`, `--accent`, `--ok`, `--err`) so the two shells read alike.
class AppColors {
  AppColors._();

  static const Color backgroundPrimary = Color(0xFF0F1220);
  static const Color backgroundCard = Color(0xFF181C2E);
  static const Color backgroundElevated = Color(0xFF10142A);
  static const Color separator = Color(0xFF2A3050);

  static const Color textPrimary = Color(0xFFE7E9F3);
  static const Color textSecondary = Color(0xFF9AA0BD);

  static const Color accentBlue = Color(0xFF5B8CFF);
  static const Color accentGreen = Color(0xFF37C98B);
  static const Color accentRed = Color(0xFFFF6B6B);
}

/// Centralized dark theme. There is no light theme (the cabinet is dark-only).
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      surface: AppColors.backgroundPrimary,
      primary: AppColors.accentBlue,
      secondary: AppColors.accentBlue,
      error: AppColors.accentRed,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: scheme,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.separator),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.separator),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentBlue),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.backgroundCard,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.separator, thickness: 1),
    );
  }
}
