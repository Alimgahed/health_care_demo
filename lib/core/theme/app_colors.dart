import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = false;

  // Primary - Deep Forest Green from Logo
  static Color get primary => isDarkMode ? primaryLight : const Color(0xFF16533A);
  static const Color primaryLight = Color(0xFF227554);
  static const Color primaryDark = Color(0xFF0C3322);

  // Secondary - Gold/Star Accent from Logo
  static const Color accent = Color(0xFFC7A252);
  static const Color accentLight = Color(0xFFE2C482);

  // Navy/Dark Blue from Logo's Falcon Outline
  static Color get navy => isDarkMode ? darkSurface : const Color(0xFF0A2B3E);

  // Neutrals (Light Mode)
  static Color get background => isDarkMode ? darkBackground : const Color(0xFFF8F9FA);
  static Color get surface => isDarkMode ? darkSurface : Colors.white;
  static Color get surface12 => surface.withOpacity(0.12);
  static Color get surface24 => surface.withOpacity(0.24);
  static Color get surface54 => surface.withOpacity(0.54);
  static Color get surface60 => surface.withOpacity(0.60);
  static Color get surface70 => surface.withOpacity(0.70);
  static Color get textPrimary => isDarkMode ? darkTextPrimary : const Color(0xFF1A1F24);
  static Color get textSecondary => isDarkMode ? darkTextSecondary : const Color(0xFF6B7280);
  static Color get border => isDarkMode ? darkBorder : const Color(0xFFE5E7EB);

  // Neutrals (Dark Mode)
  static const Color darkBackground = Color(0xFF0F172A); // Deep slate
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
