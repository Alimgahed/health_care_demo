import 'package:flutter/material.dart';

import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _syncAppColors();
    // Listen to platform brightness changes if in system mode
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        _syncAppColors();
        notifyListeners();
      }
    };
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _syncAppColors() {
    AppColors.isDarkMode = isDarkMode;
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _syncAppColors();
    notifyListeners();
  }
}
