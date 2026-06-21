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

    final predictionBanner = _AIEligibilityPredictionBanner(patient: patient);

    if (result.eligible) {
      return predictionBanner;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        predictionBanner,
        Container(
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
                  Icon(
                    LucideIcons.accessibility,
                    color: AppColors.error,
                    size: 24,
                  ),
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
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              ...result.violations.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          violationText(context, v),
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AIEligibilityPredictionBanner extends StatelessWidget {
  final Patient patient;

  const _AIEligibilityPredictionBanner({required this.patient});

  @override
  Widget build(BuildContext context) {
    final bool isEligible = patient.programEligibility.eligible;
    int score = 0;

    if (!isEligible) {
      score = 34;
    } else if (patient.bmi > 40) {
      score = 78;
    } else if (patient.bmi > 35) {
      score = 85;
    } else {
      score = 92;
    }

    final Color color = score >= 80
        ? AppColors.success
        : (score >= 60 ? AppColors.warning : AppColors.error);
    final String statusLabel = score >= 80
        ? context.tr('ai_eligibility_high')
        : (score >= 60
              ? context.tr('ai_eligibility_medium')
              : context.tr('ai_eligibility_low'));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('ai_eligibility_prediction'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '$score% - $statusLabel',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('ai_eligibility_detail', {
              'bmi': patient.bmi.toStringAsFixed(1),
              'score': score.toString(),
            }),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
