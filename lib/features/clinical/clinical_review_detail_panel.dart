import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import 'clinical_eligibility_banner.dart';

/// Full beneficiary profile for clinical review / approval workflow.
class ClinicalReviewDetailPanel extends StatelessWidget {
  final Patient patient;
  final String reviewType;
  final VoidCallback? onApprove;
  final ValueChanged<String>? onReject;
  final ValueChanged<String>? onRequestInformation;

  const ClinicalReviewDetailPanel({
    super.key,
    required this.patient,
    required this.reviewType,
    required this.onApprove,
    this.onReject,
    this.onRequestInformation,
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
                      p
                          .getLocalizedFullName(context)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${p.id} · ${p.emiratesId}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      context.tr('status_pending_clinical_review'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reason,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ClinicalEligibilityBanner(patient: p),
              const SizedBox(height: 16),
              _section(
                context,
                context.tr('demographics_section'),
                LucideIcons.user,
                [
                  _row(
                    context,
                    context.tr('full_name'),
                    p.getLocalizedFullName(context),
                  ),
                  _row(context, context.tr('emirates_id'), p.emiratesId),
                  _row(context, context.tr('age'), '${p.age}'),
                  _row(
                    context,
                    context.tr('gender'),
                    p.getLocalizedGender(context),
                  ),
                  _row(
                    context,
                    context.tr('nationality'),
                    p.getLocalizedNationality(context),
                  ),
                  _row(
                    context,
                    context.tr('residency_status'),
                    p.getLocalizedResidency(context),
                  ),
                  _row(
                    context,
                    context.tr('region'),
                    p.getLocalizedEmirate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                context,
                context.tr('clinical_assessment'),
                LucideIcons.stethoscope,
                [
                  _row(
                    context,
                    context.tr('weight'),
                    '${p.weight.toStringAsFixed(1)} kg',
                  ),
                  _row(
                    context,
                    context.tr('height_cm'),
                    '${p.height.toStringAsFixed(0)} cm',
                  ),
                  _row(
                    context,
                    context.tr('col_bmi'),
                    p.bmi.toStringAsFixed(1),
                  ),
                  _row(
                    context,
                    context.tr('hba1c_label'),
                    p.hba1cPercent != null
                        ? '${p.hba1cPercent!.toStringAsFixed(1)}%'
                        : context.tr('not_recorded'),
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
                      dp.dispensingFacilityLabel(
                        context,
                        p.lastDispensingCenterId,
                      ),
                    ),
                  _row(
                    context,
                    context.tr('next_dispense_eligible'),
                    p.nextEligibleDate ?? context.tr('now'),
                  ),
                  _row(
                    context,
                    context.tr('active_prescription'),
                    context.mounjaroDoseLabel(p.currentDose),
                  ),
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
                      context.tr('every_n_days', {
                        'n': '${plan.medicationFrequencyDays}',
                      }),
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
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ]
                    : p.clinicalAttachments
                          .map(
                            (doc) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                doc.isPdf
                                    ? LucideIcons.fileText
                                    : LucideIcons.image,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                doc.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                context.tr('document_uploaded_at', {
                                  'date': doc.uploadedAt
                                      .toString()
                                      .split('.')
                                      .first,
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
                  onPressed: p.programEligibility.eligible && onApprove != null
                      ? () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(
                                context.isArabic
                                    ? 'تأكيد اعتماد المراجعة'
                                    : 'Confirm clinical approval',
                              ),
                              content: Text(
                                context.isArabic
                                    ? 'سيُعتمد طلب ${p.getLocalizedFullName(context)} وتُحدّث حالة العلاج. راجع الأدلة السريرية قبل المتابعة.'
                                    : 'This will approve ${p.getLocalizedFullName(context)}’s review and update treatment status. Check the clinical evidence before continuing.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text(
                                    context.isArabic ? 'إلغاء' : 'Cancel',
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: Text(
                                    context.tr('approve_clinical_review'),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            onApprove?.call();
                          }
                        }
                      : null,
                  icon: const Icon(LucideIcons.checkCircle),
                  label: Text(context.tr('approve_clinical_review')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              if (reviewType == 'care_plan' &&
                  (onReject != null || onRequestInformation != null)) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (onRequestInformation != null)
                      OutlinedButton.icon(
                        onPressed: () => _reasonDialog(
                          context,
                          context.isArabic
                              ? 'طلب معلومات إضافية'
                              : 'Request more information',
                          context.isArabic
                              ? 'اشرح المعلومات أو الأدلة المطلوبة قبل إعادة تقديم الطلب.'
                              : 'Explain what information or evidence is needed before resubmission.',
                          onRequestInformation!,
                        ),
                        icon: const Icon(LucideIcons.circleHelp),
                        label: Text(
                          context.isArabic
                              ? 'طلب معلومات'
                              : 'Request information',
                        ),
                      ),
                    if (onReject != null)
                      OutlinedButton.icon(
                        onPressed: () => _reasonDialog(
                          context,
                          context.isArabic
                              ? 'تأكيد رفض الطلب'
                              : 'Confirm rejection',
                          context.isArabic
                              ? 'سيُرفض طلب العلاج ويُسجّل السبب في سجل المراجعة.'
                              : 'The treatment request will be rejected and the reason recorded in the review history.',
                          onReject!,
                        ),
                        icon: const Icon(LucideIcons.x),
                        label: Text(context.isArabic ? 'رفض الطلب' : 'Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorText,
                        ),
                      ),
                  ],
                ),
              ],
              if (!p.programEligibility.eligible) ...[
                const SizedBox(height: 8),
                Text(
                  context.isArabic
                      ? 'لا يمكن الاعتماد حتى تُستوفى معايير الأهلية السريرية.'
                      : 'Approval is unavailable until clinical eligibility criteria are met.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _reasonDialog(
    BuildContext context,
    String title,
    String explanation,
    ValueChanged<String> onConfirmed,
  ) async {
    var reason = '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(explanation),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.isArabic
                      ? 'السبب المطلوب'
                      : 'Required reason',
                ),
                onChanged: (value) => updateDialog(() => reason = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: reason.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, reason.trim()),
              child: Text(context.isArabic ? 'تأكيد' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) onConfirmed(result);
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
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
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
