import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, [Map<String, String>? params]) =>
      l10n.translate(key, params);

  bool get isArabic =>
      Localizations.localeOf(this).languageCode == 'ar';

  String emirateLabel(String emirate) {
    switch (emirate) {
      case 'Abu Dhabi':
        return tr('emirate_abu_dhabi');
      case 'Dubai':
        return tr('emirate_dubai');
      case 'Sharjah':
        return tr('emirate_sharjah');
      case 'Ajman':
        return tr('emirate_ajman');
      case 'Umm Al Quwain':
        return tr('emirate_umm_al_quwain');
      case 'Ras Al Khaimah':
        return tr('emirate_ras_al_khaimah');
      case 'Fujairah':
        return tr('emirate_fujairah');
      default:
        return emirate;
    }
  }

  String nationalityLabel(String nationality) {
    switch (nationality) {
      case 'United Arab Emirates':
        return tr('nationality_uae');
      case 'United Kingdom':
        return tr('nationality_uk');
      case 'United States':
        return tr('nationality_us');
      case 'India':
        return tr('nationality_india');
      case 'Pakistan':
        return tr('nationality_pakistan');
      case 'Egypt':
        return tr('nationality_egypt');
      default:
        return nationality;
    }
  }

  String mounjaroDoseLabel(String doseMg) {
    final normalized = doseMg.replaceAll(' ', '').toLowerCase();
    if (normalized.contains('2.5')) return tr('mounjaro_dose_2_5');
    if (normalized.contains('7.5')) return tr('mounjaro_dose_7_5');
    if (normalized.contains('10')) return tr('mounjaro_dose_10_0');
    if (normalized.contains('5')) return tr('mounjaro_dose_5_0');
    return doseMg;
  }
}
