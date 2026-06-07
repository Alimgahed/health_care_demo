import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/localization/l10n_extension.dart';

class PatientJourneyTimeline extends StatelessWidget {
  final List<ActivityLog> logs;

  const PatientJourneyTimeline({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              context.tr('no_activity_logs'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isLast = index == logs.length - 1;
        return _buildTimelineItem(context, log, isLast);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, ActivityLog log, bool isLast) {
    final kind = log.eventKind;
    final (Color color, IconData icon, String typeLabel) = switch (kind) {
      'dispense' => (AppColors.success, LucideIcons.package, context.tr('log_type_dispense')),
      'care_plan' => (AppColors.primary, LucideIcons.clipboardList, context.tr('log_type_care_plan')),
      'registration' => (AppColors.textPrimary, LucideIcons.userPlus, context.tr('log_type_registration')),
      'clinical_review' => (AppColors.warning, LucideIcons.stethoscope, context.tr('log_type_clinical_review')),
      _ => (AppColors.textSecondary, LucideIcons.activity, context.tr('log_type_other')),
    };

    final isCarePlan = kind == 'care_plan';
    final statusColor = log.status == 'Pending'
        ? AppColors.warning
        : log.status == 'Overridden'
            ? AppColors.error
            : AppColors.success;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        if (log.status != 'Success') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.getLocalizedStatus(context),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          log.formatTimestamp(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      log.getLocalizedAction(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCarePlan) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.tr('log_not_dispense_hint'),
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          log.getLocalizedCenterName(context),
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
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