import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../patients/patient_list_screen.dart';
import '../dispensing/dispensing_screen.dart';
import '../dashboard/ministry_dashboard_screen.dart';
import '../patient_app/patient_app_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MinistryDashboardScreen(),
    const PatientListScreen(),
    const DispensingScreen(),
    const PatientAppScreen(),
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
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.users),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.pill),
            label: 'Dispensing',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.smartphone),
            label: 'Patient App',
          ),
        ],
      ),
    );
  }
}
