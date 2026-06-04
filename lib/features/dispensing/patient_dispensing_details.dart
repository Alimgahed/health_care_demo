import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
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
    switch (p.residencyStatus) {
      case ResidencyStatus.citizen:
        return '100%';
      case ResidencyStatus.resident:
        return '50%';
      case ResidencyStatus.visitor:
        return '0%';
    }
  }

  void _processDispensing(BuildContext context, Patient p, DataProvider dp) {
    if (!dp.canDispensePatient(p)) {
      dp.ensureEarlyDispenseReviewQueued(p.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('dispense_pending_clinical_msg', {'date': p.nextEligibleDate ?? ''})),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    _showPaymentSimulation(context, p, isOverride: false);
  }

  void _showPaymentSimulation(BuildContext context, Patient p, {bool isOverride = false}) {
    final double patientToPay = p.residencyStatus == ResidencyStatus.citizen
        ? 0.0
        : (p.residencyStatus == ResidencyStatus.resident ? 500.0 : 1000.0);

    final provider = Provider.of<DataProvider>(context, listen: false);
    final resolvedCenterId = provider.centers.any((c) => c.id == centerId)
        ? centerId
        : provider.centers.first.id;

    void completeDispense() {
      final ok = provider.dispenseMedication(
        patientId: p.id,
        centerId: resolvedCenterId,
        dose: p.currentDose,
        isOverride: isOverride,
      );
      if (!ok && context.mounted) {
        CustomToast.showMessage(context, context.tr('insufficient_inventory'), isError: true);
      }
    }

    if (patientToPay == 0.0) {
      completeDispense();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            patientName: p.getLocalizedFullName(context),
          ),
        ),
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        final p = dp.getPatientById(patient.id) ?? patient;
        final uiStatus = dp.dispensingUiStatus(p);
        final canDispense = dp.canDispensePatient(p);
        final doseLabel = context.mounjaroDoseLabel(p.currentDose);
        if (uiStatus == DispensingUiStatus.pendingClinicalReview) {
          dp.ensureEarlyDispenseReviewQueued(p.id);
        }

        return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dispensing_review')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClinicalEligibilityBanner(patient: p),
            if (!canDispense && uiStatus != DispensingUiStatus.clinicalIneligible)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        uiStatus == DispensingUiStatus.pendingCarePlan
                            ? context.tr('care_plan_pending_approval_msg')
                            : context.tr('dispense_pending_clinical_msg', {'date': p.nextEligibleDate ?? ''}),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.warning,
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(p.emiratesId, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(context, context.tr('current_dose'), doseLabel, isHighlight: true),
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
                        dp.dispensingFacilityLabel(context, p.lastDispensingCenterId),
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
                    Text(context.tr('coverage_payment'), style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildDetailRow(context, context.tr('total_cost'), '1,000.00 AED'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      context.tr('govt_subsidy_line', {'pct': _subsidyPct(context, p)}),
                      '${p.residencyStatus == ResidencyStatus.citizen ? '1,000.00' : (p.residencyStatus == ResidencyStatus.resident ? '500.00' : '0.00')} AED',
                      color: AppColors.success,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      context,
                      context.tr('patient_pay_line'),
                      '${p.residencyStatus == ResidencyStatus.citizen ? '0.00' : (p.residencyStatus == ResidencyStatus.resident ? '500.00' : '1,000.00')} AED',
                      isHighlight: true,
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
            onPressed: canDispense ? () => _processDispensing(context, p, dp) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canDispense ? AppColors.primary : AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              canDispense ? context.tr('proceed_copayment') : _statusLabel(context, uiStatus),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: isHighlight ? 18 : 16,
                color: color ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
