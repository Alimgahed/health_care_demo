import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import 'demo_flow_provider.dart';
import 'demo_workflow_step.dart';

/// Wraps a role portal during a guided demo with step context and return action.
class DemoPortalScaffold extends StatelessWidget {
  final int stepIndex;
  final Widget child;

  const DemoPortalScaffold({
    super.key,
    required this.stepIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final step = kDemoWorkflowSteps[stepIndex];
    final flow = context.watch<DemoFlowProvider>();

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.navy,
            elevation: 2,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        flow.endPortal();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                      tooltip: context.tr('demo_back_to_workflow'),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('demo_step_n_of', {
                              'n': '${stepIndex + 1}',
                              'total': '$kDemoWorkflowStepCount',
                            }),
                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            context.tr(step.titleKey),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        flow.markStepComplete(stepIndex);
                        flow.endPortal();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Text(context.tr('demo_mark_done')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
