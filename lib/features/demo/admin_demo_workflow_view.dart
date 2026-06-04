import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/center_shell.dart';
import '../dashboard/doctor_shell.dart';
import '../dashboard/patient_shell.dart';
import 'demo_flow_provider.dart';
import 'demo_portal_scaffold.dart';
import 'demo_workflow_step.dart';

class AdminDemoWorkflowView extends StatelessWidget {
  final ValueChanged<int> onAdminNavigate;

  const AdminDemoWorkflowView({super.key, required this.onAdminNavigate});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<DemoFlowProvider>();
    final dp = context.watch<DataProvider>();
    final focus = dp.getPatientById(flow.focusPatientId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('demo_workflow_title'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('demo_workflow_subtitle'),
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 24),
          _FlowDiagram(completed: flow.completedSteps),
          const SizedBox(height: 28),
          _ScenarioPicker(
            dp: dp,
            selectedId: flow.focusPatientId,
            onSelect: flow.setFocusPatient,
          ),
          if (focus != null) ...[
            const SizedBox(height: 16),
            _FocusPatientBanner(patient: focus),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                context.tr('demo_steps_heading'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: flow.resetProgress,
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: Text(context.tr('demo_reset_progress')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...kDemoWorkflowSteps.map(
            (step) => _StepCard(
              step: step,
              isDone: flow.completedSteps.contains(step.index),
              onToggleDone: () {
                if (flow.completedSteps.contains(step.index)) {
                  flow.unmarkStep(step.index);
                } else {
                  flow.markStepComplete(step.index);
                }
              },
              onLaunch: () => _launchStep(context, step, onAdminNavigate),
            ),
          ),
        ],
      ),
    );
  }

  void _launchStep(BuildContext context, DemoWorkflowStep step, ValueChanged<int> onAdminNavigate) {
    final flow = context.read<DemoFlowProvider>();
    final patientId = step.patientId ?? step.scenarioPatientId ?? flow.focusPatientId;

    switch (step.role) {
      case DemoPortalRole.admin:
        if (step.adminNavIndex != null) {
          onAdminNavigate(step.adminNavIndex!);
          flow.markStepComplete(step.index);
        }
        break;
      case DemoPortalRole.doctor:
        flow.beginPortalStep(step.index);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DemoPortalScaffold(
              stepIndex: step.index,
              child: DoctorShell(
                initialPatientId: patientId,
                initialTabIndex: step.doctorTabIndex,
              ),
            ),
          ),
        ).then((_) => flow.endPortal());
        break;
      case DemoPortalRole.center:
        flow.beginPortalStep(step.index);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DemoPortalScaffold(
              stepIndex: step.index,
              child: CenterShell(initialPatientId: patientId),
            ),
          ),
        ).then((_) => flow.endPortal());
        break;
      case DemoPortalRole.patient:
        flow.beginPortalStep(step.index);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DemoPortalScaffold(
              stepIndex: step.index,
              child: const PatientShell(),
            ),
          ),
        ).then((_) => flow.endPortal());
        break;
    }
  }
}

class _FlowDiagram extends StatelessWidget {
  final Set<int> completed;

  const _FlowDiagram({required this.completed});

  @override
  Widget build(BuildContext context) {
    final nodes = [
      (LucideIcons.landmark, context.tr('demo_role_admin')),
      (LucideIcons.stethoscope, context.tr('demo_role_doctor')),
      (LucideIcons.building2, context.tr('demo_role_center')),
      (LucideIcons.user, context.tr('demo_role_patient')),
      (LucideIcons.shieldCheck, context.tr('demo_role_audit')),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final vertical = constraints.maxWidth < 720;
            if (vertical) {
              return Column(
                children: [
                  for (var i = 0; i < nodes.length; i++) ...[
                    _FlowNode(
                      icon: nodes[i].$1,
                      label: nodes[i].$2,
                      done: i < 2 ? completed.contains(i) : completed.contains(i + 1),
                    ),
                    if (i < nodes.length - 1)
                      Icon(LucideIcons.arrowDown, color: AppColors.primary.withValues(alpha: 0.5)),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < nodes.length; i++) ...[
                  Expanded(
                    child: _FlowNode(
                      icon: nodes[i].$1,
                      label: nodes[i].$2,
                      done: _nodeDone(i, completed),
                    ),
                  ),
                  if (i < nodes.length - 1)
                    Icon(LucideIcons.chevronRight, color: AppColors.primary.withValues(alpha: 0.45), size: 20),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  bool _nodeDone(int node, Set<int> done) {
    switch (node) {
      case 0:
        return done.contains(0) || done.contains(1);
      case 1:
        return done.contains(2) || done.contains(3);
      case 2:
        return done.contains(4) || done.contains(5);
      case 3:
        return done.contains(6);
      case 4:
        return done.contains(7);
      default:
        return false;
    }
  }
}

class _FlowNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _FlowNode({required this.icon, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: (done ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done ? AppColors.success : AppColors.primary,
              width: done ? 2 : 1,
            ),
          ),
          child: Icon(icon, color: done ? AppColors.success : AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
        ),
      ],
    );
  }
}

class _ScenarioPicker extends StatelessWidget {
  final DataProvider dp;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ScenarioPicker({
    required this.dp,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scenarios = [
      ('P001', 'demo_scenario_p001'),
      ('P003', 'demo_scenario_p003'),
      ('P002', 'demo_scenario_p002'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('demo_scenarios_heading'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: scenarios.map((s) {
            final p = dp.getPatientById(s.$1);
            final selected = selectedId == s.$1;
            return ChoiceChip(
              label: Text(
                p != null
                    ? '${p.getLocalizedFullName(context)} · ${context.tr(s.$2)}'
                    : context.tr(s.$2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: selected,
              onSelected: (_) => onSelect(s.$1),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FocusPatientBanner extends StatelessWidget {
  final Patient patient;

  const _FocusPatientBanner({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.userCheck, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('demo_patient_focus', {
                'name': patient.getLocalizedFullName(context),
                'id': patient.id,
              }),
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final DemoWorkflowStep step;
  final bool isDone;
  final VoidCallback onToggleDone;
  final VoidCallback onLaunch;

  const _StepCard({
    required this.step,
    required this.isDone,
    required this.onToggleDone,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String roleLabel) = switch (step.role) {
      DemoPortalRole.admin => (LucideIcons.landmark, AppColors.navy, context.tr('demo_role_admin')),
      DemoPortalRole.doctor => (LucideIcons.stethoscope, AppColors.primary, context.tr('demo_role_doctor')),
      DemoPortalRole.center => (LucideIcons.building2, const Color(0xFF1565C0), context.tr('demo_role_center')),
      DemoPortalRole.patient => (LucideIcons.smartphone, AppColors.accent, context.tr('demo_role_patient')),
    };

    final launchLabel = step.role == DemoPortalRole.admin
        ? context.tr('demo_go_admin_view')
        : context.tr('demo_open_portal');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isDone,
              onChanged: (_) => onToggleDone(),
              activeColor: AppColors.primary,
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${step.index + 1} · $roleLabel',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(step.titleKey),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(step.bodyKey),
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.lightbulb, size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr(step.tipKey),
                            style: const TextStyle(fontSize: 13, color: AppColors.navy, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: onLaunch,
                    icon: Icon(
                      step.role == DemoPortalRole.admin ? LucideIcons.panelLeft : LucideIcons.externalLink,
                      size: 18,
                    ),
                    label: Text(launchLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
