import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import 'dart:math' as math;

class PlanOverviewScreen extends StatefulWidget {
  final Patient patient;

  const PlanOverviewScreen({super.key, required this.patient});

  @override
  State<PlanOverviewScreen> createState() => _PlanOverviewScreenState();
}

class _PlanOverviewScreenState extends State<PlanOverviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _progressController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataProvider = Provider.of<DataProvider>(context);
    final plan = dataProvider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return _buildEmptyState(context, isDark);
    }

    final double progress = ((widget.patient.weightHistory.first - widget.patient.weight) /
            (widget.patient.weightHistory.first - plan.targetWeight))
        .clamp(0.0, 1.0);
    final int attendedSessions =
        plan.sessions.where((s) => s.isAttended).length;
    final double weightLost =
        widget.patient.weightHistory.first - widget.patient.weight;
    final double weightToGo = widget.patient.weight - plan.targetWeight;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark, plan),
            const SizedBox(height: 24),

            // Hero Progress Card
            _buildProgressHeroCard(context, isDark, plan, progress, weightLost, weightToGo),
            const SizedBox(height: 20),

            // Quick Stats Row
            _buildQuickStats(context, isDark, attendedSessions, plan),
            const SizedBox(height: 20),

            // Weight Journey Card
            _buildWeightJourneyCard(context, isDark, weightLost, weightToGo, plan),
            const SizedBox(height: 20),

            // Plan Details Card
            _buildPlanDetailsCard(context, isDark, plan),
            const SizedBox(height: 20),

            // Sessions Timeline Preview
            _buildSessionsPreview(context, isDark, plan),
            const SizedBox(height: 20),

            // Next Milestone Card
            _buildNextMilestone(context, isDark, plan, progress),
            const SizedBox(height: 20),

            // Health Metrics Row
            _buildHealthMetrics(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.clipboardList,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_treatment_plan_mobile'),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, dynamic plan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('nav_overview_plan'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.patient.fullName,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: plan.clinicalApprovalStatus == 'approved'
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: plan.clinicalApprovalStatus == 'approved'
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: plan.clinicalApprovalStatus == 'approved'
                      ? AppColors.success
                      : AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                plan.clinicalApprovalStatus == 'approved'
                    ? (context.tr('approved'))
                    : (context.tr('pending_review')),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: plan.clinicalApprovalStatus == 'approved'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeroCard(BuildContext context, bool isDark, dynamic plan,
      double progress, double weightLost, double weightToGo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles background
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    // Animated Progress Ring
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(110, 110),
                                painter: _RingPainter(
                                  progress: progress * _progressAnimation.value,
                                  backgroundColor: AppColors.background.withValues(alpha: 0.15),
                                  progressColor: AppColors.accent,
                                  strokeWidth: 9,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(progress * _progressAnimation.value * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                      color: AppColors.surface,
                                    ),
                                  ),
                                  Text(
                                    context.tr('goal'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.surface70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('weight_goal'),
                            style: TextStyle(
                              color: AppColors.surface70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${plan.targetWeight} ${context.tr('kg_label')}",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.surface,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.tr('weight_to_go', {'weight': '${weightToGo.toStringAsFixed(1)}'}),
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('journey_progress'),
                          style: TextStyle(
                              color: AppColors.surface70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          context.tr('weight_lost', {'weight': '${weightLost.toStringAsFixed(1)}'}),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress * _progressAnimation.value,
                            backgroundColor: AppColors.background.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent),
                            minHeight: 8,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      BuildContext context, bool isDark, int attended, dynamic plan) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            context, isDark, cardBg, borderColor,
            icon: LucideIcons.checkCircle2,
            label: context.tr('sessions_label'),
            value: '$attended',
            sub: context.tr('session_completed', {'completed': '', 'total': '${plan.totalSessions}'}).replaceFirst(' ', ''),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            context, isDark, cardBg, borderColor,
            icon: LucideIcons.trendingUp,
            label: context.tr('adherence'),
            value: '95%',
            sub: context.tr('excellent'),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat(
            context, isDark, cardBg, borderColor,
            icon: LucideIcons.flame,
            label: context.tr('streak'),
            value: '12',
            sub: context.tr('days_label'),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color borderColor, {
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightJourneyCard(BuildContext context, bool isDark,
      double weightLost, double weightToGo, dynamic plan) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final startWeight = widget.patient.weightHistory.first;
    final currentWeight = widget.patient.weight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
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
              Text(
                context.tr('weight_journey'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.tr('weight_lost', {'weight': '${weightLost.toStringAsFixed(1)}'}),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildWeightPoint(
                context, isDark,
                label: context.tr('start_label'),
                weight: startWeight,
                color: AppColors.error,
                isActive: false,
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(height: 2, color: AppColors.primary.withValues(alpha: 0.15)),
                    Container(
                      height: 2,
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) => FractionallySizedBox(
                          widthFactor: ((startWeight - currentWeight) /
                                  (startWeight - plan.targetWeight))
                              .clamp(0.0, 1.0) *
                              _progressAnimation.value,
                          child: Container(color: AppColors.primary),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${currentWeight.toStringAsFixed(1)} ${context.tr('kg_label')}",
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildWeightPoint(
                context, isDark,
                label: context.tr('target_label'),
                weight: plan.targetWeight.toDouble(),
                color: AppColors.success,
                isActive: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildJourneyMetric(
                  isDark,
                  label: context.tr('bmi_progress'),
                  value: context.tr('improving'),
                  icon: LucideIcons.activity,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildJourneyMetric(
                  isDark,
                  label: context.tr('est_completion'),
                  value: context.tr('weeks_count', {'count': '8'}),
                  icon: LucideIcons.calendarClock,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPoint(BuildContext context, bool isDark,
      {required String label, required double weight, required Color color, required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${weight.toStringAsFixed(0)} ${context.tr('kg_label')}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildJourneyMetric(bool isDark,
      {required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetailsCard(BuildContext context, bool isDark, dynamic plan) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.clipboardList,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('plan_details_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailTile(context, isDark,
              icon: LucideIcons.userCircle,
              label: context.tr('assigned_doctor'),
              value: plan.doctorName,
              iconColor: AppColors.primary),
          _buildDivider(isDark),
          _buildDetailTile(context, isDark,
              icon: LucideIcons.calendarDays,
              label: context.tr('treatment_start'),
              value:
                  '${plan.createdAt.day} / ${plan.createdAt.month} / ${plan.createdAt.year}',
              iconColor: AppColors.info),
          _buildDivider(isDark),
          _buildDetailTile(context, isDark,
              icon: LucideIcons.target,
              label: context.tr('treatment_duration'),
              value: context.tr('sessions_count', {'count': '${plan.totalSessions}'}),
              iconColor: AppColors.accent),
          _buildDivider(isDark),
          _buildDetailTile(context, isDark,
              icon: LucideIcons.stethoscope,
              label: context.tr('treatment_type_label'),
              value: context.tr('nutritional_therapy'),
              iconColor: AppColors.textPrimary),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDetailTile(BuildContext context, bool isDark,
      {required IconData icon,
      required String label,
      required String value,
      required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.border,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildSessionsPreview(BuildContext context, bool isDark, dynamic plan) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final sessions = plan.sessions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
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
              Text(
                context.tr('recent_sessions'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  context.tr('view_all'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Session dots timeline
          Row(
            children: List.generate(plan.totalSessions.clamp(0, 10), (index) {
              final session = index < plan.sessions.length ? plan.sessions[index] : null;
              final isAttended = session?.isAttended == true;
              final isMissed = session != null && !isAttended && session.scheduledDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              
              int upcomingIdx = plan.sessions.indexWhere((s) => s.isAttended != true && s.scheduledDate.isAfter(DateTime.now().subtract(const Duration(days: 1))));
              if (upcomingIdx == -1) upcomingIdx = plan.sessions.where((s) => s.isAttended == true).length;
              final isCurrent = index == upcomingIdx;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : isAttended
                                  ? AppColors.primary
                                  : isMissed
                                      ? AppColors.error.withValues(alpha: 0.15)
                                      : isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                          border: isCurrent
                              ? Border.all(color: AppColors.accent, width: 1.5)
                              : isMissed
                                  ? Border.all(color: AppColors.error, width: 1.0)
                                  : null,
                        ),
                        child: isCurrent
                            ? const Icon(LucideIcons.clock, size: 12, color: AppColors.accent)
                            : isAttended
                                ? Icon(LucideIcons.check, size: 12, color: AppColors.surface)
                                : isMissed
                                    ? const Icon(LucideIcons.x, size: 12, color: AppColors.error)
                                    : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(AppColors.primary, context.tr('attended_status')),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.accent, context.tr('upcoming_status')),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.error, context.tr('missed_status')),
              const SizedBox(width: 12),
              _buildLegendDot(
                  isDark ? AppColors.darkBorder : AppColors.border,
                  context.tr('scheduled_status')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildNextMilestone(
      BuildContext context, bool isDark, dynamic plan, double progress) {
    final nextMilestone = progress < 0.25
        ? '25% Goal Reached'
        : progress < 0.5
            ? context.tr('halfway_point')
            : progress < 0.75
                ? '75% Goal Reached'
                : 'Final Goal';
    final milestoneProgress = progress < 0.25
        ? progress / 0.25
        : progress < 0.5
            ? (progress - 0.25) / 0.25
            : progress < 0.75
                ? (progress - 0.5) / 0.25
                : (progress - 0.75) / 0.25;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.trophy,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('next_milestone'),
                  style: TextStyle(
                    color: AppColors.surface60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextMilestone,
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: milestoneProgress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.background.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(milestoneProgress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetrics(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('health_metrics'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark, cardBg, borderColor,
                icon: LucideIcons.droplets,
                label: 'Hydration',
                value: '2.4L',
                unit: context.tr('daily_avg'),
                progress: 0.8,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                isDark, cardBg, borderColor,
                icon: LucideIcons.utensils,
                label: 'Calories',
                value: '1,800',
                unit: context.tr('kcal_per_day'),
                progress: 0.72,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark, cardBg, borderColor,
                icon: LucideIcons.footprints,
                label: 'Steps',
                value: '7,432',
                unit: context.tr('avg_per_day'),
                progress: 0.74,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                isDark, cardBg, borderColor,
                icon: LucideIcons.moon,
                label: 'Sleep',
                value: '7.2h',
                unit: context.tr('per_night'),
                progress: 0.9,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    bool isDark,
    Color cardBg,
    Color borderColor, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the circular progress ring
class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}