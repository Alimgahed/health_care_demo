import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import 'clinical_eligibility_banner.dart';

/// Full beneficiary profile for clinical review / approval workflow.
class ClinicalReviewDetailPanel extends StatelessWidget {
  final Patient patient;
  final String reviewType;
  final VoidCallback onApprove;

  const ClinicalReviewDetailPanel({
    super.key,
    required this.patient,
    required this.reviewType,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        final p = dp.getPatientById(patient.id) ?? patient;
        final plan = dp.getPlanForPatient(p.id);
        final reason = reviewType == 'care_plan'
            ? context.tr('review_type_care_plan')
            : context.tr('review_type_early_dispense');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      p.getLocalizedFullName(context).substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.getLocalizedFullName(context),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          '${p.id} · ${p.emiratesId}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      context.tr('status_pending_clinical_review'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              ClinicalEligibilityBanner(patient: p),
              const SizedBox(height: 16),
              _section(
                context,
                context.tr('demographics_section'),
                LucideIcons.user,
                [
                  _row(context, context.tr('full_name'), p.getLocalizedFullName(context)),
                  _row(context, context.tr('emirates_id'), p.emiratesId),
                  _row(context, context.tr('age'), '${p.age}'),
                  _row(context, context.tr('gender'), p.getLocalizedGender(context)),
                  _row(context, context.tr('nationality'), p.getLocalizedNationality(context)),
                  _row(context, context.tr('residency_status'), p.getLocalizedResidency(context)),
                  _row(context, context.tr('region'), p.getLocalizedEmirate(context)),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                context,
                context.tr('clinical_assessment'),
                LucideIcons.stethoscope,
                [
                  _row(context, context.tr('weight'), '${p.weight.toStringAsFixed(1)} kg'),
                  _row(context, context.tr('height_cm'), '${p.height.toStringAsFixed(0)} cm'),
                  _row(context, context.tr('col_bmi'), p.bmi.toStringAsFixed(1)),
                  _row(
                    context,
                    context.tr('hba1c_label'),
                    p.hba1cPercent != null ? '${p.hba1cPercent!.toStringAsFixed(1)}%' : context.tr('not_recorded'),
                  ),
                  _row(
                    context,
                    context.tr('fasting_glucose_label'),
                    p.fastingGlucoseMgDl != null
                        ? '${p.fastingGlucoseMgDl!.toStringAsFixed(0)} mg/dL'
                        : context.tr('not_recorded'),
                  ),
                  _row(
                    context,
                    context.tr('has_chronic_disease'),
                    p.hasChronicDisease ? context.tr('yes') : context.tr('no'),
                  ),
                  _row(
                    context,
                    context.tr('chronic_conditions_section'),
                    p.getLocalizedMedicalConditions(context).isEmpty
                        ? context.tr('none_reported')
                        : p.getLocalizedMedicalConditions(context).join(' · '),
                  ),
                  _row(
                    context,
                    context.tr('last_dispense_date'),
                    p.lastDispensingDate ?? context.tr('never_dispensed'),
                  ),
                  if (p.lastDispensingCenterId != null)
                    _row(
                      context,
                      context.tr('last_dispensing_facility'),
                      dp.dispensingFacilityLabel(context, p.lastDispensingCenterId),
                    ),
                  _row(
                    context,
                    context.tr('next_dispense_eligible'),
                    p.nextEligibleDate ?? context.tr('now'),
                  ),
                  _row(context, context.tr('active_prescription'), context.mounjaroDoseLabel(p.currentDose)),
                ],
              ),
              if (plan != null) ...[
                const SizedBox(height: 20),
                _section(
                  context,
                  context.tr('active_care_plan'),
                  LucideIcons.clipboardList,
                  [
                    _row(
                      context,
                      context.tr('select_dose'),
                      context.mounjaroDoseLabel(plan.medicationDose),
                    ),
                    _row(
                      context,
                      context.tr('injection_interval'),
                      context.tr('every_n_days', {'n': '${plan.medicationFrequencyDays}'}),
                    ),
                    _row(
                      context,
                      context.tr('care_plan_status_pending'),
                      plan.clinicalApprovalStatus == 'pending_review'
                          ? context.tr('status_pending_clinical_review')
                          : context.tr('eligible_dispensation'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _section(
                context,
                context.tr('lab_documents_section'),
                LucideIcons.fileText,
                p.clinicalAttachments.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            context.tr('no_lab_documents'),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ]
                    : p.clinicalAttachments
                        .map(
                          (doc) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              doc.isPdf ? LucideIcons.fileText : LucideIcons.image,
                              color: AppColors.primary,
                            ),
                            title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              context.tr('document_uploaded_at', {
                                'date': doc.uploadedAt.toString().split('.').first,
                              }),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: p.programEligibility.eligible ? onApprove : null,
                  icon: const Icon(LucideIcons.checkCircle),
                  label: Text(context.tr('approve_clinical_review')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}
