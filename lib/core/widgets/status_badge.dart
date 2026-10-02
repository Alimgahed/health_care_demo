import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

enum BadgeStatus { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.neutral,
    this.icon,
  });

  /// Maps lifecycle labels from the shared records to one visual vocabulary.
  factory StatusBadge.lifecycle(String label, {Key? key}) {
    final value = label.toLowerCase().replaceAll('_', ' ').trim();
    final status = switch (value) {
      'approved' ||
      'dispensed' ||
      'completed' ||
      'active' => BadgeStatus.success,
      'pending' ||
      'under review' ||
      'needs information' ||
      'warning' ||
      'out of stock' => BadgeStatus.warning,
      'rejected' || 'expired' || 'blocked' || 'failed' => BadgeStatus.error,
      'ready' || 'submitted' => BadgeStatus.info,
      _ => BadgeStatus.neutral,
    };
    return StatusBadge(key: key, label: label, status: status);
  }

  Color _getBackgroundColor(bool isDark) {
    switch (status) {
      case BadgeStatus.success:
        return AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1);
      case BadgeStatus.warning:
        return AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.1);
      case BadgeStatus.error:
        return AppColors.error.withValues(alpha: isDark ? 0.2 : 0.1);
      case BadgeStatus.info:
        return AppColors.info.withValues(alpha: isDark ? 0.2 : 0.1);
      case BadgeStatus.neutral:
        return isDark ? AppColors.darkBorder : AppColors.border;
    }
  }

  Color _getTextColor(bool isDark) {
    switch (status) {
      case BadgeStatus.success:
        return isDark ? const Color(0xFF76D9AD) : AppColors.success;
      case BadgeStatus.warning:
        return isDark ? const Color(0xFFFFD584) : AppColors.warning;
      case BadgeStatus.error:
        return isDark ? const Color(0xFFFF9EA4) : AppColors.error;
      case BadgeStatus.info:
        return isDark ? const Color(0xFF91CBE7) : AppColors.info;
      case BadgeStatus.neutral:
        return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semanticIcon =
        icon ??
        switch (status) {
          BadgeStatus.success => Icons.check_circle_outline,
          BadgeStatus.warning => Icons.error_outline,
          BadgeStatus.error => Icons.cancel_outlined,
          BadgeStatus.info => Icons.info_outline,
          BadgeStatus.neutral => Icons.radio_button_unchecked,
        };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isDark),
          border: Border.all(
            color: _getTextColor(isDark).withValues(alpha: .24),
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(semanticIcon, size: 14, color: _getTextColor(isDark)),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _getTextColor(isDark),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
