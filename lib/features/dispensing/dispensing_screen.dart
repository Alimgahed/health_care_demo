import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/theme/app_colors.dart';
import 'patient_dispensing_details.dart';

class DispensingScreen extends StatefulWidget {
  const DispensingScreen({super.key});

  @override
  State<DispensingScreen> createState() => _DispensingScreenState();
}

class _DispensingScreenState extends State<DispensingScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _searchPatient() {
    if (_searchController.text.isNotEmpty) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      
      // Look for match by Emirates ID or Name
      final match = provider.patients.firstWhere(
        (p) => p.emiratesId.contains(_searchController.text) || 
               p.getLocalizedFullName(context).toLowerCase().contains(_searchController.text.toLowerCase()),
        orElse: () => provider.patients.first, // Fallback to first if not found
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDispensingDetails(
            patient: match,
          ),
        ),
      );
    }
  }

  void _scanQrCode() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.scanLine, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Scanning QR Code...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close dialog
      final provider = Provider.of<DataProvider>(context, listen: false);
      
      // Navigate using the second patient (who recently dispensed to show warning)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDispensingDetails(
            patient: provider.patients[1], // Sarah Johnson
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispensing Center'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Patient Search',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter Emirates ID or scan patient QR code to proceed with dispensing.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter Emirates ID (e.g. 784-...) or Name',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
                  onPressed: _searchPatient,
                ),
              ),
              onSubmitted: (_) => _searchPatient(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Container(height: 1, color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(LucideIcons.qrCode),
              label: const Text('Scan Patient QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkSurface,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
