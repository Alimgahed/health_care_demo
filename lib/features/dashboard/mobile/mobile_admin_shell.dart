import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../auth/login_screen.dart';

class MobileAdminShell extends StatelessWidget {
  const MobileAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ministry Health'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.globe),
            onPressed: () => localeProvider.toggleLanguage(),
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
            const SizedBox(height: 24),
            
            // Mini KPIs
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMiniKpi(t.translate('total_active_patients'), '14,289', LucideIcons.users, Colors.blue),
                _buildMiniKpi(t.translate('govt_subsidy'), '42.5M', LucideIcons.wallet, Colors.orange),
                _buildMiniKpi(t.translate('fraud_prevented'), '342', LucideIcons.shieldAlert, Colors.red),
                _buildMiniKpi(t.translate('national_bmi_drop'), '-4.2', LucideIcons.activity, Colors.green),
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
            
            // Quick Actions List
            _buildActionItem(context, t.translate('view_fraud_alerts'), LucideIcons.alertTriangle, Colors.red),
            const SizedBox(height: 12),
            _buildActionItem(context, t.translate('approve_subsidies'), LucideIcons.checkCircle, Colors.green),
            const SizedBox(height: 12),
            _buildActionItem(context, t.translate('generate_report'), LucideIcons.fileText, Colors.blue),
            const SizedBox(height: 12),
            _buildActionItem(context, t.translate('contact_centers'), LucideIcons.phoneCall, AppColors.primary),
            
            const SizedBox(height: 48), // Safe area
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
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
            content: Text('Action executed: \$title'),
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
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
