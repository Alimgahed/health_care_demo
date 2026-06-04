import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/demo_metrics.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../auth/login_screen.dart';
import '../web/web_doctor_shell.dart';
import '../web/web_center_shell.dart';

class MobileAdminShell extends StatelessWidget {
  const MobileAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dp = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('ministry_health')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('greeting'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('demo_cohort')}: ${dp.totalActivePatients} ${context.tr('records')} · ${context.tr('national_registry')}: ${DemoMetrics.formatCount(DemoMetrics.nationalEnrolled)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: WebDoctorShell(embeddedInAdmin: true),
                        ),
                      ),
                    ),
                    icon: const Icon(LucideIcons.stethoscope, size: 18),
                    label: Text(context.tr('nav_clinical_ops')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: WebCenterShell(embeddedInAdmin: true),
                        ),
                      ),
                    ),
                    icon: const Icon(LucideIcons.pill, size: 18),
                    label: Text(context.tr('nav_dispensing_ops')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMiniKpi(
                  t.translate('total_active_patients'),
                  DemoMetrics.formatCount(DemoMetrics.nationalEnrolled),
                  LucideIcons.users,
                  AppColors.primary,
                ),
                _buildMiniKpi(
                  t.translate('govt_subsidy'),
                  DemoMetrics.formatAed(dp.totalGovtSubsidyDisbursed),
                  LucideIcons.wallet,
                  AppColors.accent,
                ),
                _buildMiniKpi(
                  t.translate('fraud_prevented'),
                  '${dp.fraudIncidentsPrevented}',
                  LucideIcons.shieldAlert,
                  AppColors.error,
                ),
                _buildMiniKpi(
                  context.tr('national_avg_bmi_cohort'),
                  dp.averageBmi.toStringAsFixed(1),
                  LucideIcons.activity,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              t.translate('quick_actions'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(context, t.translate('view_fraud_alerts'), LucideIcons.alertTriangle, Colors.red),
            const SizedBox(height: 12),
            _buildActionItem(context, t.translate('approve_subsidies'), LucideIcons.checkCircle, Colors.green),
            const SizedBox(height: 12),
            _buildActionItem(context, t.translate('generate_report'), LucideIcons.fileText, Colors.blue),
            const SizedBox(height: 12),
            _buildActionItem(context, t.translate('contact_centers'), LucideIcons.phoneCall, AppColors.primary),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKpi(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('action_executed', {'title': title})),
            backgroundColor: AppColors.navy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
