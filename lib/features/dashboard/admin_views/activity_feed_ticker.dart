import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/models/activity_log.dart';

class ActivityFeedTicker extends StatefulWidget {
  const ActivityFeedTicker({super.key});

  @override
  State<ActivityFeedTicker> createState() => _ActivityFeedTickerState();
}

class _ActivityFeedTickerState extends State<ActivityFeedTicker> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        final recentLogs = dp.logs.take(5).toList();
        
        if (recentLogs.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                  color: AppColors.primary.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.activity, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('live_activity_feed'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.5 + (_pulseController.value * 0.5)),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.error.withValues(alpha: _pulseController.value * 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('live_badge'),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: recentLogs.map((log) => _buildLogItem(context, log)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogItem(BuildContext context, ActivityLog log) {
    IconData icon;
    Color color;

    switch (log.eventType) {
      case ActivityEventType.dispense:
        icon = LucideIcons.pill;
        color = AppColors.success;
        break;
      case ActivityEventType.carePlan:
        icon = LucideIcons.clipboardList;
        color = AppColors.primary;
        break;
      case ActivityEventType.registration:
        icon = LucideIcons.userPlus;
        color = AppColors.accent;
        break;
      case ActivityEventType.inventoryReplenish:
        icon = LucideIcons.packagePlus;
        color = AppColors.warning;
        break;
      case ActivityEventType.clinicalReview:
        icon = LucideIcons.stethoscope;
        color = AppColors.info;
        break;
      default:
        icon = LucideIcons.info;
        color = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.getLocalizedAction(context),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.user, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      log.getLocalizedPatientName(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.getLocalizedCenterName(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              log.formatTimestamp(context).split('·').last.trim(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}