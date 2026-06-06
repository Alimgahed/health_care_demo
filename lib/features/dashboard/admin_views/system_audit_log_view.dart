import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/theme/app_colors.dart';

class SystemAuditLogView extends StatelessWidget {
  final AppLocalizations t;

  const SystemAuditLogView({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final logs = provider.logs;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activitySquare, size: 28, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                t.translate('system_audit_log'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('system_audit_log_desc'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: logs.isEmpty
                ? Center(child: Text(t.translate('no_records_found')))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildAuditLogCard(context, log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(BuildContext context, ActivityLog log) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (log.eventType) {
      case ActivityEventType.dispense:
        iconColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        icon = LucideIcons.pill;
        break;
      case ActivityEventType.inventoryReplenish:
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        icon = LucideIcons.packagePlus;
        break;
      case ActivityEventType.adminAction:
        iconColor = AppColors.accent;
        bgColor = AppColors.accent.withValues(alpha: 0.1);
        icon = LucideIcons.settings;
        break;
      case ActivityEventType.clinicalReview:
      case ActivityEventType.carePlan:
        iconColor = AppColors.textPrimary;
        bgColor = AppColors.navy.withValues(alpha: 0.1);
        icon = LucideIcons.fileText;
        break;
      default:
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.border;
        icon = LucideIcons.info;
    }

    final timeStr = log.formatTimestamp(context);
    final action = log.getLocalizedAction(context);
    final patient = log.getLocalizedPatientName(context);
    final center = log.getLocalizedCenterName(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(patient, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 16),
                      Icon(LucideIcons.building, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeStr.split(' · ')[0], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(timeStr.split(' · ')[1], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}