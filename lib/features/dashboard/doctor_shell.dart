import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../patients/patient_list_screen.dart';
import 'web/web_doctor_shell.dart';
import '../../../core/constants/mock_data.dart';

class DoctorShell extends StatelessWidget {
  const DoctorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileDoctorShell(),
      web: WebDoctorShell(),
    );
  }
}

class MobileDoctorShell extends StatefulWidget {
  const MobileDoctorShell({super.key});

  @override
  State<MobileDoctorShell> createState() => _MobileDoctorShellState();
}

class _MobileDoctorShellState extends State<MobileDoctorShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PatientListScreen(),
    const MobileAssessmentsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.users),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.clipboardList),
            label: 'Assessments',
          ),
        ],
      ),
    );
  }
}

class MobileAssessmentsTab extends StatelessWidget {
  const MobileAssessmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final logs = dataProvider.logs.where((l) => l.action.contains('escalated') || l.action.contains('Weight')).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessments Log'),
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text('No assessments recorded yet'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.clipboardList, color: AppColors.primary),
                  title: Text(log.getLocalizedPatientName(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(log.getLocalizedAction(context)),
                  trailing: Text(
                    '${log.timestamp.day}/${log.timestamp.month}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
