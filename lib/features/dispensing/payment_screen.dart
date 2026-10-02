import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

/// Coverage review and medication handover. No payment collection is recorded.
class PaymentScreen extends StatefulWidget {
  final Patient patient;
  final double amountToPay;
  final Future<bool> Function()? onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.patient,
    required this.amountToPay,
    this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _submitting = false;

  Future<void> _confirmHandover() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    bool completed = false;
    try {
      completed =
          await (widget.onPaymentSuccess?.call() ?? Future.value(false));
    } catch (_) {
      completed = false;
    }
    if (!mounted) return;
    if (completed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PaymentSuccessScreen(patient: widget.patient),
        ),
      );
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            context.isArabic
                ? 'تعذّر الصرف. تحقق من الطلب والمخزون ثم حاول مجدداً.'
                : 'Dispensing could not be completed. Check the request and stock, then try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final patient = data.getPatientById(widget.patient.id) ?? widget.patient;
    final plan = data.getPlanForPatient(patient.id);
    final queue = data.pharmacyRequestForPatient(patient.id);
    final linkedRequest = queue == null
        ? null
        : data.treatmentRequestById(queue.treatmentRequestId);
    final coverage = linkedRequest == null
        ? data.coverageEstimateForPatient(patient.id)
        : data.coverageForRequest(linkedRequest.id);
    final canConfirm =
        plan != null &&
        queue != null &&
        queue.status == PharmacyRequestStatus.ready &&
        linkedRequest != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.isArabic ? 'مراجعة الصرف' : 'Dispensing review'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.isArabic
                          ? 'تأكيد تسليم الدواء'
                          : 'Confirm medication handover',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.isArabic
                          ? 'راجع هوية المريض والجرعة والتغطية قبل إتمام الصرف.'
                          : 'Review patient identity, dose, and coverage before dispensing.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    _detail(
                      context.isArabic ? 'المريض' : 'Patient',
                      patient.getLocalizedFullName(context),
                    ),
                    _detail(
                      context.isArabic ? 'رقم الملف' : 'Patient ID',
                      patient.id,
                    ),
                    _detail(
                      context.isArabic ? 'رقم الطلب' : 'Request ID',
                      queue?.id ?? '—',
                    ),
                    _detail(
                      context.isArabic
                          ? 'الدواء والجرعة'
                          : 'Medication and dose',
                      plan == null
                          ? '—'
                          : '${queue?.medication ?? 'Mounjaro'} · ${plan.medicationDose}',
                    ),
                    _detail(
                      context.isArabic ? 'الكمية' : 'Quantity',
                      plan?.medicationQuantity.toString() ?? '—',
                    ),
                    const Divider(height: 28),
                    _detail(
                      context.isArabic ? 'التكلفة المقدرة' : 'Estimated cost',
                      _aed(coverage?.totalAed),
                    ),
                    _detail(
                      context.isArabic
                          ? 'التغطية المقدرة'
                          : 'Estimated coverage',
                      _aed(coverage?.coveredAed),
                    ),
                    _detail(
                      context.isArabic
                          ? 'حصة المريض المستحقة'
                          : 'Patient share due',
                      _aed(coverage?.copayAed),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.isArabic
                          ? 'تعرض هذه الشاشة تقدير التغطية فقط. لا تسجل عملية تحصيل مالي.'
                          : 'This screen records the medication handover and coverage estimate. It does not record payment collection.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (!canConfirm)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.isArabic
                              ? 'الطلب غير جاهز للصرف. ارجع إلى قائمة الصيدلية للمراجعة.'
                              : 'This request is not ready to dispense. Return to the pharmacy queue for review.',
                          style: TextStyle(color: AppColors.errorText),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canConfirm && !_submitting
                            ? _confirmHandover
                            : null,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.packageCheck),
                        label: Text(
                          context.isArabic
                              ? 'تأكيد الصرف'
                              : 'Confirm dispensing',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  String _aed(double? amount) =>
      amount == null ? '—' : 'AED ${amount.toStringAsFixed(2)}';
}

class PaymentSuccessScreen extends StatelessWidget {
  final Patient? patient;
  final double amount;

  const PaymentSuccessScreen({super.key, this.patient, this.amount = 0});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final current = patient == null ? null : data.getPatientById(patient!.id);
    final dispense = current?.dispenseRecords.isNotEmpty == true
        ? current!.dispenseRecords.last
        : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.isArabic ? 'تأكيد الصرف' : 'Dispensing confirmation',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.circleCheck,
                    color: AppColors.successText,
                    size: 52,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.isArabic ? 'تم صرف الدواء' : 'Medication dispensed',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current?.getLocalizedFullName(context) ?? '—',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  if (dispense != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${dispense.dose} · ${dispense.date}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.isArabic
                          ? 'العودة للصيدلية'
                          : 'Return to pharmacy',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
