import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = false;

  // Shared healthcare portal palette. The action shade is kept dark enough
  // for readable white button labels; the brighter portal green is an accent.
  static Color get primary =>
      isDarkMode ? primaryLight : const Color(0xFF087F73);
  static const Color primaryLight = Color(0xFF55C6A5);
  static const Color primaryDark = Color(0xFF075B53);
  static const Color primaryAccent = Color(0xFF087F73);

  // Restrained gold accent from the shared portal identity.
  static const Color accent = Color(0xFFC7A252);
  static const Color accentLight = Color(0xFFE2C482);

  // Petrol navy for mobile navigation and operational headers.
  static Color get navy => isDarkMode ? darkSurface : const Color(0xFF102B46);

  // Neutrals (Light Mode)
  static Color get background =>
      isDarkMode ? darkBackground : const Color(0xFFF3F6F9);
  static Color get surface => isDarkMode ? darkSurface : Colors.white;
  static const Color paleSurface = Color(0xFFE5F3ED);
  static Color get surface12 => surface.withValues(alpha: 0.12);
  static Color get surface24 => surface.withValues(alpha: 0.24);
  static Color get surface54 => surface.withValues(alpha: 0.54);
  static Color get surface60 => surface.withValues(alpha: 0.60);
  static Color get surface70 => surface.withValues(alpha: 0.70);
  static Color get textPrimary =>
      isDarkMode ? darkTextPrimary : const Color(0xFF243D54);
  static Color get textSecondary =>
      isDarkMode ? darkTextSecondary : const Color(0xFF5E7286);
  static Color get border => isDarkMode ? darkBorder : const Color(0xFFDCE5ED);
  static Color get surfaceMuted =>
      isDarkMode ? const Color(0xFF243549) : const Color(0xFFF3F6F9);
  static Color get disabled =>
      isDarkMode ? const Color(0xFF6B7787) : const Color(0xFF6D807C);

  // Neutrals (Dark Mode)
  static const Color darkBackground = Color(0xFF0F172A); // Deep slate
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Status Colors
  static const Color success = Color(0xFF126B50);
  static const Color warning = Color(0xFF8B5A00);
  static const Color error = Color(0xFFB3333A);
  static const Color info = Color(0xFF246A8A);
  static Color get successText =>
      isDarkMode ? const Color(0xFF76D9AD) : success;
  static Color get warningText =>
      isDarkMode ? const Color(0xFFFFD584) : warning;
  static Color get errorText => isDarkMode ? const Color(0xFFFF9EA4) : error;
  static Color get infoText => isDarkMode ? const Color(0xFF91CBE7) : info;
}
