import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mounjaro_demo/features/treatment_plan/models/treatment_plan.dart';
import 'package:provider/provider.dart';

import '../../patient_app/medication_order/medication_order_wizard.dart' as mounjaro_demo;
import '../../../core/constants/mock_data.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../../treatment_plan/web/web_plan_exercises_view.dart';
import '../../treatment_plan/web/web_plan_medication_view.dart';
import '../../treatment_plan/web/web_plan_overview_view.dart';
import '../../treatment_plan/web/web_plan_sessions_view.dart';

class WebPatientShell extends StatefulWidget {
  const WebPatientShell({super.key});

  @override
  State<WebPatientShell> createState() => _WebPatientShellState();
}

class _WebPatientShellState extends State<WebPatientShell>
    with TickerProviderStateMixin {
  int _selectedIndex = 0; // 0 = Home / Dashboard, 1 = My Profile
  final String _patientId =
      'P001'; // Mocked as Ahmed Al Mansoori for the patient app

  bool _injectionDone = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    // Fetch active patient from provider to keep it reactive
    final patient = dataProvider.patients.firstWhere(
      (p) => p.id == _patientId,
      orElse: () => dataProvider.patients.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(child: _buildSidebar(context, patient)),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopbar(context, localeProvider, dataProvider, patient),
                Expanded(
                  child: _getScreenForIndex(
                    _selectedIndex,
                    context,
                    patient,
                    dataProvider,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar(
    BuildContext context,
    LocaleProvider localeProvider,
    DataProvider dataProvider,
    Patient patient,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () {
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('patient_portal_title') ?? 'Patient Portal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                context.tr('welcome_back_name', {
                      'name': patient
                          .getLocalizedFullName(context)
                          .split(' ')[0],
                    }) ??
                    'Welcome back, ${patient.getLocalizedFullName(context).split(' ')[0]}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: localeProvider.toggleLanguage,
            icon: Icon(
              LucideIcons.globe,
              size: 14,
              color: AppColors.textPrimary,
            ),
            label: Text(
              localeProvider.locale.languageCode == 'en'
                  ? (context.tr('arabic') ?? 'Arabic')
                  : (context.tr('english') ?? 'English'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LucideIcons.logOut,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: IconButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, Patient patient) {
    return Container(
      width: 240,
      color: AppColors.navy,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ncc_brand') ?? 'NCC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        context.tr('patient_portal_title') ?? 'Patient Portal',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navSection(context.tr('nav_overview') ?? 'Overview'),
                  _buildSidebarItem(
                    LucideIcons.home,
                    context.tr('home_dashboard') ?? 'Dashboard',
                    0,
                  ),
                  _buildSidebarItem(
                    LucideIcons.userCircle,
                    context.tr('my_health_profile_title') ?? 'My Profile',
                    1,
                  ),
                  _navSection(context.tr('my_plan') ?? 'My Plan'),
                  _buildSidebarItem(
                    LucideIcons.clipboardList,
                    context.tr('nav_overview_plan') ?? 'Overview',
                    2,
                  ),
                  _buildSidebarItem(
                    LucideIcons.pill,
                    context.tr('nav_medication') ?? 'Medication',
                    3,
                  ),
                  _buildSidebarItem(
                    LucideIcons.clock,
                    context.tr('nav_sessions') ?? 'Sessions',
                    4,
                  ),
                  _buildSidebarItem(
                    LucideIcons.activity,
                    context.tr('nav_exercises') ?? 'Exercises',
                    5,
                  ),
                ],
              ),
            ),
          ),
          // User
          Container(
            padding: const EdgeInsets.all(16),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      patient
                          .getLocalizedFullName(context)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.getLocalizedFullName(context).split(' ')[0],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.tr('beneficiary_role') ?? 'Patient',
                        style: TextStyle(
                          color: AppColors.surface54,
                          fontSize: 11,
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
    );
  }

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getScreenForIndex(
    int index,
    BuildContext context,
    Patient patient,
    DataProvider provider,
  ) {
    switch (index) {
      case 0:
        return _buildDashboardView(context, patient, provider);
      case 1:
        return WebPatientProfileOverview(patient: patient);
      case 2:
        return WebPlanOverviewView(patient: patient);
      case 3:
        return WebPlanMedicationView(patient: patient);
      case 4:
        return WebPlanSessionsView(patient: patient);
      case 5:
        return WebPlanExercisesView(patient: patient);
      default:
        return _buildDashboardView(context, patient, provider);
    }
  }

  Widget _buildDashboardView(
    BuildContext context,
    Patient patient,
    DataProvider provider,
  ) {
    final plan = provider.getPlanForPatient(patient.id);
    final double weightLost = patient.weightHistory.isNotEmpty
        ? patient.weightHistory.first - patient.weight
        : 0;
    final double targetWeight = plan?.targetWeight ?? 85.0;
    final double rawProgress = patient.weightHistory.isNotEmpty
        ? ((patient.weightHistory.first - patient.weight) /
              (patient.weightHistory.first - targetWeight))
        : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final int sessionsAttended =
        plan?.sessions.where((s) => s.isAttended).length ?? 0;
    final int totalSessions = plan?.totalSessions ?? 0;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '🌅 ' + context.tr('good_morning_comma')
        : hour < 17
        ? '☀️ ' + context.tr('good_afternoon_comma')
        : '🌙 ' + context.tr('good_evening_comma');

    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Greeting header + Summary KPIs ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      patient.getLocalizedFullName(context).split(' ')[0],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildKpiChip(
                    LucideIcons.trendingDown,
                    '${weightLost.toStringAsFixed(1)} kg Lost',
                    AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    LucideIcons.activity,
                    'BMI ${patient.bmi.toStringAsFixed(1)}',
                    patient.bmi >= 30 ? AppColors.warning : AppColors.info,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    LucideIcons.shieldCheck,
                    '${(patient.complianceRate * 100).toStringAsFixed(0)}% Adherence',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    LucideIcons.syringe,
                    'Next Dose: 4 Days',
                    AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Direct Medication Request ─────────────────────────────────
          _buildMedicationAction(context),
          const SizedBox(height: 32),

          // ── Row 2: Injection hero card (left) + 3 stat bubbles (right) ────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Injection hero card
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    image: const DecorationImage(
                      image: AssetImage('assets/illustrations/dashboard_hero.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black45, // Darken for text readability
                        BlendMode.darken,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -10,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.syringe,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        context.tr('prescribed_dose_line', {
                                              'dose': patient.currentDose,
                                            }) ??
                                            'Prescribed dose: ${patient.currentDose}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    context.tr('in_4_days'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width:
                                              60 + (_pulseAnimation.value * 10),
                                          height:
                                              60 + (_pulseAnimation.value * 10),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha:
                                                  0.06 *
                                                  (1 - _pulseAnimation.value),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          child: Icon(
                                            LucideIcons.syringe,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('next_injection_reminder') ??
                                            'Next Injection Reminder',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.tr('dont_forget_weekly_injection'),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: List.generate(7, (i) {
                                final isToday = i == 1;
                                final isPast = i == 0;
                                final isNext = i == 6;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isPast
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : (isToday
                                                      ? AppColors.accent
                                                      : (isNext
                                                            ? AppColors.accent
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  )
                                                            : Colors.white
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ))),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          [
                                            'M',
                                            'T',
                                            'W',
                                            'T',
                                            'F',
                                            'S',
                                            'S',
                                          ][i],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isToday
                                                ? AppColors.accent
                                                : Colors.white60,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _injectionDone = !_injectionDone;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _injectionDone
                                            ? 'Injection recorded successfully.'
                                            : 'Injection unmarked.',
                                      ),
                                      backgroundColor: _injectionDone
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  );
                                },
                                icon: Icon(
                                  _injectionDone
                                      ? LucideIcons.checkCircle
                                      : LucideIcons.check,
                                  size: 18,
                                ),
                                label: Text(
                                  _injectionDone
                                      ? context.tr('dashboard_injection_taken_btn')
                                      : context.tr('dashboard_take_injection_btn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _injectionDone
                                      ? AppColors.success
                                      : Colors.white,
                                  foregroundColor: _injectionDone
                                      ? Colors.white
                                      : AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right: 3 stat bubbles stacked vertically
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildWebStatBubble(
                      context,
                      icon: LucideIcons.trendingDown,
                      value: '${weightLost.toStringAsFixed(1)} kg',
                      label: context.tr('weight_loss'),
                      color: AppColors.success,
                      shadow: shadow,
                    ),
                    const SizedBox(height: 16),
                    _buildWebStatBubble(
                      context,
                      icon: LucideIcons.activity,
                      value: patient.bmi.toStringAsFixed(1),
                      label: 'BMI',
                      color: patient.bmi >= 30
                          ? AppColors.warning
                          : AppColors.info,
                      shadow: shadow,
                    ),
                    const SizedBox(height: 16),
                    _buildWebStatBubble(
                      context,
                      icon: LucideIcons.calendar,
                      value: '$sessionsAttended/$totalSessions',
                      label: context.tr('completed_sessions'),
                      color: AppColors.primary,
                      shadow: shadow,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Row 3: Goal Progress Card (full width) ────────────────────────
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [shadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('dashboard_weight_progress_title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'الهدف: $targetWeight kg  •  الحالي: ${patient.weight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 0.8
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: progress >= 0.8
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 0.8 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% مكتمل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: progress >= 0.8
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    Text(
                      'متبقي ${(patient.weight - targetWeight).toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Row 3.5: Weight Journey Horizontal Bar ────────────────────────
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [shadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('dashboard_weight_journey_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.trendingDown,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '↓ ${weightLost.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${patient.weightHistory.first.toStringAsFixed(0)}kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            height: 6,
                            alignment: Alignment.centerLeft,
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, _) => FractionallySizedBox(
                                widthFactor:
                                    progress * _progressAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '${patient.weight.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${targetWeight.toStringAsFixed(0)}kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'Target',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.activity,
                              size: 20,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:  [
                                  Text(
                                    'Improving',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  Text(
                                    'BMI Progress',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendarClock,
                              size: 20,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:  [
                                  Text(
                                    '8 weeks',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  Text(
                                    'Est. Completion',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Row 4: Weight Journey Chart (left) + Today's Routine (right) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Weight Journey LineChart
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [shadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('weight_loss_journey') ??
                            'Weight Loss Journey',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('weight_journey_sub') ??
                            'Your progress over time',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 240,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.border.withValues(alpha: 0.5),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 &&
                                        idx < patient.weightHistory.length) {
                                      return Text(
                                        context.tr('check_reading', {
                                              'n': '${idx + 1}',
                                            }) ??
                                            'Check ${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: patient.weightHistory
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(e.key.toDouble(), e.value),
                                    )
                                    .toList(),
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 3,
                                shadow: Shadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                ),
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) =>
                                      FlDotCirclePainter(
                                        radius: 4,
                                        color: AppColors.surface,
                                        strokeWidth: 2,
                                        strokeColor: AppColors.primary,
                                      ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right: Today's Routine card
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [shadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('dashboard_todays_routine'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (plan != null && plan.homeExercises.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${plan.homeExercises.length} تمارين',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (plan == null || plan.homeExercises.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child:  Row(
                            children: [
                              Icon(
                                LucideIcons.checkCircle,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 12),
                              Text(
                                context.tr('no_exercises_scheduled_today'),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...plan.homeExercises
                            .take(3)
                            .map(
                              (e) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.04,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        LucideIcons.activity,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${e.durationMinutes} دقيقة • ${e.sets} مجموعات',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${e.durationMinutes} د',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      if (plan != null)
                        _buildWebUpcomingSessionBanner(context, plan),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Row 5: Achievements — 3 equal-width badge cards ───────────────
          Text(
            context.tr('earned_badges_title') ?? 'Earned Badges',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBadgeCard(
                context,
                LucideIcons.medal,
                context.tr('badge_month_streak') ?? 'Monthly Streak',
                context.tr('badge_month_streak_sub') ?? '1 month streak',
                AppColors.accent,
                shadow,
              ),
              const SizedBox(width: 24),
              _buildBadgeCard(
                context,
                LucideIcons.flame,
                context.tr('badge_weight_reduction') ?? 'Weight Reduction',
                context.tr('badge_weight_reduction_sub') ?? 'Lost 5kg',
                AppColors.error,
                shadow,
              ),
              const SizedBox(width: 24),
              _buildBadgeCard(
                context,
                LucideIcons.award,
                context.tr('badge_clinical_compliance') ??
                    'Clinical Compliance',
                context.tr('badge_clinical_compliance_sub') ?? '100% compliant',
                AppColors.primary,
                shadow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Direct Medication Request Action (Web) ───────────────────────────────────
  Widget _buildMedicationAction(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const mounjaro_demo.MedicationOrderWizard(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 24),
             Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('dashboard_request_med_now'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.tr('check_eligibility_and_request'),
                    style: TextStyle(
                      color: AppColors.surface70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }


  Widget _buildKpiChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatBubble(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required BoxShadow shadow,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [shadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebUpcomingSessionBanner(
    BuildContext context,
    TreatmentPlan plan,
  ) {
    final upcoming = plan.sessions.firstWhere(
      (s) => !s.isAttended,
      orElse: () => plan.sessions.last,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy.withValues(alpha: 0.9), AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.calendar,
              color: Colors.white,
              size: 20,
            ),
          ),
           SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('dashboard_upcoming_session')}:${upcoming.sessionNumber}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${upcoming.scheduledDate.day}/${upcoming.scheduledDate.month}/${upcoming.scheduledDate.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    BoxShadow shadow,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [shadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
    );
  }
}

// Assuming these exist in your data layer models

class WebPatientProfileOverview extends StatefulWidget {
  final Patient patient;

  const WebPatientProfileOverview({super.key, required this.patient});

  @override
  State<WebPatientProfileOverview> createState() =>
      _WebPatientProfileOverviewState();
}

class _WebPatientProfileOverviewState extends State<WebPatientProfileOverview> {
  bool _isIdObscured = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    // Financial Subsidy Computations
    final double coverage =
        widget.patient.residencyStatus == ResidencyStatus.citizen
        ? 1.0
        : (widget.patient.residencyStatus == ResidencyStatus.resident
              ? 0.5
              : 0.0);
    final double govtPays = 1000.0 * coverage;
    final double copay = 1000.0 - govtPays;

    String formatEmiratesId(String id) {
      if (!_isIdObscured || id.length < 15) return id;
      return '${id.substring(0, 3)}-****-*******-${id.substring(14)}';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Premium Platform Profile Header Block
          _buildProfileHeader(context, isDark),
          const SizedBox(height: 36),

          // 2. High-Density Web Layout Framework (3-Column Architecture Matrix)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Left: Verified Demographic Dossier (Flex: 4)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.userCheck,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                context.tr('demographics') ??
                                    context.tr('demographics'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.2),
                              ),
                            ),
                            child:  Row(
                              children: [
                                Icon(
                                  LucideIcons.shieldCheck,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  context.tr('verified_digital'),
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      _buildPremiumRow(
                        context,
                        context.tr('full_name'),
                        widget.patient.getLocalizedFullName(context),
                      ),
                      _buildPremiumRow(
                        context,
                        context.tr('nationality'),
                        widget.patient.getLocalizedNationality(context),
                      ),
                      _buildPremiumRow(
                        context,
                        context.tr('residency_status'),
                        widget.patient.getLocalizedResidency(context),
                      ),
                      _buildPremiumRow(
                        context,
                        context.tr('region'),
                        widget.patient.getLocalizedEmirate(context),
                      ),

                      // Obscure-controlled Emirates ID Field Block
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('emirates_id') ??
                                  context.tr('emirates_id'),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  formatEmiratesId(widget.patient.emiratesId),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () => setState(
                                    () => _isIdObscured = !_isIdObscured,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _isIdObscured
                                          ? LucideIcons.eyeOff
                                          : LucideIcons.eye,
                                      size: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),

              // Column Right: Financial Calculator & Allocation Matrix (Flex: 3)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.wallet,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            context.tr('gov_subsidy_details') ??
                                context.tr('gov_subsidy_details'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      _buildPremiumRow(
                        context,
                        context.tr('base_medication_price') ??
                            context.tr('base_medication_price'),
                        '1,000.00 AED',
                      ),

                      // Progress visualization context of insurance coverage
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('coverage_rate') ??
                                      context.tr('coverage_rate'),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${(coverage * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: coverage,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.background,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPremiumRow(
                        context,
                        context.tr('govt_contribution') ??
                            context.tr('govt_contribution'),
                        '${govtPays.toStringAsFixed(2)} AED',
                        color: AppColors.success,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('your_copay_per_checkin') ??
                                      context.tr('your_copay_per_checkin'),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('payable_at_checkin'),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${copay.toStringAsFixed(2)} AED',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 3. New Bottom Row: Advanced Integrated Clinical Diagnostics Logs
          _buildIntegratedDiagnosticsTray(context, surfaceColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                LucideIcons.heart,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('my_health_profile') ??
                      context.tr('my_health_profile'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('health_profile_desc'),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedDiagnosticsTray(
    BuildContext context,
    Color bg,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(
                LucideIcons.activity,
                color: AppColors.primaryLight,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                context.tr('clinical_data_desc'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _diagnosticSummaryBlock(
                context.tr('wizard_bmi_req'),
                context.tr('wizard_bmi_current').replaceAll('{bmi}', '27.4'),
                context.tr('slight_overweight_stable'),
                LucideIcons.scale,
                AppColors.info,
              ),
              const SizedBox(width: 20),
              _diagnosticSummaryBlock(
                context.tr('active_dose'),
                '5 mg / ' + context.tr('frequency_weekly'),
                'Mounjaro • ' + context.tr('eligible_mounjaro'),
                LucideIcons.droplet,
                AppColors.primaryLight,
              ),
              const SizedBox(width: 20),
              _diagnosticSummaryBlock(
                context.tr('last_vital_scan'),
                context.tr('last_dispense_date') + ': ' + context.tr('every_n_days').replaceAll('{n}', '14'),
                'HbA1c: 5.8% • ' + context.tr('dashboard_improving'),
                LucideIcons.clipboardCheck,
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diagnosticSummaryBlock(
    String title,
    String value,
    String sub,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}