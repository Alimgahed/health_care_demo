import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/auth/access_control.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_toast.dart';
import '../clinical/clinical_eligibility_banner.dart';
import 'payment_screen.dart';

class PatientDispensingDetails extends StatelessWidget {
  final Patient patient;
  final String centerId;

  const PatientDispensingDetails({
    super.key,
    required this.patient,
    this.centerId = 'C001',
  });

  String _statusLabel(BuildContext context, DispensingUiStatus status) {
    switch (status) {
      case DispensingUiStatus.eligible:
        return context.tr('eligible_dispensation');
      case DispensingUiStatus.approvedEarly:
        return context.tr('status_clinical_approved_dispense');
      case DispensingUiStatus.pendingCarePlan:
        return context.tr('status_pending_care_plan');
      case DispensingUiStatus.pendingClinicalReview:
        return context.tr('status_pending_clinical_review');
      case DispensingUiStatus.clinicalIneligible:
        return context.tr('status_program_ineligible');
    }
  }

  String _subsidyPct(BuildContext context, Patient p) {
    final rate = DemoFinancialSupportPolicy.coverageRateFor(p.residencyStatus);
    return '${(rate * 100).toStringAsFixed(0)}%';
  }

  void _processDispensing(BuildContext context, Patient p, DataProvider dp) {
    final access = Provider.of<AccessControlProvider>(context, listen: false);
    final centerId = dp.centers.any((center) => center.id == this.centerId)
        ? this.centerId
        : (dp.centers.isEmpty ? '' : dp.centers.first.id);
    final validation = dp.validateDispensing(
      patientId: p.id,
      centerId: centerId,
      hasPermission: access.can(AppPermission.dispenseMedication),
    );
    if (!validation.canDispense) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.issues.join(' ')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    _showHandoverReview(context, p, centerId: centerId, isOverride: false);
  }

  void _showHandoverReview(
    BuildContext context,
    Patient p, {
    required String centerId,
    bool isOverride = false,
  }) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final patientToPay =
        provider.coverageEstimateForPatient(p.id)?.copayAed ?? 0.0;
    final access = Provider.of<AccessControlProvider>(context, listen: false);
    final plan = provider.getPlanForPatient(p.id);
    final request = provider.pharmacyRequestForPatient(p.id);

    Future<bool> completeDispense() async {
      if (plan == null || request == null) return false;
      final ok = provider.dispenseMedication(
        patientId: p.id,
        centerId: centerId,
        dose: plan.medicationDose,
        authorized: access.can(AppPermission.dispenseMedication),
        requestId: request.id,
        isOverride: isOverride,
      );
      if (!ok && context.mounted) {
        CustomToast.showMessage(
          context,
          context.tr('insufficient_inventory'),
          isError: true,
        );
      }
      return ok;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          patient: p,
          amountToPay: patientToPay,
          onPaymentSuccess: completeDispense,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        final p = dp.getPatientById(patient.id) ?? patient;
        final access = context.watch<AccessControlProvider>();
        final resolvedCenterId = dp.centers.any((c) => c.id == centerId)
            ? centerId
            : (dp.centers.isEmpty ? '' : dp.centers.first.id);
        final validation = dp.validateDispensing(
          patientId: p.id,
          centerId: resolvedCenterId,
          hasPermission: access.can(AppPermission.dispenseMedication),
        );
        final canDispense = validation.canDispense;
        final uiStatus = dp.dispensingUiStatus(p);
        final doseLabel = context.mounjaroDoseLabel(
          validation.plan?.medicationDose ?? p.currentDose,
        );
        final coverage = dp.coverageEstimateForPatient(p.id);
        String aed(double? value) =>
            value == null ? '—' : '${value.toStringAsFixed(2)} AED';

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('dispensing_review'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClinicalEligibilityBanner(patient: p),
                if (validation.issues.isNotEmpty)
                  Card(
                    color: AppColors.error.withValues(alpha: .06),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        validation.issues.join('\n'),
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                if (validation.warnings.isNotEmpty)
                  Card(
                    color: AppColors.warning.withValues(alpha: .08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final warning in validation.warnings)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.triangleAlert,
                                    size: 16,
                                    color: AppColors.warningText,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      warning,
                                      style: TextStyle(
                                        color: AppColors.warningText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!canDispense &&
                    uiStatus != DispensingUiStatus.clinicalIneligible)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.clock, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            uiStatus == DispensingUiStatus.pendingCarePlan
                                ? context.tr('care_plan_pending_approval_msg')
                                : context.tr('dispense_pending_clinical_msg', {
                                    'date': p.nextEligibleDate ?? '',
                                  }),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.warningText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                p.getLocalizedFullName(context).substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.getLocalizedFullName(context),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    p.emiratesId,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  if (dp.getPlanForPatient(p.id) != null)
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.clipboardCheck,
                                          size: 14,
                                          color: AppColors.successText,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            context.isArabic
                                                ? 'توجد خطة علاج حالية'
                                                : 'Active treatment plan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.successText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.clipboardX,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            context.isArabic
                                                ? 'لا توجد خطة علاج'
                                                : 'No active plan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildDetailRow(
                          context,
                          context.tr('current_dose'),
                          doseLabel,
                          isHighlight: true,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          context.tr('last_dispensed'),
                          p.lastDispensingDate ?? context.tr('never'),
                        ),
                        if (p.lastDispensingCenterId != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            context.tr('last_dispensing_facility'),
                            dp.dispensingFacilityLabel(
                              context,
                              p.lastDispensingCenterId,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          context.tr('next_eligible'),
                          p.nextEligibleDate ?? context.tr('now'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('coverage_payment'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          context,
                          context.tr('total_cost'),
                          aed(coverage?.totalAed),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          context.tr('govt_subsidy_line', {
                            'pct': _subsidyPct(context, p),
                          }),
                          aed(coverage?.coveredAed),
                          color: AppColors.successText,
                        ),
                        const Divider(height: 32),
                        _buildDetailRow(
                          context,
                          context.tr('patient_pay_line'),
                          aed(coverage?.copayAed),
                          isHighlight: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.isArabic
                              ? 'تقدير توضيحي؛ ليس سياسة تغطية معتمدة'
                              : 'Illustrative estimate; not an approved benefit policy',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: canDispense
                    ? () => _processDispensing(context, p, dp)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canDispense
                      ? AppColors.primary
                      : AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  canDispense
                      ? (context.isArabic
                            ? 'مراجعة وتسليم الدواء'
                            : 'Review medication handover')
                      : _statusLabel(context, uiStatus),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlight ? 18 : 16,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
