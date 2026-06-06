import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/clinical/clinical_eligibility_rules.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

/// Shows rule-based block reasons (BMI, HbA1c, glucose, contraindications).
class ClinicalEligibilityBanner extends StatelessWidget {
  final Patient patient;

  const ClinicalEligibilityBanner({super.key, required this.patient});

  static String violationText(BuildContext context, EligibilityViolation v) {
    switch (v.code) {
      case EligibilityBlockCode.bmiTooLow:
        return context.tr('rule_bmi_too_low', v.params);
      case EligibilityBlockCode.hba1cTooHigh:
        return context.tr('rule_hba1c_too_high', v.params);
      case EligibilityBlockCode.glucoseTooHigh:
        return context.tr('rule_glucose_too_high', v.params);
      case EligibilityBlockCode.labsMissing:
        return context.tr('rule_labs_missing');
      case EligibilityBlockCode.contraindicatedCondition:
        return context.tr('rule_contraindication', v.params);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = patient.programEligibility;
    if (result.eligible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.accessibility, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('program_ineligible_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('program_ineligible_sub'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          ...result.violations.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      violationText(context, v),
                      style: TextStyle(color: AppColors.error, fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}