import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/mock_data.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/platform_state_view.dart';
import '../../clinical/patient_clinical_models.dart';
import '../models/treatment_plan.dart';
import '../../patient_app/medication_order/medication_order_wizard.dart';

class WebPlanMedicationView extends StatelessWidget {
  final Patient patient;

  const WebPlanMedicationView({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final currentPatient = data.getPatientById(patient.id);
    if (currentPatient == null) {
      return PlatformStateView(
        kind: PlatformStateKind.error,
        title: context.isArabic
            ? 'ملف المريض غير متاح'
            : 'Patient record unavailable',
        message: context.isArabic
            ? 'ارجع إلى الملف الصحي ثم حاول مرة أخرى.'
            : 'Return to your health profile and try again.',
      );
    }
    final plan = data.getPlanForPatient(currentPatient.id);
    if (plan == null) {
      return PlatformStateView(
        kind: PlatformStateKind.empty,
        title: context.isArabic
            ? 'لا توجد خطة دوائية نشطة'
            : 'No active medication plan',
        message: context.isArabic
            ? 'ستظهر تفاصيل الدواء عند اعتماد خطة العلاج.'
            : 'Medication details will appear when your care plan is approved.',
      );
    }
    final events = [...data.medicationEventsFor(currentPatient.id)]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final handovers = [...currentPatient.dispenseRecords]
      ..sort((a, b) => b.date.compareTo(a.date));
    final taken = events
        .where((event) => event.status == MedicationDoseStatus.taken)
        .length;
    final adherence = events.isEmpty ? null : taken / events.length;
    final queue = data.pharmacyRequestForPatient(currentPatient.id);

    return SingleChildScrollView(
      padding: AppLayout.pagePadding(MediaQuery.sizeOf(context).width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, plan, currentPatient),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050 ? 4 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric(
                        context.isArabic
                            ? 'الجرعة الموصوفة'
                            : 'Prescribed dose',
                        plan.medicationDose,
                        LucideIcons.syringe,
                        width,
                      ),
                      _metric(
                        context.isArabic ? 'تكرار الجرعة' : 'Dose interval',
                        context.isArabic
                            ? 'كل ${plan.medicationFrequencyDays} أيام'
                            : 'Every ${plan.medicationFrequencyDays} days',
                        LucideIcons.calendarClock,
                        width,
                      ),
                      _metric(
                        context.isArabic
                            ? 'الالتزام الموثق'
                            : 'Recorded adherence',
                        adherence == null
                            ? (context.isArabic
                                  ? 'لا توجد جرعات موثقة'
                                  : 'No dose events')
                            : '${(adherence * 100).toStringAsFixed(0)}%',
                        LucideIcons.circleCheck,
                        width,
                      ),
                      _metric(
                        context.isArabic ? 'آخر تسليم' : 'Last handover',
                        handovers.isEmpty ? '—' : handovers.first.date,
                        LucideIcons.packageCheck,
                        width,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 930;
                  final left = Column(
                    children: [
                      _planCard(context, plan, currentPatient, queue),
                      const SizedBox(height: 16),
                      _recordCard(context, data, plan, events),
                    ],
                  );
                  final right = Column(
                    children: [
                      _handoverCard(context, data, handovers),
                      const SizedBox(height: 16),
                      _eventCard(context, events),
                    ],
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 18),
                        Expanded(child: right),
                      ],
                    );
                  }
                  return Column(
                    children: [left, const SizedBox(height: 16), right],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    TreatmentPlan plan,
    Patient patient,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.navy, AppColors.primaryDark]),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.isArabic ? 'الخطة الدوائية' : 'Medication plan',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          'Mounjaro · ${plan.medicationDose}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.isArabic
              ? 'ملف ${patient.getLocalizedFullName(context)} · رقم الخطة ${plan.id}'
              : '${patient.getLocalizedFullName(context)} · Plan ${plan.id}',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _metric(String label, String value, IconData icon, double width) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _card(BuildContext context, String title, List<Widget> children) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      );

  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _planCard(
    BuildContext context,
    TreatmentPlan plan,
    Patient patient,
    PharmacyDispensingRequest? queue,
  ) => _card(
    context,
    context.isArabic
        ? 'الوصفة وحالة إعادة الصرف'
        : 'Prescription and refill status',
    [
      _fact(
        context.isArabic ? 'رقم الوصفة' : 'Prescription ID',
        plan.prescriptionId,
      ),
      _fact(
        context.isArabic ? 'الكمية' : 'Quantity',
        '${plan.medicationQuantity}',
      ),
      _fact(
        context.isArabic ? 'صلاحية الوصفة حتى' : 'Prescription valid until',
        _date(plan.prescriptionValidUntil),
      ),
      _fact(
        context.isArabic ? 'الطبيب المعالج' : 'Prescribing physician',
        plan.doctorName,
      ),
      _fact(
        context.isArabic ? 'استحقاق إعادة الصرف' : 'Next eligible refill',
        patient.nextEligibleDate ?? '—',
      ),
      _fact(
        context.isArabic ? 'طلب الصيدلية' : 'Pharmacy request',
        queue == null
            ? (context.isArabic ? 'لا يوجد طلب مفتوح' : 'No open request')
            : _queueStatus(context, queue.status),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MedicationOrderWizard(),
          ),
        ),
        icon: const Icon(LucideIcons.packagePlus),
        label: Text(context.isArabic ? 'طلب إعادة صرف' : 'Request a refill'),
      ),
    ],
  );

  Widget _recordCard(
    BuildContext context,
    DataProvider data,
    TreatmentPlan plan,
    List<MedicationDoseEvent> events,
  ) => _card(context, context.isArabic ? 'توثيق الجرعة' : 'Record a dose', [
    Text(
      context.isArabic
          ? 'اختر ما حدث في فترة الجرعة الحالية. يظهر التوثيق في ملف الرعاية لجميع الفرق المصرح لها.'
          : 'Record the current dose interval. Your care team can see the updated record.',
      style: TextStyle(color: AppColors.textSecondary),
    ),
    const SizedBox(height: 14),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _eventButton(
          context,
          data,
          plan,
          MedicationDoseStatus.taken,
          context.isArabic ? 'تم أخذ الجرعة' : 'Taken',
          LucideIcons.circleCheck,
        ),
        _eventButton(
          context,
          data,
          plan,
          MedicationDoseStatus.skipped,
          context.isArabic ? 'تم تخطيها' : 'Skipped',
          LucideIcons.circleMinus,
        ),
        _eventButton(
          context,
          data,
          plan,
          MedicationDoseStatus.missed,
          context.isArabic ? 'فاتت الجرعة' : 'Missed',
          LucideIcons.circleAlert,
        ),
      ],
    ),
    if (events.isEmpty) ...[
      const SizedBox(height: 12),
      Text(
        context.isArabic ? 'لم تُوثق أي جرعات بعد.' : 'No doses recorded yet.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    ],
  ]);

  Widget _eventButton(
    BuildContext context,
    DataProvider data,
    TreatmentPlan plan,
    MedicationDoseStatus status,
    String label,
    IconData icon,
  ) => OutlinedButton.icon(
    onPressed: () {
      final time = DateTime.now();
      data.logMedication(plan.id, time, status: status);
      final interval = plan.medicationFrequencyDays < 1
          ? 1
          : plan.medicationFrequencyDays;
      final slot = time.difference(plan.createdAt).inDays ~/ interval;
      final saved = data
          .medicationEventsFor(plan.patientId)
          .any(
            (event) =>
                event.planId == plan.id &&
                event.status == status &&
                event.scheduledAt.difference(plan.createdAt).inDays ~/
                        interval ==
                    slot,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? (context.isArabic
                      ? 'تم تحديث سجل الجرعات.'
                      : 'Dose record updated.')
                : (context.isArabic
                      ? 'تعذر تحديث سجل الجرعات.'
                      : 'Unable to update the dose record.'),
          ),
        ),
      );
    },
    icon: Icon(icon, size: 17),
    label: Text(label),
  );

  Widget _handoverCard(
    BuildContext context,
    DataProvider data,
    List<PatientDispenseRecord> handovers,
  ) => _card(
    context,
    context.isArabic ? 'سجل تسليم الدواء' : 'Medication handovers',
    [
      if (handovers.isEmpty)
        Text(
          context.isArabic
              ? 'لم يُسجل تسليم دواء بعد.'
              : 'No medication handover recorded.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      for (final record in handovers.take(8))
        _fact(
          record.date,
          '${record.dose} · ${data.dispensingFacilityLabel(context, record.centerId)}',
        ),
    ],
  );

  Widget _eventCard(BuildContext context, List<MedicationDoseEvent> events) =>
      _card(context, context.isArabic ? 'سجل الجرعات' : 'Dose history', [
        if (events.isEmpty)
          Text(
            context.isArabic
                ? 'لا توجد جرعات موثقة.'
                : 'No dose events recorded.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        for (final event in events.take(8))
          _fact(_date(event.recordedAt), _status(context, event.status)),
      ]);

  String _status(BuildContext context, MedicationDoseStatus status) =>
      switch (status) {
        MedicationDoseStatus.taken => context.isArabic ? 'تم أخذها' : 'Taken',
        MedicationDoseStatus.skipped =>
          context.isArabic ? 'تم تخطيها' : 'Skipped',
        MedicationDoseStatus.missed => context.isArabic ? 'فاتت' : 'Missed',
      };

  String _queueStatus(BuildContext context, PharmacyRequestStatus status) =>
      switch ((context.isArabic, status)) {
        (true, PharmacyRequestStatus.ready) => 'جاهز للصرف',
        (true, PharmacyRequestStatus.pendingReview) => 'بانتظار المراجعة',
        (true, PharmacyRequestStatus.notEligible) => 'غير مؤهل',
        (true, PharmacyRequestStatus.outOfStock) => 'غير متوفر بالمخزون',
        (true, PharmacyRequestStatus.expired) => 'منتهي الصلاحية',
        (true, PharmacyRequestStatus.cancelled) => 'ملغي',
        (true, PharmacyRequestStatus.dispensed) => 'تم الصرف',
        (false, PharmacyRequestStatus.ready) => 'Ready to dispense',
        (false, PharmacyRequestStatus.pendingReview) => 'Pending review',
        (false, PharmacyRequestStatus.notEligible) => 'Not eligible',
        (false, PharmacyRequestStatus.outOfStock) => 'Out of stock',
        (false, PharmacyRequestStatus.expired) => 'Expired',
        (false, PharmacyRequestStatus.cancelled) => 'Cancelled',
        (false, PharmacyRequestStatus.dispensed) => 'Dispensed',
      };

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
