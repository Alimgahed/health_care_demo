import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/demo_metrics.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../admin_views/regional_analytics.dart';
import '../admin_views/system_audit_log_view.dart';
import '../program_alerts.dart';
import 'web_center_shell.dart';
import 'web_doctor_shell.dart';
import 'web_map_analytics_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MOUNJARO NCC — Optimized Admin Dashboard
//  Brand palette: Deep Forest Green #16533A · Gold #C7A252 · Navy #0A2B3E
// ─────────────────────────────────────────────────────────────────────────────

class WebAdminShell extends StatefulWidget {
  const WebAdminShell({super.key});

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _WebAdminShellState extends State<WebAdminShell> {
  int _selectedIndex = 0;
  int _lastSeenLogsCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dp = Provider.of<DataProvider>(context, listen: false);
        setState(() => _lastSeenLogsCount = dp.logs.length);
      }
    });
  }

  void _navigate(int index, int totalLogs) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      if (index == 11) {
        _lastSeenLogsCount = totalLogs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 1100;
        final sidebar = Consumer<DataProvider>(
          builder: (context, dp, _) {
            final totalLogs = dp.logs.length;
            final unreadLogs = _lastSeenLogsCount == -1
                ? 0
                : (totalLogs - _lastSeenLogsCount);
            return _Sidebar(
              selectedIndex: _selectedIndex,
              onNavigate: (index) {
                _navigate(index, totalLogs);
                if (!showSidebar) Navigator.of(context).maybePop();
              },
              t: t,
              localeProvider: localeProvider,
              alertBadgeCount: programAlertBadgeCount(context, dp),
              readyDispenseCount: dp.countPatientsReadyToDispense(),
              pendingAuthCount: pendingAuthorizationReviewCount(dp),
              unreadAuditLogsCount: unreadLogs,
            );
          },
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: showSidebar ? null : Drawer(child: sidebar),
          body: Row(
            children: [
              if (showSidebar) sidebar,
              Expanded(
                child: Column(
                  children: [
                    _Topbar(
                      t: t,
                      localeProvider: localeProvider,
                      showMenuButton: !showSidebar,
                      onLogout: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    ),
                    Expanded(child: _buildBody(t)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations t) {
    switch (_selectedIndex) {
      case 0:
        return _OverviewDashboard(t: t);
      case 1:
        return const WebMapAnalyticsScreen();
      case 2:
        return _PatientsView(t: t);
      case 3:
        return InventoryView();
      case 4:
        return _AiAlertsFullView(t: t);
      case 5:
        return _FraudAuditView(t: t);
      case 6:
        return const RegionalAnalytics();
      case 7:
        return const WebDoctorShell(embeddedInAdmin: true);
      case 8:
        return const WebCenterShell(embeddedInAdmin: true);
      case 9:
        return _ManageDoctorsView(t: t);
      case 10:
        return _ManageCentersView(t: t);
      case 11:
        return SystemAuditLogView(t: t);
      default:
        return _OverviewDashboard(t: t);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final AppLocalizations t;
  final LocaleProvider localeProvider;
  final int alertBadgeCount;
  final int readyDispenseCount;
  final int pendingAuthCount;
  final int unreadAuditLogsCount;

  const _Sidebar({
    required this.selectedIndex,
    required this.onNavigate,
    required this.t,
    required this.localeProvider,
    required this.alertBadgeCount,
    required this.readyDispenseCount,
    required this.pendingAuthCount,
    required this.unreadAuditLogsCount,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.white.withOpacity(0.08),
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
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
                        context.tr('ncc_brand'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        context.tr('ncc_subtitle'),
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

          // Nav
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navSection(context.tr('nav_section_overview')),
                  _navItem(
                    LucideIcons.layoutDashboard,
                    context.tr('nav_dashboard'),
                    0,
                  ),
                  _navSection(context.tr('nav_section_analytics')),
                  _navItem(LucideIcons.map, context.tr('nav_geo_analytics'), 1),
                  _navItem(LucideIcons.users, context.tr('nav_patients'), 2),
                  _navItem(LucideIcons.package, context.tr('nav_inventory'), 3),
                  _navSection(context.tr('nav_section_intelligence')),
                  _navItem(
                    LucideIcons.bot,
                    context.tr('nav_ai_alerts'),
                    4,
                    badge: alertBadgeCount > 0 ? '$alertBadgeCount' : null,
                    badgeDanger: alertBadgeCount > 0,
                  ),
                  _navItem(
                    LucideIcons.shieldAlert,
                    context.tr('nav_fraud_log'),
                    5,
                  ),
                  _navItem(LucideIcons.fileText, context.tr('nav_reports'), 6),
                  _navSection(context.tr('nav_section_operations')),
                  _navItem(
                    LucideIcons.stethoscope,
                    context.tr('nav_clinical_ops'),
                    7,
                    badge: pendingAuthCount > 0 ? '$pendingAuthCount' : null,
                  ),
                  _navItem(
                    LucideIcons.pill,
                    context.tr('nav_dispensing_ops'),
                    8,
                    badge: readyDispenseCount > 0
                        ? '$readyDispenseCount'
                        : null,
                  ),
                  _navSection(context.tr('nav_section_administration')),
                  _navItem(
                    LucideIcons.stethoscope,
                    context.tr('nav_manage_doctors'),
                    9,
                  ),
                  _navItem(
                    LucideIcons.building,
                    context.tr('nav_manage_centers'),
                    10,
                  ),
                  _navItem(
                    LucideIcons.activitySquare,
                    t.translate('system_audit_log') ?? 'سجل النظام',
                    11,
                    badge: unreadAuditLogsCount > 0
                        ? '$unreadAuditLogsCount'
                        : null,
                    badgeDanger: unreadAuditLogsCount > 0,
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
                  color: Colors.white.withOpacity(0.08),
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
                  child: const Center(
                    child: Text(
                      'ME',
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
                        context.tr('ministry_executive_user'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'admin@moh.gov.ae',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.logOut, color: Colors.white38, size: 16),
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
          color: Colors.white.withOpacity(0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    String? badge,
    bool badgeDanger = false,
  }) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onNavigate(index),
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
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeDanger ? AppColors.error : AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeDanger ? Colors.white : AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _Topbar extends StatelessWidget {
  final AppLocalizations t;
  final LocaleProvider localeProvider;
  final bool showMenuButton;
  final VoidCallback onLogout;

  const _Topbar({
    required this.t,
    required this.localeProvider,
    required this.showMenuButton,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.navy),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          if (showMenuButton) const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('national_command_center'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              Text(
                '${context.tr('last_synced')}: ${context.tr('today')}, ${_syncTime()} GST',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Lang toggle
          _topBtn(
            icon: LucideIcons.globe,
            label: localeProvider.locale.languageCode == 'en'
                ? context.tr('arabic')
                : context.tr('english'),
            onTap: localeProvider.toggleLanguage,
          ),
          const SizedBox(width: 8),
          // Notifications
          _iconBtn(LucideIcons.bell, hasAlert: true, onTap: () {}),
          const SizedBox(width: 8),
          // Export
          _primaryBtn(
            context.tr('export_report'),
            LucideIcons.download,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Logout
          _iconBtn(LucideIcons.logOut, onTap: onLogout),
        ],
      ),
    );
  }

  Widget _topBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: AppColors.navy),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    bool hasAlert = false,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, size: 18, color: AppColors.textSecondary),
          onPressed: onTap,
          style: IconButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (hasAlert)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  static String _syncTime() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Widget _primaryBtn(
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERVIEW DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewDashboard extends StatelessWidget {
  final AppLocalizations t;

  const _OverviewDashboard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        final tr = context.tr;
        final avgBmi = dp.averageBmi;
        final fraudPrevented = dp.fraudIncidentsPrevented;
        final adherence = DemoMetrics.formatPercent(dp.averageCompliance);
        final bmiDrop = dp.nationalAverageBmiDrop;
        final obesityReduction = dp.obesityIndexReductionPercent;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AI Cost & ROI Index ───────────────────────────────────────
              _buildAiRoiBanner(context),
              const SizedBox(height: 24),

              // ── KPI Row ─────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.users,
                      value: DemoMetrics.formatCount(
                        DemoMetrics.nationalEnrolled,
                      ),
                      label: tr('registered_patients_national'),
                      trend: '${tr('demo_cohort')}: ${dp.totalActivePatients}',
                      trendUp: null,
                      accentColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.wallet,
                      value: _fmtSubsidy(dp.totalGovtSubsidyDisbursed),
                      label: tr('govt_subsidy_expenditure'),
                      trend: tr('q2_budget'),
                      trendUp: null,
                      accentColor: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.activity,
                      value: avgBmi.toStringAsFixed(1),
                      label: tr('national_avg_bmi_cohort'),
                      trend:
                          '↓ ${bmiDrop.toStringAsFixed(1)} ${tr('vs_baseline_2023')}',
                      trendUp: true,
                      accentColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.shieldAlert,
                      value: fraudPrevented.toString(),
                      label: tr('fraud_abuse_prevented'),
                      trend: tr('cases_blocked'),
                      trendUp: true,
                      accentColor: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Extra KPI Row (new) ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.clipboard,
                      value: adherence,
                      label: tr('adherence_rate'),
                      trend: tr('cohort_average'),
                      trendUp: true,
                      accentColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.building2,
                      value: dp.centers.length.toString(),
                      label: tr('active_dispensing_centers'),
                      trend: tr('all_regions'),
                      trendUp: null,
                      accentColor: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.package,
                      value: _totalStock(dp),
                      label: tr('total_stock_units'),
                      trend: _stockStatus(context, dp),
                      trendUp: _stockOk(dp),
                      accentColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _KpiCard(
                      icon: LucideIcons.trendingUp,
                      value: '${obesityReduction.toStringAsFixed(0)}%',
                      label: tr('obesity_index_reduction'),
                      trend: tr('vs_baseline_2023'),
                      trendUp: true,
                      accentColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Main Charts Row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left 2/3
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _ChartCard(
                          title: tr('obesity_index_title'),
                          subtitle: tr('monthly_bmi_sub'),
                          pill: tr('on_track'),
                          pillColor: AppColors.success,
                          height: 300,
                          child: const _ObesityLineChart(),
                        ),
                        const SizedBox(height: 20),
                        _ChartCard(
                          title: tr('dispensing_vs_goals'),
                          subtitle:
                              '${tr('actual_dispensed')} vs ${tr('ministry_target')}',
                          height: 280,
                          child: _ConsumptionBarChart(t: t, dp: dp),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _AiAlertsPanel(t: t, dp: dp),
                        const SizedBox(height: 20),
                        _ChartCard(
                          title: tr('demographics_title'),
                          subtitle: '${tr('citizens')} vs ${tr('residents')}',
                          height: 280,
                          child: _DemographicsPieChart(t: t, dp: dp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ChartCard(
                      title: tr('adherence_by_dose'),
                      subtitle: tr('adherence_by_dose_sub'),
                      height: 280,
                      child: _AdherenceBarChart(dp: dp),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _ChartCard(
                      title: tr('center_inventory_status'),
                      subtitle: tr('center_inventory_sub'),
                      height: 280,
                      child: _CenterInventoryTable(dp: dp),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiRoiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navy.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.brainCircuit,
              color: AppColors.accent,
              size: 48,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('ai_roi_title'),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '45.2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('ai_roi_millions_aed'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.trendingUp,
                            color: AppColors.success,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('ai_roi_savings_label'),
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('ai_roi_description'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.tr('ai_roi_complication_reduction'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '22%',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(
                    value: 0.22,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: AppColors.success,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtSubsidy(double amt) => DemoMetrics.formatAed(amt);

  String _totalStock(DataProvider dp) {
    int total = 0;
    for (var c in dp.centers) {
      total += c.inventory2_5mg + c.inventory5mg;
    }
    return total.toString();
  }

  String _stockStatus(BuildContext context, DataProvider dp) {
    bool anyLow = dp.centers.any(
      (c) => c.inventory2_5mg <= 10 || c.inventory5mg <= 10,
    );
    return anyLow ? context.tr('low_stock_alert') : context.tr('levels_stable');
  }

  bool _stockOk(DataProvider dp) =>
      !dp.centers.any((c) => c.inventory2_5mg <= 10 || c.inventory5mg <= 10);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String trend;
  final bool? trendUp; // null = neutral
  final Color accentColor;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendUp,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Color trendBg, trendFg;
    if (trendUp == null) {
      trendBg = const Color(0xFFF3F4F6);
      trendFg = AppColors.textSecondary;
    } else if (trendUp!) {
      trendBg = const Color(0xFFD1FAE5);
      trendFg = const Color(0xFF065F46);
    } else {
      trendBg = const Color(0xFFFEE2E2);
      trendFg = const Color(0xFF991B1B);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trendFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? pill;
  final Color? pillColor;
  final double height;
  final Widget child;

  const _ChartCard({
    required this.title,
    this.subtitle,
    this.pill,
    this.pillColor,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (pill != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (pillColor ?? AppColors.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (pillColor ?? AppColors.success).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    pill!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pillColor ?? AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHARTS
// ─────────────────────────────────────────────────────────────────────────────

class _ObesityLineChart extends StatelessWidget {
  const _ObesityLineChart();

  @override
  Widget build(BuildContext context) {
    const bmiLevels = [33.5, 33.1, 32.7, 32.2, 31.8, 31.2, 30.8, 30.2, 29.8];
    const targetLine = [28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0];
    const months = [
      'Oct',
      'Nov',
      'Dec',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
    ];

    return RepaintBoundary(
      child: LineChart(
        duration: Duration.zero,
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border.withOpacity(0.6),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  int i = v.toInt();
                  if (i >= 0 && i < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        months[i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 1,
                getTitlesWidget: _leftTitle,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 8,
          minY: 26,
          maxY: 35,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                bmiLevels.length,
                (i) => FlSpot(i.toDouble(), bmiLevels[i]),
              ),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, __, ___, ____) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            LineChartBarData(
              spots: List.generate(
                targetLine.length,
                (i) => FlSpot(i.toDouble(), targetLine[i]),
              ),
              isCurved: false,
              color: AppColors.accent.withOpacity(0.7),
              barWidth: 1.5,
              isStrokeCapRound: false,
              dashArray: [5, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _leftTitle(double v, TitleMeta _) => Text(
  v.toStringAsFixed(0),
  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
);

class _ConsumptionBarChart extends StatelessWidget {
  final AppLocalizations t;
  final DataProvider dp;
  const _ConsumptionBarChart({required this.t, required this.dp});

  @override
  Widget build(BuildContext context) {
    final counts = [
      dp.patients.where((p) => p.currentDose == '2.5 mg').length.toDouble(),
      dp.patients.where((p) => p.currentDose == '5 mg').length.toDouble(),
      dp.patients.where((p) => p.currentDose == '7.5 mg').length.toDouble(),
      dp.patients.where((p) => p.currentDose == '10 mg').length.toDouble(),
    ];
    final targets = [30.0, 35.0, 25.0, 20.0];
    final labels = ['2.5 mg', '5 mg', '7.5 mg', '10 mg'];

    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: BarChart(
              duration: Duration.zero,
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 45,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          rod.toY.toInt().toString(),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _leftTitle,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        int i = v.toInt();
                        if (i >= 0 && i < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[i],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withOpacity(0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  4,
                  (i) => BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i],
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                      BarChartRodData(
                        toY: targets[i],
                        color: AppColors.accent.withOpacity(0.7),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(AppColors.primary, context.tr('active_patients_legend')),
            const SizedBox(width: 20),
            _Legend(AppColors.accent, context.tr('target_limit_legend')),
          ],
        ),
      ],
    );
  }
}

class _DemographicsPieChart extends StatelessWidget {
  final AppLocalizations t;
  final DataProvider dp;
  const _DemographicsPieChart({required this.t, required this.dp});

  @override
  Widget build(BuildContext context) {
    int citizens = dp.patients
        .where((p) => p.residencyStatus == ResidencyStatus.citizen)
        .length;
    int residents = dp.patients
        .where((p) => p.residencyStatus == ResidencyStatus.resident)
        .length;
    int total = citizens + residents;
    double cPct = total > 0 ? (citizens / total) * 100 : 50;
    double rPct = total > 0 ? (residents / total) * 100 : 50;

    return Row(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: PieChart(
              duration: Duration.zero,
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(
                    color: AppColors.primary,
                    value: cPct,
                    title: '${cPct.toStringAsFixed(0)}%',
                    radius: 44,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  PieChartSectionData(
                    color: AppColors.accent,
                    value: rPct,
                    title: '${rPct.toStringAsFixed(0)}%',
                    radius: 44,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(AppColors.primary, t.translate('citizens')),
            const SizedBox(height: 12),
            _Legend(AppColors.accent, t.translate('residents')),
          ],
        ),
      ],
    );
  }
}

class _AdherenceBarChart extends StatelessWidget {
  final DataProvider dp;
  const _AdherenceBarChart({required this.dp});

  @override
  Widget build(BuildContext context) {
    const labels = ['2.5 mg', '5 mg', '7.5 mg', '10 mg'];
    final adherence = labels.map((dose) {
      final cohort = dp.patients.where((p) => p.currentDose == dose).toList();
      if (cohort.isEmpty) return 85.0;
      return cohort.map((p) => p.complianceRate).reduce((a, b) => a + b) /
          cohort.length *
          100;
    }).toList();

    return RepaintBoundary(
      child: BarChart(
        duration: Duration.zero,
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${rod.toY.toStringAsFixed(0)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                interval: 25,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  int i = v.toInt();
                  if (i >= 0 && i < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[i],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border.withOpacity(0.6),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            4,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: adherence[i],
                  color: adherence[i] >= 90
                      ? AppColors.success
                      : adherence[i] >= 80
                      ? AppColors.warning
                      : AppColors.error,
                  width: 32,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterInventoryTable extends StatelessWidget {
  final DataProvider dp;
  const _CenterInventoryTable({required this.dp});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            children: [
              _th(tr('center_inventory')),
              _th('2.5 mg'),
              _th('5 mg'),
              _th(tr('col_status')),
            ],
          ),
          ...dp.centers.take(6).map((center) {
            final low =
                center.inventory2_5mg <= 10 || center.inventory5mg <= 10;
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              children: [
                _td(
                  center.getLocalizedName(context).split(' ').take(2).join(' '),
                ),
                _td(
                  '${center.inventory2_5mg}',
                  color: center.inventory2_5mg <= 10
                      ? AppColors.error
                      : AppColors.navy,
                ),
                _td(
                  '${center.inventory5mg}',
                  color: center.inventory5mg <= 10
                      ? AppColors.error
                      : AppColors.navy,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: low
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      low ? tr('low_stock') : tr('stable'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: low ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _th(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _td(String label, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.navy,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  AI ALERTS PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _AiAlertsPanel extends StatelessWidget {
  final AppLocalizations t;
  final DataProvider dp;
  const _AiAlertsPanel({required this.t, required this.dp});

  @override
  Widget build(BuildContext context) {
    final alerts = collectProgramAlerts(context, dp)
        .take(4)
        .map((a) => _AlertData(a.message, a.icon, a.color, a.time))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.bot,
                color: AppColors.accentLight,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.translate('ai_alerts_title'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Pulsing dot
              _PulseDot(),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map((a) => _AlertTile(data: a)),
        ],
      ),
    );
  }
}

class _AlertData {
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  const _AlertData(this.message, this.icon, this.color, this.time);
}

class _AlertTile extends StatelessWidget {
  final _AlertData data;
  const _AlertTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PATIENTS VIEW  (new full page)
// ─────────────────────────────────────────────────────────────────────────────

class _PatientsView extends StatefulWidget {
  final AppLocalizations t;
  const _PatientsView({required this.t});

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  String _search = '';
  String _filter = 'All';
  int _page = 0;
  static const int _pageSize = 25;

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final patients = dp.patients.where((p) {
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          p.getLocalizedFullName(context).toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
      final matchFilter =
          _filter == 'All' ||
          (_filter == 'Flagged' &&
              dp.logs.any(
                (l) => l.patientId == p.id && l.status == 'Flagged',
              )) ||
          (_filter == 'Overridden' &&
              dp.logs.any(
                (l) => l.patientId == p.id && l.status == 'Overridden',
              ));
      return matchSearch && matchFilter;
    }).toList();

    final totalPages = (patients.length / _pageSize).ceil().clamp(1, 999);
    final effectivePage = _page.clamp(0, totalPages - 1);
    final pageItems = patients
        .skip(effectivePage * _pageSize)
        .take(_pageSize)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('patient_registry'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('patient_registry_sub'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // Search + filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: context.tr('search_name_or_id'),
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              for (final f in ['All', 'Flagged', 'Overridden'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      f == 'All'
                          ? context.tr('all')
                          : f == 'Flagged'
                          ? context.tr('filter_flagged')
                          : context.tr('filter_overridden'),
                    ),
                    selected: _filter == f,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _filter == f ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() {
                      _filter = f;
                      _page = 0;
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                context.tr('patients_pagination', {
                  'count': '${patients.length}',
                  'page': '${effectivePage + 1}',
                  'total': '$totalPages',
                }),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: effectivePage > 0
                    ? () => setState(() => _page--)
                    : null,
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight),
                onPressed: effectivePage < totalPages - 1
                    ? () => setState(() => _page++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      color: AppColors.background,
                      child: Row(
                        children: [
                          _PatCol(context.tr('col_patient'), flex: 2),
                          _PatCol(context.tr('col_id'), flex: 1),
                          _PatCol(context.tr('col_dose'), flex: 1),
                          _PatCol(context.tr('col_bmi'), flex: 1),
                          _PatCol(context.tr('col_residency'), flex: 1),
                          _PatCol(context.tr('col_status'), flex: 1),
                          const SizedBox(width: 48), // Action column space
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: ListView.separated(
                        itemCount: pageItems.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final p = pageItems[i];
                          final isFlagged = dp.logs.any(
                            (l) => l.patientId == p.id && l.status == 'Flagged',
                          );
                          final isOverridden = dp.logs.any(
                            (l) =>
                                l.patientId == p.id && l.status == 'Overridden',
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.getLocalizedFullName(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p.id,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p.currentDose,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p.bmi.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p.residencyStatus == ResidencyStatus.citizen
                                        ? context.tr('citizens')
                                        : context.tr('resident'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          p.residencyStatus ==
                                              ResidencyStatus.citizen
                                          ? AppColors.primary
                                          : AppColors.accent,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _StatusChip(
                                    isFlagged
                                        ? 'Flagged'
                                        : isOverridden
                                        ? 'Override'
                                        : 'Active',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.fileText,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  tooltip: context.tr('view_details'),
                                  onPressed: () =>
                                      _showPatientDetails(context, p),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(BuildContext context, Patient p) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 800,
            height: 600,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.getLocalizedFullName(context),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.id} • ${p.age} سنة • ${p.getLocalizedGender(context)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Right column: Clinical info
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(
                                'الخطة العلاجية الحالية',
                                LucideIcons.fileText,
                              ),
                              _infoRow('الجرعة الحالية:', p.currentDose),
                              _infoRow(
                                'تاريخ آخر صرف:',
                                p.lastDispensingDate ?? 'غير متوفر',
                              ),
                              _infoRow(
                                'تاريخ الاستحقاق القادم:',
                                p.nextEligibleDate ?? 'غير متوفر',
                              ),
                              _infoRow(
                                'معدل الالتزام:',
                                '${(p.complianceRate * 100).toInt()}%',
                              ),
                              const SizedBox(height: 24),
                              _sectionTitle(
                                'المقاييس الحيوية',
                                LucideIcons.activity,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricBox(
                                      'الوزن',
                                      '${p.weight} kg',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _metricBox(
                                      'الطول',
                                      '${p.height} cm',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _metricBox(
                                      'مؤشر الكتلة',
                                      p.bmi.toStringAsFixed(1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _sectionTitle(
                                'تاريخ الجرعات',
                                LucideIcons.history,
                              ),
                              Wrap(
                                spacing: 8,
                                children: p.doseHistory
                                    .map(
                                      (d) => Chip(
                                        label: Text(d),
                                        backgroundColor: AppColors.surface,
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Left column: Profile details
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  'البيانات الشخصية',
                                  LucideIcons.userCheck,
                                ),
                                _infoRow('رقم الهوية:', p.emiratesId),
                                _infoRow(
                                  'الجنسية:',
                                  p.getLocalizedNationality(context),
                                ),
                                _infoRow(
                                  'الإقامة:',
                                  p.getLocalizedResidency(context),
                                ),
                                _infoRow(
                                  'الإمارة:',
                                  p.getLocalizedEmirate(context),
                                ),
                                const SizedBox(height: 24),
                                _sectionTitle(
                                  'الحالة الصحية المسبقة',
                                  LucideIcons.stethoscope,
                                ),
                                ...p
                                    .getLocalizedMedicalConditions(context)
                                    .map(
                                      (c) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              LucideIcons.checkCircle2,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                c,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                if (p.medicalConditions.isEmpty)
                                  const Text(
                                    'لا يوجد أمراض مزمنة',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
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
        );
      },
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.navy),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatCol extends StatelessWidget {
  final String label;
  final int flex;
  const _PatCol(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'Flagged':
        bg = AppColors.error.withOpacity(0.1);
        fg = AppColors.error;
        break;
      case 'Override':
        bg = AppColors.warning.withOpacity(0.1);
        fg = AppColors.warning;
        break;
      default:
        bg = AppColors.success.withOpacity(0.1);
        fg = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(context),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  String _label(BuildContext context) {
    switch (status) {
      case 'Flagged':
        return context.tr('status_flagged');
      case 'Override':
      case 'Overridden':
        return context.tr('status_override');
      default:
        return context.tr('status_active');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INVENTORY VIEW  (new full page)
// ─────────────────────────────────────────────────────────────────────────────

// Placeholder for localization context extensions if used

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    // Calculate global KPIs for enterprise feel
    final totalCenters = dp.centers.length;
    int criticalStockCenters = 0;
    int totalItems2_5 = 0;
    int totalItems5 = 0;

    for (var c in dp.centers) {
      if (c.inventory2_5mg <= 10 || c.inventory5mg <= 10) {
        criticalStockCenters++;
      }
      totalItems2_5 += c.inventory2_5mg;
      totalItems5 += c.inventory5mg;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('inventory_management'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('inventory_management_sub'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Web Top Bar Action Controls
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(context.tr('export_csv')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(context.tr('sync_all_nodes')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Enterprise KPI Cards Summary Strip
            _buildKPIRibbon(
              totalCenters,
              criticalStockCenters,
              totalItems2_5 + totalItems5,
            ),
            const SizedBox(height: 32),

            // Active Search & Table controls section
            _buildFilterUtilityRow(context),
            const SizedBox(height: 20),

            // Responsive ListView for detailed data cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dp.centers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, i) {
                final center = dp.centers[i];
                return _InventoryCard(center: center, dataProvider: dp);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIRibbon(int total, int critical, int totalUnits) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileStack = constraints.maxWidth < 750;
        return Flex(
          direction: isMobileStack ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: isMobileStack ? 0 : 1,
              child: _KPICard(
                title: context.tr('total_distribution_centers'),
                value: '$total',
                icon: Icons.maps_home_work_rounded,
                iconColor: AppColors.primary,
              ),
            ),
            if (!isMobileStack) const SizedBox(width: 16),
            Expanded(
              flex: isMobileStack ? 0 : 1,
              child: _KPICard(
                title: context.tr('critical_outages_low_stocks'),
                value: '$critical',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
                isCritical: critical > 0,
              ),
            ),
            if (!isMobileStack) const SizedBox(width: 16),
            Expanded(
              flex: isMobileStack ? 0 : 1,
              child: _KPICard(
                title: context.tr('total_tracked_inventory_units'),
                value: '$totalUnits',
                icon: Icons.inventory_2_rounded,
                iconColor: AppColors.accent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterUtilityRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: context.tr('filter_specific_nodes'),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: 'All Statuses',
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: 'All Statuses',
                child: Text(context.tr('all_statuses')),
              ),
              DropdownMenuItem(
                value: 'Low Stock',
                child: Text(context.tr('low_stock_alerts')),
              ),
            ],
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}

// Reusable micro-animated Web Card for distribution centers
class _InventoryCard extends StatefulWidget {
  final DispensingCenter center;
  final DataProvider dataProvider;

  const _InventoryCard({required this.center, required this.dataProvider});

  @override
  State<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<_InventoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.center;
    final anyLow =
        c.inventory2_5mg <= 10 ||
        c.inventory5mg <= 10 ||
        c.inventory7_5mg <= 10 ||
        c.inventory10mg <= 10;

    // Pseudo-random last dispensed time based on ID length/hash
    final mockMinsAgo = (c.id.hashCode % 59) + 1;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: anyLow
                ? AppColors.error.withOpacity(0.7)
                : (_isHovered
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border),
            width: anyLow || _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.06 : 0.02),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.store,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.getLocalizedName(context),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.getLocalizedRegion(context),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.activity,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('active_global_sync'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context
                                .tr('last_dispensed_ago')
                                .replaceAll('{time}', '$mockMinsAgo'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: anyLow
                        ? AppColors.error.withOpacity(0.08)
                        : AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: anyLow
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        anyLow
                            ? LucideIcons.alertTriangle
                            : LucideIcons.checkCircle2,
                        size: 14,
                        color: anyLow ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        anyLow
                            ? context.tr('critical_low')
                            : context.tr('stable'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: anyLow ? AppColors.error : AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SUMMARY KPI ROW
            Row(
              children: [
                Expanded(
                  child: _buildMiniKpi(
                    context,
                    context.tr('total_available'),
                    '${c.totalAvailable}',
                    LucideIcons.packageCheck,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMiniKpi(
                    context,
                    context.tr('total_dispensed'),
                    '${c.totalDispensed}',
                    LucideIcons.logOut,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMiniKpi(
                    context,
                    context.tr('total_handled'),
                    '${c.totalAllocated}',
                    LucideIcons.boxes,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // DOSAGE BREAKDOWN TABLE
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      border: const Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            context.tr('dosage_label'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            context.tr('available_label'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            context.tr('dispensed_label'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            context.tr('utilization_overview'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDosageRow('2.5 mg', c.inventory2_5mg, c.dispensed2_5mg),
                  const Divider(height: 1, color: AppColors.border),
                  _buildDosageRow('5.0 mg', c.inventory5mg, c.dispensed5mg),
                  const Divider(height: 1, color: AppColors.border),
                  _buildDosageRow('7.5 mg', c.inventory7_5mg, c.dispensed7_5mg),
                  const Divider(height: 1, color: AppColors.border),
                  _buildDosageRow(
                    '10.0 mg',
                    c.inventory10mg,
                    c.dispensed10mg,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('last_updated_just_now'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProfessionalReplenishDialog(
                    context,
                    widget.dataProvider,
                    c,
                  ),
                  icon: const Icon(LucideIcons.packagePlus, size: 16),
                  label: Text(context.tr('manage_stock_replenish')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKpi(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDosageRow(
    String label,
    int available,
    int dispensed, {
    bool isLast = false,
  }) {
    final total = available + dispensed;
    final dispensedPct = total == 0 ? 0.0 : (dispensed / total);
    final availablePct = total == 0 ? 0.0 : (available / total);

    final lowStock = available <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  '$available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: lowStock ? AppColors.error : AppColors.navy,
                  ),
                ),
                if (lowStock) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.alertCircle,
                    size: 14,
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$dispensed',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.info,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (total > 0) ...[
                          Expanded(
                            flex: (dispensedPct * 100).toInt(),
                            child: Container(height: 8, color: AppColors.info),
                          ),
                          Expanded(
                            flex: (availablePct * 100).toInt(),
                            child: Container(
                              height: 8,
                              color: lowStock
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ] else
                          Expanded(
                            child: Container(
                              height: 8,
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(dispensedPct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enterprise KPI Stats Widget
class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isCritical;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFFF1F2) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            radius: 24,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Professional Variable Input Multi-Dose Replenishment Dialog
void _showProfessionalReplenishDialog(
  BuildContext context,
  DataProvider dp,
  DispensingCenter center,
) {
  final formKey = GlobalKey<FormState>();
  int input2_5 = 0;
  int input5_0 = 0;
  int input7_5 = 0;
  int input10_0 = 0;

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        titlePadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.packagePlus,
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Replenish Node Stock: ${center.getLocalizedName(context)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Specify standard batches allocation quantities to supply to this center. Enter units for each dosage.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                _buildDoseInputRow(
                  '2.5 mg',
                  (val) => input2_5 = int.tryParse(val ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),
                _buildDoseInputRow(
                  '5.0 mg',
                  (val) => input5_0 = int.tryParse(val ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),
                _buildDoseInputRow(
                  '7.5 mg',
                  (val) => input7_5 = int.tryParse(val ?? '0') ?? 0,
                ),
                const SizedBox(height: 12),
                _buildDoseInputRow(
                  '10.0 mg',
                  (val) => input10_0 = int.tryParse(val ?? '0') ?? 0,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel Operation',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              formKey.currentState?.save();
              dp.updateInventory(
                center.id,
                d2_5: input2_5,
                d5: input5_0,
                d7_5: input7_5,
                d10: input10_0,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  width: 400,
                  backgroundColor: AppColors.success,
                  content: Text(
                    'Successfully authorized batch supply drops to ${center.getLocalizedName(context)}!',
                  ),
                ),
              );
            },
            child: const Text('Authorize Replenishment'),
          ),
        ],
      );
    },
  );
}

Widget _buildDoseInputRow(String label, void Function(String?) onSaved) {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Text(
          'Dosage $label Stock Up:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: '0 units',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          onSaved: onSaved,
        ),
      ),
    ],
  );
}

// Mock definitions allowing instant isolated IDE compilation

// ─────────────────────────────────────────────────────────────────────────────
//  AI ALERTS FULL VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _FraudAuditView extends StatelessWidget {
  final AppLocalizations t;
  const _FraudAuditView({required this.t});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final alerts = fraudProgramAlerts(context, dp);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('fraud_prevention_log'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('ai_alerts_sub'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.checkSquare,
                            size: 56,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('no_flagged_alerts'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, i) {
                        final alert = alerts[i];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: alert.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              alert.icon,
                              color: alert.color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            alert.message,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          trailing: Text(
                            alert.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAlertsFullView extends StatelessWidget {
  final AppLocalizations t;
  final String titleKey;
  const _AiAlertsFullView({
    required this.t,
    this.titleKey = 'ai_alerts_command_center',
  });

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final alerts = collectProgramAlerts(context, dp);
    final actionable = alerts
        .where((a) => a.kind != ProgramAlertKind.allClear)
        .toList();

    final fraudCount = actionable
        .where(
          (a) =>
              a.kind == ProgramAlertKind.fraudAttempt ||
              a.kind == ProgramAlertKind.override,
        )
        .length;
    final clinicalCount = actionable
        .where(
          (a) =>
              a.kind == ProgramAlertKind.clinicalIneffective ||
              a.kind == ProgramAlertKind.nonCompliance ||
              a.kind == ProgramAlertKind.clinicalPending,
        )
        .length;
    final supplyCount = actionable
        .where(
          (a) =>
              a.kind == ProgramAlertKind.criticalShortage ||
              a.kind == ProgramAlertKind.inventory ||
              a.kind == ProgramAlertKind.readyDispense,
        )
        .length;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bot, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                context.tr(titleKey) == titleKey
                    ? 'غرفة عمليات التنبيهات الذكية (AI Command Center)'
                    : context.tr(titleKey),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('ai_alerts_command_desc') == 'ai_alerts_command_desc'
                ? 'نظام مراقبة ذكي يعتمد على الذكاء الاصطناعي لاكتشاف التجاوزات، التنبؤ بنقص المخزون، وتحليل استجابة المرضى.'
                : context.tr('ai_alerts_command_desc'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  context.tr('metrics_fraud') == 'metrics_fraud'
                      ? 'أمن واحتيال'
                      : context.tr('metrics_fraud'),
                  fraudCount,
                  AppColors.error,
                  LucideIcons.shieldAlert,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  context.tr('metrics_clinical') == 'metrics_clinical'
                      ? 'متابعة سريرية'
                      : context.tr('metrics_clinical'),
                  clinicalCount,
                  AppColors.accent,
                  LucideIcons.activity,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  context.tr('metrics_supply') == 'metrics_supply'
                      ? 'أزمات الإمداد'
                      : context.tr('metrics_supply'),
                  supplyCount,
                  AppColors.warning,
                  LucideIcons.packageX,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: actionable.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.checkCircle,
                          size: 64,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('no_flagged_alerts'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 220,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: actionable.length,
                    itemBuilder: (context, i) {
                      final alert = actionable[i];
                      return _buildAlertCard(context, alert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: color.withValues(alpha: 0.08)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, ProgramAlert alert) {
    String actionLabel = '';
    IconData actionIcon = LucideIcons.arrowRight;
    Color actionColor = alert.color;

    switch (alert.kind) {
      case ProgramAlertKind.fraudAttempt:
        actionLabel =
            context.tr('action_freeze_account') == 'action_freeze_account'
            ? 'تجميد الحساب'
            : context.tr('action_freeze_account');
        actionIcon = LucideIcons.lock;
        break;
      case ProgramAlertKind.clinicalIneffective:
        actionLabel = context.tr('action_review_plan') == 'action_review_plan'
            ? 'مراجعة الخطة'
            : context.tr('action_review_plan');
        actionIcon = LucideIcons.fileSearch;
        break;
      case ProgramAlertKind.criticalShortage:
      case ProgramAlertKind.inventory:
        actionLabel =
            context.tr('action_emergency_restock') == 'action_emergency_restock'
            ? 'إرسال إمداد طارئ'
            : context.tr('action_emergency_restock');
        actionIcon = LucideIcons.truck;
        break;
      case ProgramAlertKind.nonCompliance:
        actionLabel =
            context.tr('action_contact_patient') == 'action_contact_patient'
            ? 'التواصل مع المريض'
            : context.tr('action_contact_patient');
        actionIcon = LucideIcons.phoneCall;
        break;
      default:
        actionLabel = context.tr('view_details');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: alert.color.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: alert.color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: alert.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(alert.icon, color: alert.color, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.message,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                alert.time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAlertDialog(context, alert),
                      icon: Icon(actionIcon, size: 16, color: actionColor),
                      label: Text(
                        actionLabel,
                        style: TextStyle(
                          color: actionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: actionColor.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
    );
  }

  void _showAlertDialog(BuildContext context, ProgramAlert alert) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alert.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(alert.icon, color: alert.color),
              ),
              const SizedBox(width: 12),
              const Text(
                'تفاصيل التنبيه (Alert Details)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
                if (alert.metadata.isNotEmpty) ...[
                  const Text(
                    'البيانات المرتبطة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: alert.metadata.entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${e.value}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إغلاق',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تنفيذ الإجراء بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: alert.color,
                foregroundColor: Colors.white,
              ),
              child: const Text('تنفيذ الإجراء'),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED UTILITY
// ─────────────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MANAGE DOCTORS
// ─────────────────────────────────────────────────────────────────────────────

class _ManageDoctorsView extends StatelessWidget {
  final AppLocalizations t;
  const _ManageDoctorsView({required this.t});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('manage_doctors_title'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          context.tr('manage_doctors_sub'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddDoctorDialog(context, dp);
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(context.tr('add_doctor')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dp.doctors.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final doc = dp.doctors[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          LucideIcons.stethoscope,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        doc.getLocalizedName(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: Text(
                        '${doc.getLocalizedSpecialty(context)} • ${doc.getLocalizedHospital(context)}',
                      ),
                      trailing: Text(
                        doc.getLocalizedEmirate(context),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDoctorDialog(BuildContext context, DataProvider dp) {
    final nameController = TextEditingController();
    final nameArController = TextEditingController();
    final specialtyController = TextEditingController();
    final specialtyArController = TextEditingController();
    final hospitalController = TextEditingController();
    final hospitalArController = TextEditingController();
    final emirateController = TextEditingController();
    final emirateArController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.tr('add_doctor')),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_name_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: nameArController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_name_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: specialtyController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_specialty_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: specialtyArController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_specialty_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hospitalController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_hospital_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: hospitalArController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_hospital_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emirateController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_emirate_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: emirateArController,
                          decoration: InputDecoration(
                            labelText: context.tr('doctor_emirate_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final newDoc = Doctor(
                  id: 'D${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.isEmpty
                      ? 'New Doctor'
                      : nameController.text,
                  nameAr: nameArController.text.isEmpty
                      ? 'دكتور جديد'
                      : nameArController.text,
                  emirate: emirateController.text.isEmpty
                      ? 'Dubai'
                      : emirateController.text,
                  emirateAr: emirateArController.text.isEmpty
                      ? 'دبي'
                      : emirateArController.text,
                  specialty: specialtyController.text.isEmpty
                      ? 'General'
                      : specialtyController.text,
                  specialtyAr: specialtyArController.text.isEmpty
                      ? 'عام'
                      : specialtyArController.text,
                  hospital: hospitalController.text.isEmpty
                      ? 'General Hospital'
                      : hospitalController.text,
                  hospitalAr: hospitalArController.text.isEmpty
                      ? 'مستشفى عام'
                      : hospitalArController.text,
                  email: 'doctor@moh.gov.ae',
                );
                dp.addDoctor(newDoc);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('doctor_added_successfully')),
                  ),
                );
              },
              child: Text(context.tr('add_doctor')),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MANAGE CENTERS
// ─────────────────────────────────────────────────────────────────────────────

class _ManageCentersView extends StatelessWidget {
  final AppLocalizations t;
  const _ManageCentersView({required this.t});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('manage_therapy_centers_title'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          context.tr('manage_therapy_centers_sub'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddCenterDialog(context, dp);
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(context.tr('add_therapy_center')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dp.therapyCenters.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final center = dp.therapyCenters[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        child: const Icon(
                          LucideIcons.building,
                          color: AppColors.navy,
                        ),
                      ),
                      title: Text(
                        center.getLocalizedName(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: Text(
                        '${center.getLocalizedEmirate(context)} • ${context.tr('chief_therapist')}: ${center.name}',
                      ),
                      trailing: Text(
                        '${center.activePatients} ${context.tr('active_patients_legend')}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCenterDialog(BuildContext context, DataProvider dp) {
    final nameController = TextEditingController();
    final nameArController = TextEditingController();
    final emirateController = TextEditingController();
    final emirateArController = TextEditingController();
    final therapistController = TextEditingController();
    final therapistArController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.tr('add_therapy_center')),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: context.tr('center_name_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: nameArController,
                          decoration: InputDecoration(
                            labelText: context.tr('center_name_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emirateController,
                          decoration: InputDecoration(
                            labelText: context.tr('center_emirate_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: emirateArController,
                          decoration: InputDecoration(
                            labelText: context.tr('center_emirate_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: therapistController,
                          decoration: InputDecoration(
                            labelText: context.tr('chief_therapist_en_label'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: therapistArController,
                          decoration: InputDecoration(
                            labelText: context.tr('chief_therapist_ar_label'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final newCenter = PhysicalTherapyCenter(
                  id: 'T${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.isEmpty
                      ? 'New Center'
                      : nameController.text,
                  nameAr: nameArController.text.isEmpty
                      ? 'مركز جديد'
                      : nameArController.text,
                  emirate: emirateController.text.isEmpty
                      ? 'Dubai'
                      : emirateController.text,
                  emirateAr: emirateArController.text.isEmpty
                      ? 'دبي'
                      : emirateArController.text,
                  chiefTherapist: therapistController.text.isEmpty
                      ? 'Dr. Default'
                      : therapistController.text,
                  chiefTherapistAr: therapistArController.text.isEmpty
                      ? 'د. افتراضي'
                      : therapistArController.text,
                  latitude: 25.2,
                  longitude: 55.2,
                  phone: '+971 00 000 0000',
                  activePatients: 0,
                  services: ['General Therapy'],
                  servicesAr: ['علاج عام'],
                  workingHours: '08:00 AM - 08:00 PM',
                );
                dp.addPhysicalTherapyCenter(newCenter);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('therapy_center_added_successfully'),
                    ),
                  ),
                );
              },
              child: Text(context.tr('add_therapy_center')),
            ),
          ],
        );
      },
    );
  }
}
