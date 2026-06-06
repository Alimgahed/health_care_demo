import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/localization/l10n_extension.dart';

class AiDecisionSupportCard extends StatelessWidget {
  final Patient patient;

  const AiDecisionSupportCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: AppColors.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.sparkles, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('ai_clinical_insight') ?? 'AI Clinical Insight',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle, color: AppColors.success, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('confidence_high') ?? '98% Confidence',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendation(context),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricChip(
                context,
                LucideIcons.trendingDown,
                '${context.tr('bmi_trend') ?? 'BMI Trend'}: -1.2',
                AppColors.success,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                context,
                LucideIcons.activity,
                '${context.tr('adherence') ?? 'Adherence'}: ${(patient.complianceRate * 100).toInt()}%',
                patient.complianceRate > 0.8 ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context) {
    String message = '';
    IconData icon = LucideIcons.info;
    Color color = Colors.white;

    if (patient.bmi > 35 && patient.complianceRate > 0.8) {
      message = context.tr('ai_rec_increase_dose') ?? 'Patient is highly compliant but BMI remains above 35. Consider stepping up to next dose for optimal therapeutic effect.';
      icon = LucideIcons.arrowUpCircle;
      color = AppColors.warning;
    } else if (patient.complianceRate <= 0.6) {
      message = context.tr('ai_rec_adherence') ?? 'Low adherence detected. Recommend scheduling a telehealth consultation to discuss barriers to compliance before adjusting dose.';
      icon = LucideIcons.alertTriangle;
      color = AppColors.error;
    } else {
      message = context.tr('ai_rec_maintain') ?? 'Patient is responding well to current treatment plan. BMI is trending downwards and compliance is satisfactory. Maintain current dose.';
      icon = LucideIcons.checkCircle;
      color = AppColors.success;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}