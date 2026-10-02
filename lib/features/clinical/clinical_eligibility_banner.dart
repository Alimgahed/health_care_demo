import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clinical/clinical_eligibility_rules.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

/// Displays the configured clinical rules and their recorded outcome.
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
    final color = result.eligible ? AppColors.successText : AppColors.errorText;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.eligible
                    ? LucideIcons.circleCheck
                    : LucideIcons.circleAlert,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.eligible
                      ? (context.isArabic
                            ? 'معايير البرنامج مستوفاة'
                            : 'Program criteria met')
                      : context.tr('program_ineligible_title'),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.eligible
                ? (context.isArabic
                      ? 'اجتازت البيانات المسجلة فحوصات الأهلية المحددة. يبقى القرار السريري للطبيب والمراجع.'
                      : 'Recorded information passes the configured eligibility checks. The clinician and reviewer make the clinical decision.')
                : context.tr('program_ineligible_sub'),
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          if (!result.eligible) ...[
            const SizedBox(height: 12),
            for (final violation in result.violations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        violationText(context, violation),
                        style: TextStyle(color: color, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
