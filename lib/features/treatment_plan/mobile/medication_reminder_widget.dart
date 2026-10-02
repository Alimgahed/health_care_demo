import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import '../../journey/journey_provider.dart';

class MedicationReminderWidget extends StatelessWidget {
  final TreatmentPlan plan;

  const MedicationReminderWidget({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    bool isDue =
        DateTime.now().year > 2000; // Mock: assume it's due for demo purposes

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDue
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDue ? AppColors.error : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.pill,
                color: isDue ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('medication_reminder'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDue ? AppColors.error : AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('medication_schedule_line', {
              'dose': plan.medicationDose,
              'days': '${plan.medicationFrequencyDays}',
            }),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('next_injection_today', {
              'label': context.tr('next_injection_due'),
            }),
            style: TextStyle(
              color: isDue ? AppColors.error : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isDue)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _record(context, MedicationDoseStatus.taken),
                    icon: const Icon(LucideIcons.checkCircle),
                    label: Text(context.tr('i_took_my_medication')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<MedicationDoseStatus>(
                  tooltip: context.isArabic ? 'خيارات الجرعة' : 'Dose options',
                  onSelected: (status) => _record(context, status),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: MedicationDoseStatus.skipped,
                      child: Text(context.isArabic ? 'تخطي الجرعة' : 'Skipped'),
                    ),
                    PopupMenuItem(
                      value: MedicationDoseStatus.missed,
                      child: Text(context.isArabic ? 'جرعة فائتة' : 'Missed'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _record(BuildContext context, MedicationDoseStatus status) {
    final provider = context.read<DataProvider>();
    provider.logMedication(plan.id, DateTime.now(), status: status);
    final journey = context.read<JourneyProvider>();
    final patient = provider.getPatientById(plan.patientId);
    if (patient != null) journey.bindExistingPatient(patient);
    journey.recordMedicationAdherence(plan.patientId, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.isArabic
              ? 'تم تحديث حالة الجرعة والالتزام'
              : 'Dose status and adherence updated',
        ),
      ),
    );
  }
}
