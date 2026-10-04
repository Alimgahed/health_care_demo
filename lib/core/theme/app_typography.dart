import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static const List<String> _arabicFallbacks = [
    'Noto Sans Arabic',
    'Noto Naskh Arabic',
    'Arial',
  ];

  static TextStyle _manrope({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: _arabicFallbacks);

  static TextStyle _dmSans({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  ).copyWith(fontFamilyFallback: _arabicFallbacks);

  static TextTheme get lightTextTheme {
    return GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: _manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: _manrope(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: _manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: _manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: _manrope(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: _dmSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      ),
      bodyMedium: _dmSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),
      labelLarge: _dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  static TextTheme get darkTextTheme {
    return GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: _manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: _manrope(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: _manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: _manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: _manrope(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: _dmSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: _dmSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: _dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
    );
  }
}
