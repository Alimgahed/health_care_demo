import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/demo/demo_session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/l10n_extension.dart';

class MedicationOrderWizard extends StatefulWidget {
  const MedicationOrderWizard({super.key});

  @override
  State<MedicationOrderWizard> createState() => _MedicationOrderWizardState();
}

class _MedicationOrderWizardState extends State<MedicationOrderWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  DispensingCenter? _selectedCenter;

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientId = context.watch<DemoSessionProvider>().patientId;
    final patient = context.watch<DataProvider>().getPatientById(patientId);
    if (patient == null) {
      return const Scaffold(
        body: Center(child: Text('Patient record unavailable.')),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? LucideIcons.arrowRight
                : LucideIcons.arrowLeft,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: _prevStep,
        ),
        title: Text(
          context.tr('wizard_title'),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: AppColors.border.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildEligibilityStep(patient, isDark),
          _buildFulfillmentStep(patient, isDark),
          _buildPaymentStep(patient, isDark),
          _buildSuccessStep(isDark),
        ],
      ),
    );
  }

  Widget _buildEligibilityStep(Patient patient, bool isDark) {
    final programEligibility = patient.programEligibility;
    final isWithinCooldown = patient.isWithinDispensingCooldown();
    final plan = context.read<DataProvider>().getPlanForPatient(patient.id);
    final bool overallEligible =
        programEligibility.eligible &&
        !isWithinCooldown &&
        plan != null &&
        plan.clinicalApprovalStatus == 'approved' &&
        plan.prescriptionValidUntil.isAfter(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard_eligibility_review'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('wizard_eligibility_desc'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),

          _buildCheckItem(
            context.tr('wizard_bmi_req'),
            context
                .tr('wizard_bmi_current')
                .replaceAll('{bmi}', patient.bmi.toStringAsFixed(1)),
            !programEligibility.violations.any(
              (v) => v.code.name == 'bmiTooLow',
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckItem(
            context.tr('wizard_glycemic_control'),
            context.tr('wizard_glycemic_desc'),
            !programEligibility.violations.any(
              (v) =>
                  v.code.name.contains('TooHigh') ||
                  v.code.name == 'labsMissing',
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckItem(
            context.tr('wizard_refill_schedule'),
            isWithinCooldown
                ? context.tr('wizard_refill_too_early')
                : context.tr('wizard_refill_ready'),
            !isWithinCooldown,
          ),
          const SizedBox(height: 32),

          if (overallEligible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('wizard_eligible_success'),
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: AppColors.error),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('wizard_ineligible_error'),
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: overallEligible ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('wizard_continue'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, String subtitle, bool passed) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (passed ? AppColors.success : AppColors.error).withValues(
              alpha: 0.15,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            passed ? LucideIcons.check : LucideIcons.x,
            color: passed ? AppColors.success : AppColors.error,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFulfillmentStep(Patient patient, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard_med_details'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // Prescribed Dose
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.pill, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('wizard_prescribed_med'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Mounjaro ${patient.currentDose}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.checkCircle2, color: AppColors.success),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            context.tr('wizard_how_receive'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          _buildFulfillmentCard(
            context.tr('wizard_pickup'),
            LucideIcons.store,
            true,
            () {},
          ),
          const SizedBox(height: 8),
          Text(
            context.isArabic
                ? 'الاستلام من منشأة الصرف هو الخيار المتاح لهذا العلاج.'
                : 'Collection at a dispensing centre is available for this treatment.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 24),
          _buildPickupSelection(patient),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCenter != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.isArabic ? 'مراجعة التغطية' : 'Review coverage',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentCard(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupSelection(Patient patient) {
    // Filter centers that have inventory
    final data = context.watch<DataProvider>();
    final plan = data.getPlanForPatient(patient.id);
    final availableCenters = data.centers
        .where(
          (c) =>
              plan != null &&
              data.availableStockForDose(c, plan.medicationDose) >=
                  plan.medicationQuantity,
        )
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('wizard_avail_pharmacies'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...availableCenters.map((center) {
          final isSelected = _selectedCenter?.id == center.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCenter = center),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          center.region,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    context.tr('wizard_in_stock'),
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentStep(Patient patient, bool isDark) {
    final data = context.read<DataProvider>();
    final assessment = data.coverageEstimateForPatient(patient.id);
    final plan = data.getPlanForPatient(patient.id);
    if (assessment == null) {
      return Center(
        child: Text(
          context.isArabic
              ? 'خطة العلاج غير متاحة.'
              : 'The treatment plan is unavailable.',
        ),
      );
    }
    final basePrice = assessment.totalAed;
    final govtPays = assessment.coveredAed;
    final copay = assessment.copayAed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wizard_order_summary'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  context.tr('wizard_medication'),
                  'Mounjaro ${plan?.medicationDose ?? patient.currentDose}',
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  context.tr('wizard_fulfillment'),
                  context.tr('wizard_store_pickup'),
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  context.tr('wizard_base_price'),
                  'AED ${basePrice.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  context.tr('wizard_govt_coverage'),
                  '- AED ${govtPays.toStringAsFixed(2)}',
                  color: AppColors.success,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('wizard_total_pay'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'AED ${copay.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            context.isArabic
                ? 'هذا تقدير للتغطية. تتم مراجعة أي مبلغ مستحق عند الاستلام.'
                : 'Coverage is an estimate. Any amount due is confirmed at collection.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCenter == null
                  ? null
                  : () {
                      final result = context
                          .read<DataProvider>()
                          .submitRefillRequest(
                            patientId: patient.id,
                            centerId: _selectedCenter!.id,
                          );
                      if (result.success) {
                        _nextStep();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.isArabic
                    ? 'إرسال طلب إعادة الصرف'
                    : 'Submit refill request',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.isArabic ? 'تم إرسال الطلب' : 'Request submitted',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.isArabic
                  ? 'استلمت منشأة الصرف المختارة طلبك. يمكنك متابعة الحالة من خطة العلاج.'
                  : 'The selected dispensing centre has received your request. You can follow its status in your treatment plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop back to the parent screen and notify of success
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('wizard_back_dashboard'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
