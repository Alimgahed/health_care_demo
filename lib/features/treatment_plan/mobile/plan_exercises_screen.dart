import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import '../data/home_exercise_catalog.dart';

class PlanExercisesScreen extends StatefulWidget {
  final Patient patient;

  const PlanExercisesScreen({super.key, required this.patient});

  @override
  State<PlanExercisesScreen> createState() => _PlanExercisesScreenState();
}

class _PlanExercisesScreenState extends State<PlanExercisesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  final Set<String> _completedToday = {};

  // Weekly days — S M T W T F S aligned to today
  List<String> get _weekDays => context.tr('exercise_week_days').split(',');
  final Set<int> _activeDays = {0, 1, 2, 3}; // Mocked: last 4 days done

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final plan = provider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.dumbbell, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(context.tr('no_treatment_plan_mobile'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final resolvedExercises =
        plan.homeExercises.map((e) => HomeExerciseCatalog.resolve(e)).toList();
    final int totalMinutes =
        resolvedExercises.fold(0, (sum, e) => sum + e.durationMinutes);
    final int streakDays = 4;
    final int completedCount = _completedToday.length;
    final double todayProgress =
        resolvedExercises.isEmpty ? 0 : completedCount / resolvedExercises.length;

    // Group by category
    final Map<String, List<HomeExercise>> byCategory = {};
    for (final e in resolvedExercises) {
      byCategory.putIfAbsent(e.category, () => []).add(e);
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Header ──────────────────────────────────────────────────
            Text(
              context.tr('nav_exercises'),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text('$totalMinutes دقيقة إجمالية • ${resolvedExercises.length} تمارين',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),

            // ── Streak Hero Card ─────────────────────────────────────────
            _buildStreakCard(context, streakDays),
            const SizedBox(height: 16),

            // ── Weekly Activity ──────────────────────────────────────────
            _buildWeeklyActivity(context),
            const SizedBox(height: 24),

            // ── Today's Progress ─────────────────────────────────────────
            _buildTodayProgress(context, completedCount, resolvedExercises.length, todayProgress, totalMinutes),
            const SizedBox(height: 24),

            // ── Exercises by Category ────────────────────────────────────
            ...byCategory.entries.map((entry) => _buildCategorySection(
                context, entry.key, entry.value, isAr, plan)),

            // ── Motivational Tip ─────────────────────────────────────────
            _buildTip(context),
          ],
        ),
      ),
    );
  }

  // ── Streak Hero Card ─────────────────────────────────────────────────────────
  Widget _buildStreakCard(BuildContext context, int streakDays) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Row(
            children: [
              // Flame icon with glow
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 12)
                    ]),
                child:
                    const Icon(LucideIcons.flame, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('exercise_streak_title'),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$streakDays',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                                letterSpacing: -2)),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 6),
                          child: Text(context.tr('exercise_streak_unit'),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('🏆 أفضل من 78% من المرضى!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Weekly Activity Dots ─────────────────────────────────────────────────────
  Widget _buildWeeklyActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('exercise_week_activity'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              Text('${_activeDays.length}/7 أيام',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isActive = _activeDays.contains(i);
              final isToday = i == DateTime.now().weekday % 7;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success
                          : isToday
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.border.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.4),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(_weekDays[i],
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Today's Progress ─────────────────────────────────────────────────────────
  Widget _buildTodayProgress(BuildContext context, int completed, int total,
      double progress, int totalMinutes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: progress >= 1.0
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
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
                  Text(context.tr('exercise_today_title'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                      progress >= 1.0
                          ? '🎉 أنجزت كل تمارينك!'
                          : '$completed من $total تمارين مكتملة',
                      style: TextStyle(
                          color: progress >= 1.0
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              // Calorie estimate
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.flame, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('~${(totalMinutes * 5.5).toInt()} سعرة',
                        style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppColors.success : AppColors.primary),
            ),
          ),
          if (progress > 0 && progress < 1.0) ...[
            const SizedBox(height: 8),
            Text(
                context.tr('exercise_remaining')
                    .replaceAll('{remaining}', '${total - completed}')
                    .replaceAll('{minutes}', '${totalMinutes - (completed * (totalMinutes ~/ total.clamp(1, 999)))}'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  // ── Category Section ─────────────────────────────────────────────────────────
  Widget _buildCategorySection(BuildContext context, String category,
      List<HomeExercise> exercises, bool isAr, TreatmentPlan plan) {
    final Color catColor = _categoryColor(category);
    final IconData catIcon = _categoryIcon(category);
    final String catLabel = _categoryLabel(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(catIcon, color: catColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(catLabel,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            Text('${exercises.length} تمارين',
                style: TextStyle(
                    color: catColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...exercises.map(
            (e) => _buildExerciseCard(context, e, isAr, catColor, plan)),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Exercise Card ────────────────────────────────────────────────────────────
  Widget _buildExerciseCard(BuildContext context, HomeExercise exercise,
      bool isAr, Color catColor, TreatmentPlan plan) {
    final isCompleted = _completedToday.contains(exercise.id);
    final name = HomeExerciseCatalog.displayName(
        HomeExerciseCatalog.resolve(exercise), isAr);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.08)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showExerciseDetail(context, exercise, isAr, catColor, plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon box
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.15)
                      : catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted ? LucideIcons.checkCircle : _exerciseIcon(exercise.category),
                  color: isCompleted ? AppColors.success : catColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCompleted
                                ? AppColors.success
                                : Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(LucideIcons.clock, '${exercise.durationMinutes} دق', AppColors.info),
                        if (exercise.sets > 1) _chip(LucideIcons.repeat, '${exercise.sets} مج', catColor),
                        if (exercise.reps > 1) _chip(LucideIcons.zap, '${exercise.reps} تك', AppColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action button
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isCompleted) {
                      _completedToday.remove(exercise.id);
                    } else {
                      _completedToday.add(exercise.id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : catColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: (isCompleted ? AppColors.success : catColor)
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Icon(
                    isCompleted ? LucideIcons.check : LucideIcons.play,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Exercise Detail Bottom Sheet ─────────────────────────────────────────────
  void _showExerciseDetail(BuildContext context, HomeExercise exercise, bool isAr,
      Color catColor, TreatmentPlan plan) {
    final resolved = HomeExerciseCatalog.resolve(exercise);
    final name = HomeExerciseCatalog.displayName(resolved, isAr);
    final desc = isAr ? resolved.descriptionAr : resolved.description;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_exerciseIcon(resolved.category), color: catColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface)),
                                Text(_categoryLabel(resolved.category),
                                    style: TextStyle(color: catColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      Row(
                        children: [
                          _detailStat(context, '${resolved.durationMinutes}', 'دقيقة', LucideIcons.clock, AppColors.info),
                          const SizedBox(width: 12),
                          _detailStat(context, '${resolved.sets}', 'مجموعات', LucideIcons.repeat, catColor),
                          const SizedBox(width: 12),
                          _detailStat(context, '${resolved.reps}', 'تكرارات', LucideIcons.zap, AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(context.tr('exercise_description'),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(desc,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.6)),
                      ),
                      const SizedBox(height: 24),

                      // Tips
                      Text(context.tr('exercise_tips'),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      _tipRow(context.tr('exercise_tip_1')),
                      _tipRow(context.tr('exercise_tip_2')),
                      _tipRow(context.tr('exercise_tip_3')),
                      const SizedBox(height: 24),

                      // Mark Done Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _completedToday.add(exercise.id));
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(LucideIcons.checkCircle),
                          label: Text(context.tr('exercise_mark_done')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: catColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailStat(BuildContext context, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 12, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(tip, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  // ── Motivational Tip ─────────────────────────────────────────────────────────
  Widget _buildTip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.lightbulb, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('exercise_daily_tip_title'),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  context.tr('exercise_daily_tip_body'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cardio': return AppColors.error;
      case 'strength': return AppColors.primary;
      case 'flexibility': return AppColors.info;
      default: return AppColors.accent;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio': return LucideIcons.heartPulse;
      case 'strength': return LucideIcons.dumbbell;
      case 'flexibility': return LucideIcons.activity;
      default: return LucideIcons.zap;
    }
  }

  IconData _exerciseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio': return LucideIcons.heartPulse;
      case 'strength': return LucideIcons.dumbbell;
      case 'flexibility': return LucideIcons.activity;
      default: return LucideIcons.zap;
    }
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'cardio': return 'كارديو';
      case 'strength': return 'تقوية العضلات';
      case 'flexibility': return 'مرونة وإطالة';
      default: return category;
    }
  }
}
