import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/platform_state_view.dart';
import '../../core/utils/responsive_layout.dart';
import '../patient_app/patient_app_screen.dart';
import '../patient_app/patient_notifications_sheet.dart';
import '../treatment_plan/mobile/plan_overview_screen.dart';
import '../treatment_plan/web/web_plan_medication_view.dart';
import '../treatment_plan/mobile/plan_sessions_screen.dart';
import '../treatment_plan/mobile/plan_exercises_screen.dart';
import 'web/web_patient_shell.dart';
import '../../../core/constants/mock_data.dart';
import '../../core/demo/demo_session_provider.dart';
import '../auth/login_screen.dart';

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
  int _currentIndex = 0; // 0 = Home, 1 = Profile, 2..5 = Plan

  Future<void> _showMore(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.calendarDays),
                title: Text(context.tr('nav_sessions')),
                onTap: () => Navigator.pop(sheetContext, 4),
              ),
              ListTile(
                leading: const Icon(LucideIcons.activity),
                title: Text(context.tr('nav_exercises')),
                onTap: () => Navigator.pop(sheetContext, 5),
              ),
              ListTile(
                leading: const Icon(LucideIcons.userCircle),
                title: Text(context.tr('my_health_profile_title')),
                onTap: () => Navigator.pop(sheetContext, 1),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _currentIndex = selected);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final patientId = context.watch<DemoSessionProvider>().patientId;
    final patient = provider.getPatientById(patientId);
    if (patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.isArabic ? 'ملف المريض' : 'Patient profile'),
        ),
        body: PlatformStateView(
          kind: PlatformStateKind.error,
          title: context.isArabic
              ? 'ملف المريض غير متاح'
              : 'Patient record unavailable',
          message: context.isArabic
              ? 'ارجع إلى اختيار الحساب ثم حاول مرة أخرى.'
              : 'Return to access selection and choose a patient account.',
          actionLabel: context.isArabic ? 'اختيار الحساب' : 'Choose account',
          onAction: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      );
    }
    final localeProvider = Provider.of<LocaleProvider>(context);

    final List<Widget> pages = [
      const PatientAppScreen(),
      MobilePatientProfileTab(patient: patient),
      PlanOverviewScreen(patient: patient),
      WebPlanMedicationView(patient: patient),
      PlanSessionsScreen(patient: patient),
      PlanExercisesScreen(patient: patient),
    ];

    final List<String> titles = [
      context.tr('home_dashboard'),
      context.tr('my_health_profile_title'),
      context.tr('nav_overview_plan'),
      context.tr('nav_medication'),
      context.tr('nav_sessions'),
      context.tr('nav_exercises'),
    ];

    // Badge Logic: Mock pending tasks
    final plan = provider.getPlanForPatient(patient.id);
    bool hasMedicationPending =
        plan != null && provider.medicationEventsFor(patient.id).isEmpty;
    bool hasExercisesPending =
        plan != null &&
        plan.homeExercises.any((exercise) => exercise.completedDates.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_currentIndex],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            tooltip: context.isArabic ? 'الإشعارات' : 'Notifications',
            onPressed: () => PatientNotificationsSheet.show(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: AppColors.navy,
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 20,
                  20,
                  20,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('ncc_brand'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            context.tr('patient_portal_title'),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  children: [
                    _navSection(context.tr('nav_overview')),
                    _buildDrawerItem(
                      LucideIcons.home,
                      context.tr('home_dashboard'),
                      0,
                    ),
                    _buildDrawerItem(
                      LucideIcons.userCircle,
                      context.tr('my_health_profile_title'),
                      1,
                    ),
                    const SizedBox(height: 16),
                    _navSection(context.tr('my_plan')),
                    _buildDrawerItem(
                      LucideIcons.clipboardList,
                      context.tr('nav_overview_plan'),
                      2,
                    ),
                    _buildDrawerItem(
                      LucideIcons.pill,
                      context.tr('nav_medication'),
                      3,
                      badgeCount: hasMedicationPending ? 1 : 0,
                    ),
                    _buildDrawerItem(
                      LucideIcons.clock,
                      context.tr('nav_sessions'),
                      4,
                    ),
                    _buildDrawerItem(
                      LucideIcons.activity,
                      context.tr('nav_exercises'),
                      5,
                      showDot: hasExercisesPending,
                    ),

                    const SizedBox(height: 32),
                    Divider(color: AppColors.surface24),
                    ListTile(
                      leading: const Icon(
                        LucideIcons.globe,
                        color: Colors.white,
                      ),
                      title: Text(
                        localeProvider.locale.languageCode == 'en'
                            ? context.tr('arabic')
                            : context.tr('english'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        localeProvider.toggleLanguage();
                        Navigator.pop(context); // Close drawer
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        LucideIcons.logOut,
                        color: Colors.white54,
                      ),
                      title: Text(
                        context.tr('logout'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // User Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          patient
                              .getLocalizedFullName(context)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.getLocalizedFullName(context).split(' ')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            context.tr('beneficiary_role'),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_currentIndex) {
          0 => 0,
          2 => 1,
          3 => 2,
          _ => 3,
        },
        onDestinationSelected: (index) {
          if (index == 3) {
            _showMore(context);
          } else {
            setState(() => _currentIndex = [0, 2, 3][index]);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.house),
            label: context.isArabic ? 'الرئيسية' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.clipboardList),
            label: context.isArabic ? 'الخطة' : 'Plan',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.pill),
            label: context.isArabic ? 'الدواء' : 'Medication',
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.menu),
            label: context.isArabic ? 'المزيد' : 'More',
          ),
        ],
      ),
    );
  }

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    int index, {
    int badgeCount = 0,
    bool showDot = false,
  }) {
    bool isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (showDot)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        Navigator.pop(context); // close drawer
      },
    );
  }
}

