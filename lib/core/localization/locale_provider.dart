import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar'); // Default to Arabic as requested implicitly by the use case

  Locale get locale => _locale;

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      _locale = const Locale('ar');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }
}
