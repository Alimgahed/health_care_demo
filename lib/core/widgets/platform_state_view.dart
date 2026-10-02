import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

enum PlatformStateKind { empty, noResults, error, permission, warning, loading }

/// A compact, actionable state that works in tables, panels, and full pages.
class PlatformStateView extends StatelessWidget {
  final PlatformStateKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PlatformStateView({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      PlatformStateKind.error ||
      PlatformStateKind.permission => AppColors.errorText,
      PlatformStateKind.warning => AppColors.warningText,
      PlatformStateKind.loading => AppColors.infoText,
      _ => AppColors.successText,
    };
    final icon = switch (kind) {
      PlatformStateKind.empty => Icons.inbox_outlined,
      PlatformStateKind.noResults => Icons.search_off_outlined,
      PlatformStateKind.error => Icons.error_outline,
      PlatformStateKind.permission => Icons.lock_outline,
      PlatformStateKind.warning => Icons.warning_amber_outlined,
      PlatformStateKind.loading => Icons.hourglass_empty,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 240;
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.sm : AppSpacing.xl,
                ),
                child: Semantics(
                  liveRegion: kind == PlatformStateKind.error,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!compact) ...[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: kind == PlatformStateKind.loading
                              ? Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: color,
                                  ),
                                )
                              : Icon(icon, color: color),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: compact ? 4 : AppSpacing.xs),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        SizedBox(height: compact ? 8 : AppSpacing.md),
                        OutlinedButton(
                          onPressed: onAction,
                          child: Text(actionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
