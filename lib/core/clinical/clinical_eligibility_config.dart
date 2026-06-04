/// Ministry program thresholds — edit these values only; no AI required.
abstract final class ClinicalEligibilityConfig {
  /// BMI below this when the beneficiary has **no** chronic comorbidity → not eligible.
  static const double minBmiWithoutChronicDisease = 30.0;

  /// BMI below this when chronic comorbidity is documented → not eligible.
  static const double minBmiWithChronicDisease = 27.0;

  /// HbA1c above this (%) → dispensing blocked until glycemic control.
  static const double maxHbA1cPercent = 8.5;

  /// Fasting plasma glucose above this (mg/dL) → dispensing blocked.
  static const double maxFastingGlucoseMgDl = 180.0;

  /// If true, beneficiaries without lab values on file cannot be dispensed.
  static const bool requireLabValuesOnFile = false;

  /// English condition labels that **block** Mounjaro regardless of BMI (contraindications).
  static const List<String> absoluteBlockConditionsEn = [
    'Active pancreatitis',
    'Medullary thyroid carcinoma',
    'Pregnancy',
  ];
}
