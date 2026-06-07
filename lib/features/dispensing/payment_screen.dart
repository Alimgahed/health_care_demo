import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final Patient patient;
  final double amountToPay;
  final VoidCallback? onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.patient,
    required this.amountToPay,
    this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  String? _selectedMethod;
  bool _isProcessing = false;

  // Form controllers for Card
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (widget.amountToPay > 0 && _selectedMethod == null) return;
    
    setState(() => _isProcessing = true);

    // Show processing modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('processing_payment'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('please_wait_dont_close'),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate network delay
    Timer(const Duration(seconds: 3), () {
      Navigator.pop(context); // Close dialog
      setState(() => _isProcessing = false);
      widget.onPaymentSuccess?.call();
      _showSuccessScreen();
    });
  }

  void _showSuccessScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PaymentSuccessScreen(
          patient: widget.patient,
          amount: widget.amountToPay,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('patient_copayment'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left/Right side depending on RTL: Invoice summary
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildInvoiceSummary(),
                ),
              ),
              // Payment Methods
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('select_payment_method'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (widget.amountToPay > 0.0) ...[
                          _buildPaymentMethod(
                            context.tr('gov_health_wallet'),
                            LucideIcons.wallet,
                            'health_wallet',
                            AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentMethod(
                            context.tr('apple_pay'),
                            LucideIcons.apple,
                            'apple_pay',
                            Colors.black,
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentMethod(
                            context.tr('credit_debit'),
                            LucideIcons.creditCard,
                            'card',
                            AppColors.info,
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.checkCircle, color: AppColors.success, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    context.tr('payment_successful'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Animated Expandable Card Form
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: _selectedMethod == 'card'
                              ? _buildCardForm()
                              : const SizedBox.shrink(),
                        ),
                        
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (widget.amountToPay == 0.0 || _selectedMethod != null) && !_isProcessing ? _processPayment : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              context.tr('confirm_payment'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          context.tr('payment_summary'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(LucideIcons.receipt, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('copayment_invoice'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(context.tr('ministry_health'), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: AppColors.border),
              ),
              // Patient Info
              _buildInvoiceRow(context.tr('patient_name'), widget.patient.getLocalizedFullName(context)),
              const SizedBox(height: 12),
              _buildInvoiceRow(context.tr('file_number'), widget.patient.id),
              const SizedBox(height: 12),
              _buildInvoiceRow(context.tr('date'), DateTime.now().toString().split(' ')[0]),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: AppColors.border),
              ),
              // Item Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('mounjaro_terzepatide'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${context.tr('dose')} ${widget.patient.currentDose}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('1000.00 AED', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(context.tr('payment_govt_discount'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text('-${(1000.0 - widget.amountToPay).toStringAsFixed(2)} AED', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 24),
              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(context.tr('total_due'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.amountToPay.toStringAsFixed(2)} AED',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPaymentMethod(String title, IconData icon, String value, Color iconColor) {
    final isSelected = _selectedMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.03) : Colors.white,
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: isSelected ? AppColors.primary : iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.navy,
                ),
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: AppColors.primary),
            if (!isSelected)
              Icon(LucideIcons.circle, color: AppColors.border),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('card_details'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cardNumberCtrl,
              label: context.tr('card_number'),
              icon: LucideIcons.creditCard,
              hint: '0000 0000 0000 0000',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryCtrl,
                    label: context.tr('expiry_date'),
                    icon: LucideIcons.calendar,
                    hint: 'MM/YY',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvCtrl,
                    label: context.tr('cvv'),
                    icon: LucideIcons.lock,
                    hint: '123',
                    isPassword: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameCtrl,
              label: context.tr('name_on_card'),
              icon: LucideIcons.user,
              hint: context.tr('full_name'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final Patient? patient;
  final double amount;

  const PaymentSuccessScreen({super.key, this.patient, this.amount = 0});

  @override
  Widget build(BuildContext context) {
    final ref = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final dateStr = DateTime.now().toString().substring(0, 16);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The Receipt Card
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Green Area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.check, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('payment_successful'),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AED ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Receipt Details
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          _buildReceiptRow(context.tr('reference_number'), '#$ref'),
                          const SizedBox(height: 16),
                          _buildReceiptRow(context.tr('date_and_time'), dateStr),
                          if (patient != null) ...[
                            const SizedBox(height: 16),
                            _buildReceiptRow(context.tr('patient'), patient!.getLocalizedFullName(context)),
                            const SizedBox(height: 16),
                            _buildReceiptRow(context.tr('description'), '${context.tr('mounjaro_terzepatide')} - ${context.tr('dose')} ${patient!.currentDose}'),
                          ],
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(color: AppColors.border), 
                          ),
                          // Barcode mockup
                          Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '||| | || ||| || || | ||| ||',
                                style: TextStyle(fontSize: 32, letterSpacing: 2, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.printer),
                    label: Text(context.tr('print_receipt')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.home),
                    label: Text(context.tr('return_dashboard')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
      ],
    );
  }
}