class MobilePatientProfileTab extends StatelessWidget {
  final Patient patient;
  const MobilePatientProfileTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final estimate = context.watch<DataProvider>().coverageEstimateForPatient(
      patient.id,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('my_health_profile'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('my_health_profile_sub'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Demographics Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        patient
                            .getLocalizedFullName(context)
                            .substring(0, 2)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('demographics'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            patient.getLocalizedFullName(context),
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRow(
                  context,
                  context.tr('full_name'),
                  patient.getLocalizedFullName(context),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  context,
                  context.tr('emirates_id'),
                  patient.emiratesId,
                ),
                const SizedBox(height: 12),
                _buildRow(
                  context,
                  context.tr('nationality'),
                  patient.getLocalizedNationality(context),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  context,
                  context.tr('residency_status'),
                  _residencyLabel(context, patient.residencyStatus),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  context,
                  context.tr('region'),
                  patient.getLocalizedEmirate(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Coverage is shown only when a plan exists and the shared provider
          // can derive an estimate for this patient.
          if (estimate != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('gov_subsidy_details'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRow(
                    context,
                    context.tr('base_medication_price'),
                    '${estimate.totalAed.toStringAsFixed(2)} AED',
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    context,
                    context.tr('coverage_rate'),
                    '${(estimate.totalAed == 0 ? 0 : (estimate.coveredAed / estimate.totalAed * 100)).toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    context,
                    context.tr('govt_contribution'),
                    '${estimate.coveredAed.toStringAsFixed(2)} AED',
                    color: AppColors.success,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                  _buildRow(
                    context,
                    context.tr('your_copay_per_checkin'),
                    '${estimate.copayAed.toStringAsFixed(2)} AED',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _residencyLabel(BuildContext context, ResidencyStatus status) {
    switch (status) {
      case ResidencyStatus.citizen:
        return context.tr('emirati');
      case ResidencyStatus.resident:
        return context.tr('resident');
      case ResidencyStatus.visitor:
        return context.tr('visitor');
    }
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: isHighlight ? 16 : 14,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
