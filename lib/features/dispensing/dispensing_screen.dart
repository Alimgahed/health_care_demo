import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_toast.dart';
import 'patient_dispensing_details.dart';

class DispensingScreen extends StatefulWidget {
  final String? highlightPatientId;

  const DispensingScreen({super.key, this.highlightPatientId});

  @override
  State<DispensingScreen> createState() => _DispensingScreenState();
}

class _DispensingScreenState extends State<DispensingScreen> {
  final TextEditingController _searchController = TextEditingController();

  Patient? _findPatient(DataProvider provider, String query) {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      return provider.patients.firstWhere(
        (p) =>
            p.emiratesId.contains(q) ||
            p.id.toLowerCase() == q.toLowerCase() ||
            p.getLocalizedFullName(context).toLowerCase().contains(q.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  void _searchPatient() {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final match = _findPatient(provider, _searchController.text);

    if (match == null) {
      CustomToast.showMessage(context, context.tr('patient_not_found'), isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDispensingDetails(patient: match),
      ),
    );
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
              Text(context.tr('scanning_qr'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.pop(context);
      final provider = Provider.of<DataProvider>(context, listen: false);
      final query = _searchController.text.trim();
      Patient? patient;
      if (query.isNotEmpty) {
        patient = _findPatient(provider, query);
      }
      patient ??= provider.patients.firstWhere(
        (p) => p.id == 'P001',
        orElse: () => provider.patients.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDispensingDetails(patient: patient!),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.highlightPatientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openHighlightPatient());
    }
  }

  void _openHighlightPatient() {
    if (!mounted) return;
    final provider = Provider.of<DataProvider>(context, listen: false);
    final p = provider.getPatientById(widget.highlightPatientId!);
    if (p == null) return;
    _searchController.text = p.emiratesId;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PatientDispensingDetails(patient: p)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dispensing_facility')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('patient_search'), style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              context.tr('patient_search_sub'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('search_eid_hint'),
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
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
                    context.tr('or_divider'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Expanded(child: Container(height: 1, color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(LucideIcons.qrCode),
              label: Text(context.tr('scan_qr')),
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
