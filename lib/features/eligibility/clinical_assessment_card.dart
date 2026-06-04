import 'package:flutter/material.dart';
import '../../core/constants/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClinicalAssessmentCard extends StatelessWidget {
  final Patient patient;

  const ClinicalAssessmentCard({
    super.key,
    required this.patient,
  });

  String get _obesityClassification {
    final bmi = patient.bmi;
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    if (bmi < 35) return 'Class I Obesity';
    if (bmi < 40) return 'Class II Obesity';
    return 'Class III Obesity';
  }

  BadgeStatus get _recommendationStatus {
    final bmi = patient.bmi;
    if (bmi >= 30) return BadgeStatus.success;
    if (bmi >= 27 && patient.medicalConditions.isNotEmpty) return BadgeStatus.success;
    if (bmi >= 27) return BadgeStatus.warning;
    return BadgeStatus.error;
  }

  String get _recommendationText {
    final status = _recommendationStatus;
    if (status == BadgeStatus.success) return 'Eligible for Mounjaro';
    if (status == BadgeStatus.warning) return 'Requires Medical Review';
    return 'Not Eligible';
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
                  'Clinical Assessment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StatusBadge(
                  label: _recommendationText,
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
                    'Weight',
                    '${patient.weight.toStringAsFixed(1)} kg',
                    LucideIcons.scale,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    context,
                    'BMI',
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
                          'Classification',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _obesityClassification,
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
