import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/theme/app_colors.dart';
import 'payment_screen.dart';

class PatientDispensingDetails extends StatelessWidget {
  final Patient patient;

  const PatientDispensingDetails({
    super.key,
    required this.patient,
  });

  bool get _isDuplicateRisk {
    // Mock logic: if dispensed this month (using June 2026 as current)
    if (patient.lastDispensingDate != null) {
      if (patient.lastDispensingDate!.contains('2026-06')) {
        return true;
      }
    }
    return false;
  }

  void _processDispensing(BuildContext context) {
    if (_isDuplicateRisk) {
      _showDuplicateWarning(context);
    } else {
      _showPaymentSimulation(context);
    }
  }

  void _showDuplicateWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
        title: const Text('Duplicate Dispensing Alert'),
        content: Text(
          'Patient ${patient.getLocalizedFullName(context)} already received Mounjaro recently on ${patient.lastDispensingDate}. Next eligible date is ${patient.nextEligibleDate}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle override request...
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Request Manual Override'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSimulation(BuildContext context) {
    final double patientToPay = patient.residencyStatus == ResidencyStatus.citizen ? 0.0 : 
                                (patient.residencyStatus == ResidencyStatus.resident ? 500.0 : 1000.0);
    
    final provider = Provider.of<DataProvider>(context, listen: false);
    final centerId = provider.centers.isNotEmpty ? provider.centers.first.id : 'center_1';
    
    if (patientToPay == 0.0) {
      provider.dispenseMedication(
        patientId: patient.id,
        centerId: centerId,
        dose: patient.currentDose,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            patient: patient,
            amountToPay: patientToPay,
            onPaymentSuccess: () {
              provider.dispenseMedication(
                patientId: patient.id,
                centerId: centerId,
                dose: patient.currentDose,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispensing Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isDuplicateRisk)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldAlert, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'WARNING: Patient received medication recently. Dispensing blocked until ${patient.nextEligibleDate}.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
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
                          child: Text(patient.getLocalizedFullName(context).substring(0, 1), style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient.getLocalizedFullName(context), style: Theme.of(context).textTheme.titleLarge),
                              Text(patient.emiratesId, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(context, 'Current Dose', patient.currentDose, isHighlight: true),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Last Dispensed', patient.lastDispensingDate ?? 'Never'),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Next Eligible', patient.nextEligibleDate ?? 'Now'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Subsidy summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coverage & Payment', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildDetailRow(context, 'Total Cost', '1,000.00 AED'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context, 
                      'Govt. Subsidy (${patient.residencyStatus == ResidencyStatus.citizen ? '100%' : (patient.residencyStatus == ResidencyStatus.resident ? '50%' : '0%')})', 
                      '${patient.residencyStatus == ResidencyStatus.citizen ? '1,000.00' : (patient.residencyStatus == ResidencyStatus.resident ? '500.00' : '0.00')} AED',
                      color: AppColors.success,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      context, 
                      'Patient to Pay', 
                      '${patient.residencyStatus == ResidencyStatus.citizen ? '0.00' : (patient.residencyStatus == ResidencyStatus.resident ? '500.00' : '1,000.00')} AED',
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
            onPressed: () => _processDispensing(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDuplicateRisk ? AppColors.error : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _isDuplicateRisk ? 'Review Dispensing Alert' : 'Proceed to Payment',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
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
