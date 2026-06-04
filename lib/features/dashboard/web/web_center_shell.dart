import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../dispensing/payment_screen.dart';
import '../../auth/login_screen.dart';
import '../../../core/widgets/custom_toast.dart';


class WebCenterShell extends StatefulWidget {
  const WebCenterShell({super.key});

  @override
  State<WebCenterShell> createState() => _WebCenterShellState();
}

class _WebCenterShellState extends State<WebCenterShell> {
  int _selectedIndex = 0; // 0 = Dispense medication, 1 = Live Inventory, 2 = Dispense Logs
  Patient? _activePatient;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _centerId = 'C001'; // Mocked as Dubai Central Hospital for this shell

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    // Get current center details
    final center = dataProvider.centers.firstWhere((c) => c.id == _centerId, orElse: () => dataProvider.centers.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.pill, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              '${center.getLocalizedName(context)} - Dispensing Center Portal',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navy),
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () => localeProvider.toggleLanguage(),
            icon: const Icon(LucideIcons.globe, color: AppColors.navy),
            label: Text(
              localeProvider.locale.languageCode == 'en' ? 'العربية' : 'English',
              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(t),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: _selectedIndex == 0
                ? _buildDispenseView(t, dataProvider, center)
                : (_selectedIndex == 1 
                    ? _buildInventoryView(t, dataProvider, center)
                    : _buildLogsView(t, dataProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations t) {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildSidebarItem(LucideIcons.scanLine, 'Dispense Medication', 0),
          _buildSidebarItem(LucideIcons.package, 'Live Stock Inventory', 1),
          _buildSidebarItem(LucideIcons.history, 'Dispensing Activity Logs', 2),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: Icon(LucideIcons.building, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pharmacist Admin', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                      Text('Dubai Central Depot', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.navy,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDispenseView(AppLocalizations t, DataProvider provider, DispensingCenter center) {
    // Left suggestions, right action form
    final suggestions = provider.patients.where((p) {
      if (_searchQuery.isEmpty) {
        // Return patients who haven't dispensed recently (due/eligible)
        return p.lastDispensingDate == null || !p.lastDispensingDate!.contains('2026-06');
      }
      return p.getLocalizedFullName(context).toLowerCase().contains(_searchQuery.toLowerCase()) || p.emiratesId.contains(_searchQuery);
    }).take(10).toList();

    return Row(
      children: [
        // Left Column (Patient Search & Selection) - 35%
        SizedBox(
          width: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Patient', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    const Text('Search Emirates ID or select an eligible patient below.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter Emirates ID or Name',
                        prefixIcon: Icon(LucideIcons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                child: Text(
                  _searchQuery.isEmpty ? 'Suggested Patients (Due/Eligible)' : 'Search Results',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, idx) {
                    final patient = suggestions[idx];
                    bool isSelected = _activePatient != null && _activePatient!.id == patient.id;
                    return Container(
                      color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                          child: Text(
                            patient.getLocalizedFullName(context).substring(0, 1).toUpperCase(),
                            style: TextStyle(color: isSelected ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(patient.getLocalizedFullName(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(patient.emiratesId, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _activePatient = patient;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppColors.border),
        // Right Column (Medication Dispensing details & verify) - 65%
        Expanded(
          child: _activePatient == null
              ? _buildEmptyState('Select a patient from the list or enter details to start verification')
              : _buildVerificationPane(context, _activePatient!, center, provider),
        ),
      ],
    );
  }

  Widget _buildVerificationPane(BuildContext context, Patient patient, DispensingCenter center, DataProvider provider) {
    // Check eligibility
    bool isDuplicateRisk = patient.lastDispensingDate != null && patient.lastDispensingDate!.contains('2026-06');
    final double price = 1000.0;
    final double coverage = patient.residencyStatus == ResidencyStatus.citizen ? 1.0 :
                            (patient.residencyStatus == ResidencyStatus.resident ? 0.5 : 0.0);
    final double govtPays = price * coverage;
    final double patientPays = price - govtPays;

    // Center stock checks
    int stock = 0;
    if (patient.currentDose == '2.5 mg') stock = center.inventory2_5mg;
    else if (patient.currentDose == '5 mg') stock = center.inventory5mg;
    else if (patient.currentDose == '7.5 mg') stock = center.inventory7_5mg;
    else if (patient.currentDose == '10 mg') stock = center.inventory10mg;
    
    bool outOfStock = stock <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dispensing Checkout & Safety Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDuplicateRisk ? AppColors.error.withOpacity(0.08) : AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDuplicateRisk ? AppColors.error.withOpacity(0.2) : AppColors.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDuplicateRisk ? LucideIcons.shieldAlert : LucideIcons.checkCircle,
                      color: isDuplicateRisk ? AppColors.error : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDuplicateRisk ? 'Safety Alert: Duplicate Dispense' : 'Eligible for Dispensation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDuplicateRisk ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (isDuplicateRisk)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Alert: This patient already received their Mounjaro dosage on ${patient.lastDispensingDate}. Dispensing another dose requires an administrative override for clinical necessity.',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Patient Profile & Prescribed Dose
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Patient Diagnostics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 20),
                        _buildDetailRow('Full Name', patient.getLocalizedFullName(context)),
                        const SizedBox(height: 12),
                        _buildDetailRow('Emirates ID', patient.emiratesId),
                        const SizedBox(height: 12),
                        _buildDetailRow('Residency Status', patient.residencyStatus.toString().split('.')[1].toUpperCase()),
                        const SizedBox(height: 12),
                        _buildDetailRow('Active Prescription', patient.currentDose, isHighlight: true),
                        const SizedBox(height: 12),
                        _buildDetailRow('Last Dispense Date', patient.lastDispensingDate ?? 'Never Dispensed'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Column 2: Financial Calculator & Stock Check
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Coverage Calculation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 20),
                        _buildDetailRow('Medication Cost', '1,000.00 AED'),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Govt. Subsidy (${(coverage * 100).toStringAsFixed(0)}%)',
                          '${govtPays.toStringAsFixed(2)} AED',
                          color: AppColors.success,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow('Patient Copay to Collect', '${patientPays.toStringAsFixed(2)} AED', isHighlight: true),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(LucideIcons.package, color: outOfStock ? AppColors.error : AppColors.success, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              outOfStock ? 'Out of stock at this clinic' : 'Stock level: $stock units available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: outOfStock ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Action Buttons Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activePatient = null;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              
              if (isDuplicateRisk)
                ElevatedButton.icon(
                  onPressed: outOfStock 
                      ? null 
                      : () => _showManualOverrideDialog(context, patient, center, provider),
                  icon: const Icon(LucideIcons.shieldAlert),
                  label: const Text('Request Manual Override & Dispense'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                )
              else
                ElevatedButton.icon(
                  onPressed: outOfStock 
                      ? null 
                      : () => _dispenseMedicationDirectly(context, patient, center, provider, patientPays),
                  icon: const Icon(LucideIcons.check),
                  label: const Text('Confirm Verification & Dispense'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlight ? 16 : 14,
            color: color ?? AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.scanFace, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInventoryView(AppLocalizations t, DataProvider provider, DispensingCenter center) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventory Stock Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          const Text('Monitor stock levels of Mounjaro pens and request restocking supplies.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _buildStockCard('Mounjaro 2.5 mg', center.inventory2_5mg, 'C001_2.5')),
              const SizedBox(width: 16),
              Expanded(child: _buildStockCard('Mounjaro 5.0 mg', center.inventory5mg, 'C001_5.0')),
              const SizedBox(width: 16),
              Expanded(child: _buildStockCard('Mounjaro 7.5 mg', center.inventory7_5mg, 'C001_7.5')),
              const SizedBox(width: 16),
              Expanded(child: _buildStockCard('Mounjaro 10.0 mg', center.inventory10mg, 'C001_10.0')),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Inventory Restock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 12),
                  const Text('Need additional Mounjaro supply? Submit a direct digital request to the MoH Central Pharmacy Depot.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          provider.updateInventory(center.id, d2_5: 20, d5: 20, d7_5: 20, d10: 20);
                          CustomToast.show(
                            context,
                            title: 'Stock Updated',
                            message: 'Restocking request approved. Added 20 units per dose to local inventory.',
                            icon: LucideIcons.package,
                            color: AppColors.success,
                          );

                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Simulate Depot Restock (+20 Units each)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(String doseTitle, int stock, String code) {
    bool lowStock = stock < 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(LucideIcons.package, color: AppColors.primary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lowStock ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lowStock ? 'Low Stock' : 'Good Stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: lowStock ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '$stock',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: lowStock ? AppColors.error : AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(doseTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text('SKU: $code', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsView(AppLocalizations t, DataProvider provider) {
    final centerLogs = provider.logs.where((l) => l.centerName == 'Dubai Central Hospital' || l.centerName == 'Dubai Central Depot').toList();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Center Activity Log', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          const Text('Displaying dispensations, overrides, and restocks processed recently.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ListView.separated(
                  itemCount: centerLogs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = centerLogs[index];
                    bool overridden = log.getLocalizedStatus(context) == 'Overridden';
                    return ListTile(
                      leading: Icon(
                        overridden ? LucideIcons.shieldAlert : LucideIcons.checkCircle,
                        color: overridden ? AppColors.error : AppColors.success,
                      ),
                      title: Text('${log.getLocalizedPatientName(context)} - ${log.getLocalizedAction(context)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                      subtitle: Text('Processed: ${log.timestamp.toString().split('.')[0]}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: overridden ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.getLocalizedStatus(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: overridden ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dispenseMedicationDirectly(
    BuildContext context,
    Patient patient,
    DispensingCenter center,
    DataProvider provider,
    double copay,
  ) {
    if (copay > 0.0) {
      // Direct payment flow
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            patient: patient,
            amountToPay: copay,
            onPaymentSuccess: () {
              provider.dispenseMedication(
                patientId: patient.id,
                centerId: center.id,
                dose: patient.currentDose,
              );
              setState(() {
                _activePatient = null;
              });
              CustomToast.show(
                context,
                title: 'Medication Dispensed',
                message: 'Mounjaro ${patient.currentDose} successfully dispensed to ${patient.getLocalizedFullName(context)}.',
                icon: LucideIcons.checkCircle,
                color: AppColors.success,
              );

            },
          ),
        ),
      );
    } else {
      // Citizen free subsidy
      final success = provider.dispenseMedication(
        patientId: patient.id,
        centerId: center.id,
        dose: patient.currentDose,
      );
      if (success) {
        setState(() {
          _activePatient = null;
        });
        CustomToast.show(
          context,
          title: 'Subsidy Dispensation Approved',
          message: 'Mounjaro ${patient.currentDose} dispensed under 100% Emirati subsidy for ${patient.getLocalizedFullName(context)}.',
          icon: LucideIcons.award,
          color: AppColors.success,
        );

      }
    }
  }

  void _showManualOverrideDialog(
    BuildContext context,
    Patient patient,
    DispensingCenter center,
    DataProvider provider,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Override Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A safety alert warns that this patient is receiving duplicate medication. Overriding requires entering clinical justification.',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Clinical Reason for Override',
                hintText: 'e.g., Replacement for damaged pen/Lost dose...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                final success = provider.dispenseMedication(
                  patientId: patient.id,
                  centerId: center.id,
                  dose: patient.currentDose,
                  isOverride: true,
                );
                if (success) {
                  setState(() {
                    _activePatient = null;
                  });
                  CustomToast.show(
                    context,
                    title: 'Override Dispensation Logged',
                    message: 'Dispensed successfully under clinical override: ${reasonController.text}',
                    icon: LucideIcons.shieldAlert,
                    color: AppColors.error,
                  );

                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Approve & Dispense'),
          ),
        ],
      ),
    );
  }
}
