import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../patient_app/patient_app_screen.dart';
import 'web/web_patient_shell.dart';
import '../../../core/constants/mock_data.dart';

class PatientShell extends StatelessWidget {
  const PatientShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobilePatientShell(),
      web: WebPatientShell(),
    );
  }
}

class MobilePatientShell extends StatefulWidget {
  const MobilePatientShell({super.key});

  @override
  State<MobilePatientShell> createState() => _MobilePatientShellState();
}

class _MobilePatientShellState extends State<MobilePatientShell> {
  int _currentIndex = 0;
  final String _patientId = 'P001'; // Mocked as Ahmed Al Mansoori

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final patient = provider.patients.firstWhere((p) => p.id == _patientId, orElse: () => provider.patients.first);

    final List<Widget> pages = [
      const PatientAppScreen(),
      MobilePatientProfileTab(patient: patient),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.userCircle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class MobilePatientProfileTab extends StatelessWidget {
  final Patient patient;
  const MobilePatientProfileTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final double coverage = patient.residencyStatus == ResidencyStatus.citizen ? 1.0 :
                            (patient.residencyStatus == ResidencyStatus.resident ? 0.5 : 0.0);
    final double govtPays = 1000.0 * coverage;
    final double copay = 1000.0 - govtPays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        patient.getLocalizedFullName(context).substring(0, 2).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(patient.getLocalizedFullName(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(patient.emiratesId, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subsidy Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _buildRow('Coverage Rate', '${(coverage * 100).toStringAsFixed(0)}%'),
                    _buildRow('Government Pays', '${govtPays.toStringAsFixed(0)} AED'),
                    _buildRow('Your Copay', '${copay.toStringAsFixed(0)} AED'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
