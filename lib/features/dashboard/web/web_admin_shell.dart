import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../auth/login_screen.dart';
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

class _WebAdminShellState extends State<WebAdminShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _navigate(int index) {
    if (_selectedIndex == index) return;
    _fadeCtrl.reset();
    setState(() => _selectedIndex = index);
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Fixed Sidebar ─────────────────────────────────────────────────
          _Sidebar(
            selectedIndex: _selectedIndex,
            onNavigate: _navigate,
            t: t,
            localeProvider: localeProvider,
          ),
          // ── Right Panel ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _Topbar(
                  t: t,
                  localeProvider: localeProvider,
                  dataProvider: dataProvider,
                  onLogout: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildBody(t, dataProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations t, DataProvider dp) {
    switch (_selectedIndex) {
      case 0:
        return _OverviewDashboard(t: t, dp: dp);
      case 1:
        return const WebMapAnalyticsScreen();
      case 2:
        return _PatientsView(t: t, dp: dp);
      case 3:
        return _InventoryView(t: t, dp: dp);
      case 4:
        return _AiAlertsFullView(t: t, dp: dp);
      default:
        return _OverviewDashboard(t: t, dp: dp);
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

  const _Sidebar({
    required this.selectedIndex,
    required this.onNavigate,
    required this.t,
    required this.localeProvider,
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
                      color: Colors.white.withOpacity(0.08), width: 1)),
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
                  child: const Icon(Icons.health_and_safety,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mounjaro NCC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Command Center',
                        style: TextStyle(
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
                  _navSection('Overview'),
                  _navItem(LucideIcons.layoutDashboard, 'Dashboard', 0),
                  _navSection('Analytics'),
                  _navItem(LucideIcons.map, t.translate('geo_analytics'), 1),
                  _navItem(LucideIcons.users, 'Patients', 2, badge: '1.2K'),
                  _navItem(LucideIcons.package, 'Inventory', 3),
                  _navSection('Intelligence'),
                  _navItem(LucideIcons.bot, t.translate('ai_alerts_title'), 4,
                      badge: '3', badgeDanger: true),
                  _navItem(LucideIcons.shieldAlert, 'Fraud Log', 5),
                  _navItem(LucideIcons.fileText, 'Reports', 6),
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
                      color: Colors.white.withOpacity(0.08), width: 1)),
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
                    child: Text('ME',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ministry Executive',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('admin@moh.gov.ae',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(LucideIcons.logOut,
                    color: Colors.white38, size: 16),
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

  Widget _navItem(IconData icon, String label, int index,
      {String? badge, bool badgeDanger = false}) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onNavigate(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.55)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
  final DataProvider dataProvider;
  final VoidCallback onLogout;

  const _Topbar({
    required this.t,
    required this.localeProvider,
    required this.dataProvider,
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
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('National Command Center',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              Text('Last synced: Today, 14:32 GST',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          // Lang toggle
          _topBtn(
            icon: LucideIcons.globe,
            label: localeProvider.locale.languageCode == 'en'
                ? 'العربية'
                : 'English',
            onTap: localeProvider.toggleLanguage,
          ),
          const SizedBox(width: 8),
          // Notifications
          _iconBtn(LucideIcons.bell, hasAlert: true, onTap: () {}),
          const SizedBox(width: 8),
          // Export
          _primaryBtn('Export Report', LucideIcons.download, onTap: () {}),
          const SizedBox(width: 8),
          // Logout
          _iconBtn(LucideIcons.logOut, onTap: onLogout),
        ],
      ),
    );
  }

  Widget _topBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: AppColors.navy),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.navy,
              fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _iconBtn(IconData icon,
      {bool hasAlert = false, required VoidCallback onTap}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, size: 18, color: AppColors.textSecondary),
          onPressed: onTap,
          style: IconButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
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

  Widget _primaryBtn(String label, IconData icon,
      {required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERVIEW DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewDashboard extends StatelessWidget {
  final AppLocalizations t;
  final DataProvider dp;

  const _OverviewDashboard({required this.t, required this.dp});

  @override
  Widget build(BuildContext context) {
    final activePatients = dp.totalActivePatients;
    final avgBmi = dp.averageBmi;
    final fraudPrevented = dp.fraudIncidentsPrevented;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Row ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.users,
                value: activePatients.toString(),
                label: t.translate('total_active_patients'),
                trend: '+14% growth',
                trendUp: true,
                accentColor: AppColors.primary,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.wallet,
                value: _fmtSubsidy(dp.totalGovtSubsidyDisbursed),
                label: t.translate('govt_subsidy'),
                trend: 'Q2 Budget',
                trendUp: null,
                accentColor: AppColors.accent,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.activity,
                value: avgBmi.toStringAsFixed(1),
                label: t.translate('national_bmi_drop'),
                trend: '↓ ${(34.2 - avgBmi).toStringAsFixed(1)} drop',
                trendUp: true,
                accentColor: AppColors.success,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.shieldAlert,
                value: fraudPrevented.toString(),
                label: t.translate('fraud_prevented'),
                trend: 'Cases Blocked',
                trendUp: true,
                accentColor: AppColors.error,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // ── Extra KPI Row (new) ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.clipboard,
                value: '91.4%',
                label: 'Adherence Rate',
                trend: '↑ 3.2% vs last',
                trendUp: true,
                accentColor: AppColors.info,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.building2,
                value: dp.centers.length.toString(),
                label: 'Active Centers',
                trend: 'All Regions',
                trendUp: null,
                accentColor: AppColors.navy,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.package,
                value: _totalStock(dp),
                label: 'Total Stock Units',
                trend: _stockStatus(dp),
                trendUp: _stockOk(dp),
                accentColor: AppColors.warning,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _KpiCard(
                icon: LucideIcons.trendingUp,
                value: '78%',
                label: 'Obesity Index Reduction',
                trend: 'vs Baseline 2023',
                trendUp: true,
                accentColor: AppColors.success,
              )),
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
                      title: t.translate('obesity_index_title'),
                      subtitle: 'Monthly average BMI across all enrolled patients',
                      pill: 'On Track',
                      pillColor: AppColors.success,
                      height: 300,
                      child: _ObesityLineChart(dp: dp),
                    ),
                    const SizedBox(height: 20),
                    _ChartCard(
                      title: t.translate('dispensing_vs_goals'),
                      subtitle: 'Active patients vs target ceiling by dose tier',
                      height: 280,
                      child: _ConsumptionBarChart(t: t, dp: dp),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right 1/3
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _AiAlertsPanel(t: t, dp: dp),
                    const SizedBox(height: 20),
                    _ChartCard(
                      title: t.translate('demographics_title'),
                      subtitle: 'Citizens vs Residents',
                      height: 280,
                      child: _DemographicsPieChart(t: t, dp: dp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Bottom Row: Compliance + Centers + Recent ────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Adherence by Dose Tier',
                  subtitle: 'Compliance rate per medication strength',
                  height: 280,
                  child: _AdherenceBarChart(dp: dp),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _ChartCard(
                  title: 'Center Inventory Status',
                  subtitle: 'Real-time stock levels across facilities',
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
  }

  String _fmtSubsidy(double amt) {
    if (amt >= 1000000) return '\$${(amt / 1000000).toStringAsFixed(1)}M';
    return '\$${(amt / 1000).toStringAsFixed(0)}K';
  }

  String _totalStock(DataProvider dp) {
    int total = 0;
    for (var c in dp.centers) {
      total += c.inventory2_5mg + c.inventory5mg;
    }
    return total.toString();
  }

  String _stockStatus(DataProvider dp) {
    bool anyLow =
        dp.centers.any((c) => c.inventory2_5mg <= 10 || c.inventory5mg <= 10);
    return anyLow ? 'Low Stock Alert' : 'Levels Stable';
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
              offset: const Offset(0, 4)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trend,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trendFg)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
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
              offset: const Offset(0, 4)),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (pill != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (pillColor ?? AppColors.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            (pillColor ?? AppColors.success).withOpacity(0.25)),
                  ),
                  child: Text(pill!,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pillColor ?? AppColors.success)),
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
  final DataProvider dp;
  const _ObesityLineChart({required this.dp});

  @override
  Widget build(BuildContext context) {
    const bmiLevels = [33.5, 33.1, 32.7, 32.2, 31.8, 31.2, 30.8, 30.2, 29.8];
    const targetLine = [28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0];
    const months = ['Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    return RepaintBoundary(
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border.withOpacity(0.6), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  int i = v.toInt();
                  if (i >= 0 && i < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(months[i],
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
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
                  getTitlesWidget: _leftTitle),
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
                  (i) => FlSpot(i.toDouble(), bmiLevels[i])),
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
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            LineChartBarData(
              spots: List.generate(
                  targetLine.length,
                  (i) => FlSpot(i.toDouble(), targetLine[i])),
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
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: _leftTitle),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        int i = v.toInt();
                        if (i >= 0 && i < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[i],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.border.withOpacity(0.6), strokeWidth: 1),
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
                            top: Radius.circular(5)),
                      ),
                      BarChartRodData(
                        toY: targets[i],
                        color: AppColors.accent.withOpacity(0.7),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
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
            _Legend(AppColors.primary, 'Active Patients'),
            const SizedBox(width: 20),
            _Legend(AppColors.accent, 'Target Limit'),
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
                        fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: AppColors.accent,
                    value: rPct,
                    title: '${rPct.toStringAsFixed(0)}%',
                    radius: 44,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
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
    // Adherence percentages per dose tier (mock derived from logs)
    const adherence = [88.0, 94.0, 91.0, 85.0];
    const labels = ['2.5 mg', '5 mg', '7.5 mg', '10 mg'];

    return RepaintBoundary(
      child: BarChart(
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
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
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
                      child: Text(labels[i],
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border.withOpacity(0.6), strokeWidth: 1),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(5)),
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
            decoration:
                BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            children: [
              _th('Center'),
              _th('2.5 mg'),
              _th('5 mg'),
              _th('Status'),
            ],
          ),
          ...dp.centers.take(6).map((center) {
            final low =
                center.inventory2_5mg <= 10 || center.inventory5mg <= 10;
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              children: [
                _td(center.getLocalizedName(context).split(' ').take(2).join(' ')),
                _td('${center.inventory2_5mg}',
                    color: center.inventory2_5mg <= 10
                        ? AppColors.error
                        : AppColors.navy),
                _td('${center.inventory5mg}',
                    color: center.inventory5mg <= 10
                        ? AppColors.error
                        : AppColors.navy),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: low
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      low ? 'Low' : 'OK',
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
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      );

  Widget _td(String label, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.navy)),
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
    final alerts = <_AlertData>[];

    for (var center in dp.centers) {
      if (center.inventory2_5mg <= 10) {
        alerts.add(_AlertData(
          '${center.getLocalizedName(context)}: 2.5mg critical low (${center.inventory2_5mg} left)',
          Icons.warning_amber_rounded,
          AppColors.warning,
          '2 min ago',
        ));
      }
      if (center.inventory5mg <= 10) {
        alerts.add(_AlertData(
          '${center.getLocalizedName(context)}: 5mg critical low (${center.inventory5mg} left)',
          Icons.warning_amber_rounded,
          AppColors.error,
          '5 min ago',
        ));
      }
      if (alerts.length >= 2) break;
    }

    // Fraud-derived alerts from logs
    final flagged =
        dp.logs.where((l) => l.status == 'Flagged').take(2).toList();
    for (var log in flagged) {
      alerts.add(_AlertData(
        '${log.getLocalizedPatientName(context)}: ${log.getLocalizedAction(context)} flagged at ${log.getLocalizedCenterName(context)}',
        LucideIcons.shieldAlert,
        AppColors.error,
        'Today',
      ));
      if (alerts.length >= 4) break;
    }

    if (alerts.isEmpty) {
      alerts.add(_AlertData('All inventories stable — no alerts today.',
          Icons.check_circle_outline, AppColors.success, 'Now'));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bot, color: AppColors.accentLight, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.translate('ai_alerts_title'),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
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
                Text(data.message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.45)),
                const SizedBox(height: 4),
                Text(data.time,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10)),
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
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
  final DataProvider dp;
  const _PatientsView({required this.t, required this.dp});

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  String _search = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final dp = widget.dp;
    final patients = dp.patients.where((p) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          p.getLocalizedFullName(context).toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
      final matchFilter = _filter == 'All' ||
          (_filter == 'Flagged' &&
              dp.logs
                  .any((l) => l.patientId == p.id && l.status == 'Flagged')) ||
          (_filter == 'Overridden' &&
              dp.logs
                  .any((l) => l.patientId == p.id && l.status == 'Overridden'));
      return matchSearch && matchFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Registry',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text(
              'Browse, search, and filter all enrolled patients across the program.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          // Search + filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID…',
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
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
                    label: Text(f),
                    selected: _filter == f,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: _filter == f ? Colors.white : AppColors.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                          horizontal: 20, vertical: 12),
                      color: AppColors.background,
                      child: const Row(
                        children: [
                          _PatCol('Patient', flex: 2),
                          _PatCol('ID', flex: 1),
                          _PatCol('Dose', flex: 1),
                          _PatCol('BMI', flex: 1),
                          _PatCol('Residency', flex: 1),
                          _PatCol('Status', flex: 1),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: ListView.separated(
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final p = patients[i];
                          final isFlagged = dp.logs.any((l) =>
                              l.patientId == p.id && l.status == 'Flagged');
                          final isOverridden = dp.logs.any((l) =>
                              l.patientId == p.id && l.status == 'Overridden');
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(p.getLocalizedFullName(context),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.navy)),
                                ),
                                Expanded(
                                  child: Text(p.id,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ),
                                Expanded(
                                  child: Text(p.currentDose,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.navy)),
                                ),
                                Expanded(
                                  child: Text(
                                    p.bmi.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.navy),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p.residencyStatus ==
                                            ResidencyStatus.citizen
                                        ? 'Citizen'
                                        : 'Resident',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: p.residencyStatus ==
                                                ResidencyStatus.citizen
                                            ? AppColors.primary
                                            : AppColors.accent),
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
}

class _PatCol extends StatelessWidget {
  final String label;
  final int flex;
  const _PatCol(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)),
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INVENTORY VIEW  (new full page)
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryView extends StatelessWidget {
  final AppLocalizations t;
  final DataProvider dp;
  const _InventoryView({required this.t, required this.dp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventory Management',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text('Real-time stock levels across all dispensing centers.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: dp.centers.length,
              itemBuilder: (context, i) {
                final c = dp.centers[i];
                final anyLow = c.inventory2_5mg <= 10 || c.inventory5mg <= 10;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: anyLow
                            ? AppColors.error.withOpacity(0.4)
                            : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.getLocalizedName(context),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: anyLow
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(anyLow ? 'Low Stock' : 'Stable',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: anyLow
                                        ? AppColors.error
                                        : AppColors.success)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _StockRow('2.5 mg', c.inventory2_5mg, 50),
                      const SizedBox(height: 8),
                      _StockRow('5 mg', c.inventory5mg, 50),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  const _StockRow(this.label, this.current, this.max);

  @override
  Widget build(BuildContext context) {
    final pct = (current / max).clamp(0.0, 1.0);
    final color = current <= 10
        ? AppColors.error
        : current <= 20
            ? AppColors.warning
            : AppColors.success;
    return Row(
      children: [
        SizedBox(
            width: 44,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$current',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AI ALERTS FULL VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _AiAlertsFullView extends StatelessWidget {
  final AppLocalizations t;
  final DataProvider dp;
  const _AiAlertsFullView({required this.t, required this.dp});

  @override
  Widget build(BuildContext context) {
    final logs = dp.logs
        .where((l) => l.status == 'Flagged' || l.status == 'Overridden')
        .toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Alerts & Audit Log',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text(
              'Safety flags, manual dispensing overrides, and inventory alerts across all UAE regions.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.checkSquare,
                              size: 56, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text('No flagged alerts detected',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        final isFlagged = log.getLocalizedStatus(context) == 'Flagged';
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (isFlagged ? AppColors.error : AppColors.warning)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isFlagged
                                  ? LucideIcons.shieldAlert
                                  : LucideIcons.shieldCheck,
                              color: isFlagged
                                  ? AppColors.error
                                  : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          title: Text(
                              '${log.getLocalizedPatientName(context)} (${log.patientId}) — ${log.getLocalizedAction(context)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy)),
                          subtitle: Text('${log.getLocalizedCenterName(context)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          trailing: _StatusChip(log.getLocalizedStatus(context)),
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
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.navy,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}