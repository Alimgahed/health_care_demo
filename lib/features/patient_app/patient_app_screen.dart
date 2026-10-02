import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mounjaro_demo/features/treatment_plan/models/treatment_plan.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mock_data.dart';
import '../../core/demo/demo_session_provider.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/platform_state_view.dart';
import 'medication_order/medication_order_wizard.dart';

class PatientAppScreen extends StatefulWidget {
  const PatientAppScreen({super.key});

  @override
  State<PatientAppScreen> createState() => _PatientAppScreenState();
}

class _PatientAppScreenState extends State<PatientAppScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final patientId = context.watch<DemoSessionProvider>().patientId;
    final patient = dataProvider.getPatientById(patientId);
    if (patient == null) {
      return Scaffold(
        body: PlatformStateView(
          kind: PlatformStateKind.error,
          title: context.isArabic
              ? 'ملف المريض غير متاح'
              : 'Patient record unavailable',
          message: context.isArabic
              ? 'ارجع إلى اختيار الحساب ثم حاول مرة أخرى.'
              : 'Return to access selection and choose a patient account.',
        ),
      );
    }
    final plan = dataProvider.getPlanForPatient(patient.id);

    // Computed values
    final double weightLost = patient.weightHistory.isNotEmpty
        ? patient.weightHistory.first - patient.weight
        : 0;
    final double? targetWeight = plan?.targetWeight;
    final baseline = patient.weightHistory.isEmpty
        ? patient.weight
        : patient.weightHistory.first;
    final double progress = targetWeight == null || baseline <= targetWeight
        ? 0
        : (weightLost / (baseline - targetWeight)).clamp(0.0, 1.0);
    final int sessionsAttended =
        plan?.sessions.where((s) => s.isAttended).length ?? 0;
    final int totalSessions = plan?.totalSessions ?? 0;

    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Greeting Header ──────────────────────────────────────────
            _buildGreeting(context, patient),
            const SizedBox(height: 24),

            // ── Next Injection Hero Card ──────────────────────────────────
            _buildInjectionCard(context, plan, dataProvider),
            const SizedBox(height: 20),

            // ── Quick Stats Row ───────────────────────────────────────────
            _buildQuickStats(
              context,
              patient,
              weightLost,
              sessionsAttended,
              totalSessions,
            ),
            const SizedBox(height: 24),

            // ── Direct Medication Request ─────────────────────────────────
            _buildMedicationAction(context),
            const SizedBox(height: 24),

            // ── Goal Progress ────────────────────────────────────────────
            if (targetWeight != null) ...[
              _buildGoalProgress(context, patient, targetWeight, progress),
              const SizedBox(height: 24),
            ],

            // ── Weight Journey Chart ─────────────────────────────────────
            // _buildWeightChart(context, patient),
            // const SizedBox(height: 24),

            // ── Today's Routine (Quick Actions) ──────────────────────────
            _buildTodayRoutine(context, plan),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Greeting Header ─────────────────────────────────────────────────────────
  Widget _buildGreeting(BuildContext context, Patient patient) {
    final hour = DateTime.now().hour;
    final isMorning = hour < 12;

    final greetingText = context.isArabic
        ? (isMorning ? 'صباح الخير،' : 'مساء الخير،')
        : (isMorning ? 'Good morning,' : 'Good evening,');

    return Row(
      children: [
        // User Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(LucideIcons.user, color: AppColors.primary, size: 26),
          ),
        ),
        const SizedBox(width: 16),

        // Greeting Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greetingText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                patient.getLocalizedFullName(context).split(' ')[0],
                maxLines: 1,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Adherence Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: patient.complianceRate,
                      strokeWidth: 3.5,
                      backgroundColor: AppColors.success.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    ),
                    const Icon(
                      LucideIcons.flame,
                      size: 12,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.isArabic ? 'الالتزام' : 'Adherence',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(patient.complianceRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Current medication interval ──────────────────────────────────────────
  Widget _buildInjectionCard(
    BuildContext context,
    TreatmentPlan? plan,
    DataProvider data,
  ) {
    if (plan == null) {
      return Card(
        child: PlatformStateView(
          kind: PlatformStateKind.empty,
          title: context.isArabic
              ? 'لا توجد خطة دوائية نشطة'
              : 'No active medication plan',
          message: context.isArabic
              ? 'ستظهر الجرعات هنا عندما يعتمد فريقك خطة العلاج.'
              : 'Your doses will appear here when your care team approves a treatment plan.',
        ),
      );
    }
    final now = DateTime.now();
    final interval = math.max(1, plan.medicationFrequencyDays);
    final elapsedDays = now.difference(plan.createdAt).inDays;
    final slot = elapsedDays < 0 ? 0 : elapsedDays ~/ interval;
    final nextDate = plan.createdAt.add(Duration(days: (slot + 1) * interval));
    final recorded = data
        .medicationEventsFor(plan.patientId)
        .any(
          (event) =>
              event.planId == plan.id &&
              event.status == MedicationDoseStatus.taken &&
              event.scheduledAt.difference(plan.createdAt).inDays ~/ interval ==
                  slot,
        );
    final canRecord =
        plan.status == 'Active' &&
        plan.clinicalApprovalStatus == 'approved' &&
        !now.isBefore(plan.createdAt);
    final nextDateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(nextDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.syringe, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.isArabic
                      ? 'الجرعة الموصوفة: ${plan.medicationDose}'
                      : 'Prescribed dose: ${plan.medicationDose}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            !canRecord
                ? (context.isArabic
                      ? 'توثيق الجرعة متاح بعد اعتماد الخطة'
                      : 'Dose recording opens after plan approval')
                : recorded
                ? (context.isArabic
                      ? 'تم توثيق جرعة الفترة الحالية'
                      : 'Current dose recorded')
                : (context.isArabic
                      ? 'وثّق جرعتك الحالية'
                      : 'Record your current dose'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.isArabic
                ? 'الجرعة التالية حسب الخطة: $nextDateLabel'
                : 'Next dose in your plan: $nextDateLabel',
            style: const TextStyle(color: Color(0xFFE5F2EC), fontSize: 13),
          ),
          const SizedBox(height: 17),
          ElevatedButton.icon(
            onPressed: recorded || !canRecord
                ? null
                : () {
                    data.logMedication(
                      plan.id,
                      now,
                      status: MedicationDoseStatus.taken,
                    );
                    final saved = data
                        .medicationEventsFor(plan.patientId)
                        .any(
                          (event) =>
                              event.planId == plan.id &&
                              event.status == MedicationDoseStatus.taken &&
                              event.scheduledAt
                                          .difference(plan.createdAt)
                                          .inDays ~/
                                      interval ==
                                  slot,
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          saved
                              ? (context.isArabic
                                    ? 'تم توثيق الجرعة في سجلك.'
                                    : 'Dose recorded in your care record.')
                              : (context.isArabic
                                    ? 'تعذر توثيق الجرعة. حاول مرة أخرى أو تواصل مع فريق الرعاية.'
                                    : 'Unable to record the dose. Try again or contact your care team.'),
                        ),
                      ),
                    );
                  },
            icon: Icon(
              recorded ? LucideIcons.circleCheck : LucideIcons.check,
              size: 18,
            ),
            label: Text(
              recorded
                  ? (context.isArabic ? 'الجرعة موثقة' : 'Dose recorded')
                  : !canRecord
                  ? (context.isArabic
                        ? 'الخطة بانتظار الاعتماد'
                        : 'Plan awaiting approval')
                  : (context.isArabic
                        ? 'تسجيل أخذ الجرعة'
                        : 'Record dose taken'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              disabledBackgroundColor: const Color(0xFFD8ECE2),
              disabledForegroundColor: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats Row ──────────────────────────────────────────────────────────
  Widget _buildQuickStats(
    BuildContext context,
    Patient patient,
    double weightLost,
    int sessionsAttended,
    int totalSessions,
  ) {
    return Row(
      children: [
        _buildStatBubble(
          context,
          icon: LucideIcons.trendingDown,
          value: '${weightLost.toStringAsFixed(1)} kg',
          label: context.tr('app_stat_weight_loss'),
          color: AppColors.success,
          flex: 1,
        ),
        const SizedBox(width: 12),
        _buildStatBubble(
          context,
          icon: LucideIcons.activity,
          value: patient.bmi.toStringAsFixed(1),
          label: 'BMI',
          color: patient.bmi >= 30 ? AppColors.warning : AppColors.info,
          flex: 1,
        ),
        const SizedBox(width: 12),
        _buildStatBubble(
          context,
          icon: LucideIcons.calendar,
          value: '$sessionsAttended/$totalSessions',
          label: context.tr('app_stat_sessions'),
          color: AppColors.primary,
          flex: 1,
        ),
      ],
    );
  }

  Widget _buildStatBubble(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Direct Medication Request Action ──────────────────────────────────────────
  Widget _buildMedicationAction(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MedicationOrderWizard(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.shoppingBag, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('dashboard_request_med_now'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('dashboard_request_med_desc'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronLeft, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Goal Progress Card ────────────────────────────────────────────────────────
  Widget _buildGoalProgress(
    BuildContext context,
    Patient patient,
    double targetWeight,
    double progress,
  ) {
    final remainingKg = patient.weight - targetWeight;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('dashboard_weight_progress_title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context
                          .tr('app_goal_label')
                          .replaceAll(
                            '{target}',
                            targetWeight.toStringAsFixed(1),
                          )
                          .replaceAll(
                            '{current}',
                            patient.weight.toStringAsFixed(1),
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildProgressRing(progress),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.8 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('dashboard_completed_pct'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context
                      .tr('dashboard_remaining_kg')
                      .replaceAll('{kg}', remainingKg.toStringAsFixed(1)),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(double progress) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(64, 64),
            painter: _RingPainter(progress: progress),
          ),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: progress >= 0.8 ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Weight Chart ─────────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildWeightChart(BuildContext context, Patient patient) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('weight_loss_journey'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('weight_journey_sub'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.isArabic
                      ? '${patient.weightHistory.length} قراءات'
                      : '${patient.weightHistory.length} readings',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 &&
                            idx < patient.weightHistory.length &&
                            idx % 2 == 0) {
                          return Text(
                            context.tr('check_reading', {'n': '${idx + 1}'}),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: patient.weightHistory
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    shadow: Shadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.surface,
                            strokeWidth: 2,
                            strokeColor: AppColors.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's Routine ───────────────────────────────────────────────────────────
  Widget _buildTodayRoutine(BuildContext context, TreatmentPlan? plan) {
    final exercises = plan?.homeExercises ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.tr('dashboard_todays_routine'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (exercises.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.isArabic
                      ? '${exercises.length} تمارين'
                      : '${exercises.length} exercises',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (exercises.isEmpty)
          _buildEmptyRoutine(context)
        else
          ...exercises
              .take(2)
              .map(
                (e) => _buildRoutineItem(
                  context,
                  context.isArabic ? e.nameAr : e.name,
                  context.isArabic
                      ? '${e.durationMinutes} دقيقة · ${e.sets} مجموعات × ${e.reps} تكرار'
                      : '${e.durationMinutes} min · ${e.sets} sets × ${e.reps} reps',
                  LucideIcons.activity,
                  AppColors.primary,
                ),
              ),
        const SizedBox(height: 12),
        // Upcoming session reminder
        if (plan != null && plan.sessions.any((s) => !s.isAttended))
          _buildUpcomingSessionBanner(context, plan),
      ],
    );
  }

  Widget _buildEmptyRoutine(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('app_no_exercises_today'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessionBanner(BuildContext context, TreatmentPlan plan) {
    final upcoming = plan.sessions.firstWhere((s) => !s.isAttended);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy.withValues(alpha: 0.9), AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.calendar, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('dashboard_upcoming_session')}: ${upcoming.sessionNumber}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${upcoming.scheduledDate.day}/${upcoming.scheduledDate.month}/${upcoming.scheduledDate.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular progress ring
class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 6.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = progress >= 0.8 ? AppColors.success : AppColors.primary
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
