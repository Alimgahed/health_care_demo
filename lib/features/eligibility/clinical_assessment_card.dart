import 'package:flutter/material.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClinicalAssessmentCard extends StatelessWidget {
  final Patient patient;

  const ClinicalAssessmentCard({
    super.key,
    required this.patient,
  });

  String _obesityClassification(BuildContext context) {
    final bmi = patient.bmi;
    if (bmi < 18.5) return context.tr('underweight');
    if (bmi < 25) return context.tr('normal_weight');
    if (bmi < 30) return context.tr('overweight');
    if (bmi < 35) return context.tr('obesity_class_1');
    if (bmi < 40) return context.tr('obesity_class_2');
    return context.tr('obesity_class_3');
  }

  BadgeStatus get _recommendationStatus {
    final bmi = patient.bmi;
    if (bmi >= 30) return BadgeStatus.success;
    if (bmi >= 27 && patient.medicalConditions.isNotEmpty) return BadgeStatus.success;
    if (bmi >= 27) return BadgeStatus.warning;
    return BadgeStatus.error;
  }

  String _recommendationText(BuildContext context) {
    final status = _recommendationStatus;
    if (status == BadgeStatus.success) return context.tr('eligible_mounjaro');
    if (status == BadgeStatus.warning) return context.tr('requires_review');
    return context.tr('not_eligible');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('clinical_assessment'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StatusBadge(
                  label: _recommendationText(context),
                  status: _recommendationStatus,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    context,
                    context.tr('weight'),
                    '${patient.weight.toStringAsFixed(1)} kg',
                    LucideIcons.scale,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    context,
                    context.tr('col_bmi'),
                    patient.bmi.toStringAsFixed(1),
                    LucideIcons.activity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.stethoscope,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('classification'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _obesityClassification(context),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ],
    );
  }
}
