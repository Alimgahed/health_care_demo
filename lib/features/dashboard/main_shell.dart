import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/localization/l10n_extension.dart';
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
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.layoutDashboard),
            label: context.tr('main_nav_dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.users),
            label: context.tr('main_nav_patients'),
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.pill),
            label: context.tr('main_nav_dispensing'),
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.smartphone),
            label: context.tr('main_nav_patient_app'),
          ),
        ],
      ),
    );
  }
}
