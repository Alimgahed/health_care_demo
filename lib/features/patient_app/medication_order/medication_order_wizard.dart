import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/mock_data.dart';
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

  bool _isEligible = false;
  bool _eligibilityChecked = false;
  
  String _fulfillmentType = 'pickup'; // 'pickup' or 'delivery'
  DispensingCenter? _selectedCenter;
  final TextEditingController _addressController = TextEditingController();

  bool _isProcessing = false;

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
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = Provider.of<DataProvider>(context).patients.first;
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
            color: isDark ? Colors.white : AppColors.navy,
          ),
          onPressed: _prevStep,
        ),
        title: Text(
          context.tr('wizard_title'),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: AppColors.border.withValues(alpha: 0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
    final bool overallEligible = programEligibility.eligible && !isWithinCooldown;

    // We do a delayed check to simulate loading
    if (!_eligibilityChecked) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _eligibilityChecked = true;
            _isEligible = overallEligible;
          });
        }
      });
      return  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(context.tr('wizard_checking_eligibility'), style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          _buildCheckItem(
            context.tr('wizard_bmi_req'),
            context.tr('wizard_bmi_current').replaceAll('{bmi}', patient.bmi.toStringAsFixed(1)),
            !programEligibility.violations.any((v) => v.code.name == 'bmiTooLow'),
          ),
          const SizedBox(height: 16),
          _buildCheckItem(
            context.tr('wizard_glycemic_control'),
            context.tr('wizard_glycemic_desc'),
            !programEligibility.violations.any((v) => v.code.name.contains('TooHigh') || v.code.name == 'labsMissing'),
          ),
          const SizedBox(height: 16),
          _buildCheckItem(
            context.tr('wizard_refill_schedule'),
            isWithinCooldown ? context.tr('wizard_refill_too_early') : context.tr('wizard_refill_ready'),
            !isWithinCooldown,
          ),
          const SizedBox(height: 32),
          
          if (_isEligible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child:  Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('wizard_eligible_success'),
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
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
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child:  Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: AppColors.error),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('wizard_ineligible_error'),
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEligible ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('wizard_continue'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            color: (passed ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                  child: const Icon(LucideIcons.pill, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('wizard_prescribed_med'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('Mounjaro ${patient.currentDose}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.checkCircle2, color: AppColors.success),
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
          
          Row(
            children: [
              Expanded(
                child: _buildFulfillmentCard(
                  context.tr('wizard_pickup'),
                  LucideIcons.store,
                  _fulfillmentType == 'pickup',
                  () => setState(() => _fulfillmentType = 'pickup'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFulfillmentCard(
                  context.tr('wizard_delivery'),
                  LucideIcons.truck,
                  _fulfillmentType == 'delivery',
                  () => setState(() => _fulfillmentType = 'delivery'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          if (_fulfillmentType == 'pickup') _buildPickupSelection(patient)
          else _buildDeliverySelection(),
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_fulfillmentType == 'pickup' && _selectedCenter != null) || (_fulfillmentType == 'delivery' && _addressController.text.isNotEmpty)
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('wizard_continue_payment'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentCard(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
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
    final availableCenters = MockData.centers.where((c) => c.totalAvailable > 0).take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('wizard_avail_pharmacies'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...availableCenters.map((center) {
          final isSelected = _selectedCenter?.id == center.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCenter = center),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                    ),
                    child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary))) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(center.region, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(context.tr('wizard_in_stock'), style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeliverySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('wizard_deliv_address'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr('wizard_enter_address'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          onChanged: (v) => setState((){}),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(Patient patient, bool isDark) {
    final double basePrice = 1000.0;
    double coverage = 0.0;
    
    if (patient.residencyStatus == ResidencyStatus.citizen) {
      coverage = 1.0;
    } else if (patient.residencyStatus == ResidencyStatus.resident) {
      coverage = 0.5;
    }
    
    final double govtPays = basePrice * coverage;
    final double copay = basePrice - govtPays;

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
                _buildSummaryRow(context.tr('wizard_medication'), 'Mounjaro ${patient.currentDose}'),
                const Divider(height: 24),
                _buildSummaryRow(context.tr('wizard_fulfillment'), _fulfillmentType == 'pickup' ? context.tr('wizard_store_pickup') : context.tr('wizard_home_delivery')),
                const Divider(height: 24),
                _buildSummaryRow(context.tr('wizard_base_price'), 'AED ${basePrice.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildSummaryRow(context.tr('wizard_govt_coverage'), '- AED ${govtPays.toStringAsFixed(2)}', color: AppColors.success),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('wizard_total_pay'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('AED ${copay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          if (copay > 0) ...[
            Text(context.tr('wizard_payment_method'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.creditCard, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Apple Pay / Credit Card', style: TextStyle(fontWeight: FontWeight.bold))),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 6),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () async {
                setState(() => _isProcessing = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) {
                  setState(() => _isProcessing = false);
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(copay > 0 ? context.tr('wizard_pay_confirm').replaceAll('{amount}', copay.toStringAsFixed(2)) : context.tr('wizard_confirm_order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
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
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('wizard_order_confirmed'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fulfillmentType == 'pickup'
                  ? context.tr('wizard_pickup_msg').replaceAll('{center}', _selectedCenter?.name ?? '')
                  : context.tr('wizard_delivery_msg'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.tr('wizard_back_dashboard'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
