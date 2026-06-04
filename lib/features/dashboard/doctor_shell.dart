import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../patients/patient_list_screen.dart';
import 'web/web_doctor_shell.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/models/activity_log.dart';
import 'program_alerts.dart';

class DoctorShell extends StatelessWidget {
  final String? initialPatientId;
  final int initialTabIndex;

  const DoctorShell({super.key, this.initialPatientId, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileDoctorShell(
        initialPatientId: initialPatientId,
        initialTabIndex: initialTabIndex,
      ),
      web: WebDoctorShell(
        initialPatientId: initialPatientId,
        initialTabIndex: initialTabIndex,
      ),
    );
  }
}

class MobileDoctorShell extends StatefulWidget {
  final String? initialPatientId;
  final int initialTabIndex;

  const MobileDoctorShell({super.key, this.initialPatientId, this.initialTabIndex = 0});

  @override
  State<MobileDoctorShell> createState() => _MobileDoctorShellState();
}

class _MobileDoctorShellState extends State<MobileDoctorShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, 1);
  }

  List<Widget> get _pages => [
        PatientListScreen(highlightPatientId: widget.initialPatientId),
        const MobileAssessmentsTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        pendingAuthorizationReviewCount(context.watch<DataProvider>());
    final assessmentsIcon = pendingCount > 0
        ? Badge(
            label: Text('$pendingCount'),
            backgroundColor: AppColors.warning,
            child: const Icon(LucideIcons.clipboardList),
          )
        : const Icon(LucideIcons.clipboardList);

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
            icon: const Icon(LucideIcons.users),
            label: context.tr('main_nav_patients'),
          ),
          NavigationDestination(
            icon: assessmentsIcon,
            label: context.tr('nav_assessments'),
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
    final logs = dataProvider.logs
        .where((l) =>
            l.eventType == ActivityEventType.doseChange ||
            l.eventType == ActivityEventType.weightUpdate)
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('assessments_log')),
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(context.tr('no_assessments')),
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
