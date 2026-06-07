import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../auth/login_screen.dart';
import 'mobile_admin_views.dart';
import '../admin_views/system_audit_log_view.dart';

class MobileAdminShell extends StatefulWidget {
  const MobileAdminShell({super.key});

  @override
  State<MobileAdminShell> createState() => _MobileAdminShellState();
}

class _MobileAdminShellState extends State<MobileAdminShell> {
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

  Widget _buildBody(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (_selectedIndex) {
      case 0:
        return MobileAdminDashboardView(t: t);
      case 1:
        return MobileManageDoctorsView(t: t);
      case 2:
        return MobileManageCentersView(t: t);
      case 3:
        return MobileRegionalAnalyticsView(t: t);
      case 4:
        return MobileInventoryView(t: t);
      case 5:
        return MobileFraudAuditView(t: t);
      case 6:
        return SystemAuditLogView(t: t);
      default:
        return MobileAdminDashboardView(t: t);
    }
  }

  void _onItemTapped(int index, int totalLogs) {
    setState(() {
      _selectedIndex = index;
      if (index == 6) {
        _lastSeenLogsCount = totalLogs;
      }
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    String appBarTitle = context.tr('ministry_health');
    switch (_selectedIndex) {
      case 1: appBarTitle = context.tr('manage_doctors_title'); break;
      case 2: appBarTitle = context.tr('manage_therapy_centers_title'); break;
      case 3: appBarTitle = context.tr('nav_clinical_ops'); break;
      case 4: appBarTitle = context.tr('nav_inventory'); break;
      case 5: appBarTitle = context.tr('nav_fraud_log'); break;
      case 6: appBarTitle = context.tr('system_audit_log'); break;
    }

    final totalLogs = Provider.of<DataProvider>(context).logs.length;
    final unreadLogs = _lastSeenLogsCount == -1 ? 0 : (totalLogs - _lastSeenLogsCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.globe),
            onPressed: localeProvider.toggleLanguage,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.navy,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Image.asset('assets/logo.png', width: 32, height: 32, errorBuilder: (c,e,s) => const Icon(LucideIcons.activity, color: Colors.white, size: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('app_title'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.surface24, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildDrawerSectionTitle(context.tr('nav_section_dashboards')),
                    _buildDrawerItem(LucideIcons.layoutDashboard, context.tr('nav_dashboard'), 0, totalLogs),
                    _buildDrawerItem(LucideIcons.stethoscope, context.tr('manage_doctors_title'), 1, totalLogs),
                    _buildDrawerItem(LucideIcons.building2, context.tr('manage_therapy_centers_title'), 2, totalLogs),
                    const SizedBox(height: 16),
                    _buildDrawerSectionTitle(context.tr('nav_section_operations')),
                    _buildDrawerItem(LucideIcons.map, context.tr('nav_clinical_ops'), 3, totalLogs),
                    _buildDrawerItem(LucideIcons.packageSearch, context.tr('nav_inventory'), 4, totalLogs),
                    const SizedBox(height: 16),
                    _buildDrawerSectionTitle(context.tr('nav_section_administration')),
                    _buildDrawerItem(LucideIcons.shieldAlert, context.tr('nav_fraud_log'), 5, totalLogs),
                    _buildDrawerItem(LucideIcons.activitySquare, context.tr('system_audit_log'), 6, totalLogs, badgeCount: unreadLogs),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.surface12)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white12,
                      child: Icon(LucideIcons.user, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('ministry_executive_user'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('admin@moh.gov.ae', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index, int totalLogs, {int badgeCount = 0}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        selected: isSelected,
        selectedTileColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _onItemTapped(index, totalLogs),
      ),
    );
  }
}