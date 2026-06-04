import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeStatus {
  success,
  warning,
  error,
  info,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;

  const StatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.neutral,
  });

  Color _getBackgroundColor(bool isDark) {
    switch (status) {
      case BadgeStatus.success:
        return AppColors.success.withOpacity(isDark ? 0.2 : 0.1);
      case BadgeStatus.warning:
        return AppColors.warning.withOpacity(isDark ? 0.2 : 0.1);
      case BadgeStatus.error:
        return AppColors.error.withOpacity(isDark ? 0.2 : 0.1);
      case BadgeStatus.info:
        return AppColors.info.withOpacity(isDark ? 0.2 : 0.1);
      case BadgeStatus.neutral:
        return isDark ? AppColors.darkBorder : AppColors.border;
    }
  }

  Color _getTextColor(bool isDark) {
    switch (status) {
      case BadgeStatus.success:
        return isDark ? const Color(0xFF34D399) : AppColors.success;
      case BadgeStatus.warning:
        return isDark ? const Color(0xFFFBBF24) : AppColors.warning;
      case BadgeStatus.error:
        return isDark ? const Color(0xFFF87171) : AppColors.error;
      case BadgeStatus.info:
        return isDark ? const Color(0xFF60A5FA) : AppColors.info;
      case BadgeStatus.neutral:
        return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _getTextColor(isDark),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
