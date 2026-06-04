import 'clinical_eligibility_config.dart';

enum EligibilityBlockCode {
  bmiTooLow,
  hba1cTooHigh,
  glucoseTooHigh,
  labsMissing,
  contraindicatedCondition,
}

class EligibilityViolation {
  final EligibilityBlockCode code;
  final Map<String, String> params;

  const EligibilityViolation(this.code, [this.params = const {}]);
}

class ProgramEligibilityResult {
  final bool eligible;
  final List<EligibilityViolation> violations;

  const ProgramEligibilityResult({
    required this.eligible,
    this.violations = const [],
  });
}

/// Rule-based Mounjaro program eligibility (BMI, glycemia, contraindications).
abstract final class ClinicalEligibilityRules {
  static ProgramEligibilityResult evaluateFields({
    required double bmi,
    required bool hasChronicDisease,
    required List<String> medicalConditions,
    double? hba1cPercent,
    double? fastingGlucoseMgDl,
  }) {
    final violations = <EligibilityViolation>[];

    final minBmi = hasChronicDisease
        ? ClinicalEligibilityConfig.minBmiWithChronicDisease
        : ClinicalEligibilityConfig.minBmiWithoutChronicDisease;

    if (bmi < minBmi) {
      violations.add(
        EligibilityViolation(
          EligibilityBlockCode.bmiTooLow,
          {
            'bmi': bmi.toStringAsFixed(1),
            'min': minBmi.toStringAsFixed(1),
          },
        ),
      );
    }

    for (final blocked in ClinicalEligibilityConfig.absoluteBlockConditionsEn) {
      if (medicalConditions.any((c) => c.toLowerCase() == blocked.toLowerCase())) {
        violations.add(
          EligibilityViolation(
            EligibilityBlockCode.contraindicatedCondition,
            {'condition': blocked},
          ),
        );
      }
    }

    if (ClinicalEligibilityConfig.requireLabValuesOnFile &&
        (hba1cPercent == null || fastingGlucoseMgDl == null)) {
      violations.add(const EligibilityViolation(EligibilityBlockCode.labsMissing));
    } else {
      if (hba1cPercent != null && hba1cPercent > ClinicalEligibilityConfig.maxHbA1cPercent) {
        violations.add(
          EligibilityViolation(
            EligibilityBlockCode.hba1cTooHigh,
            {
              'value': hba1cPercent.toStringAsFixed(1),
              'max': ClinicalEligibilityConfig.maxHbA1cPercent.toStringAsFixed(1),
            },
          ),
        );
      }
      if (fastingGlucoseMgDl != null &&
          fastingGlucoseMgDl > ClinicalEligibilityConfig.maxFastingGlucoseMgDl) {
        violations.add(
          EligibilityViolation(
            EligibilityBlockCode.glucoseTooHigh,
            {
              'value': fastingGlucoseMgDl.toStringAsFixed(0),
              'max': ClinicalEligibilityConfig.maxFastingGlucoseMgDl.toStringAsFixed(0),
            },
          ),
        );
      }
    }

    return ProgramEligibilityResult(
      eligible: violations.isEmpty,
      violations: violations,
    );
  }
}
