
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import '../data/home_exercise_catalog.dart';

class WebPlanExercisesView extends StatefulWidget {
  final Patient patient;

  const WebPlanExercisesView({super.key, required this.patient});

  @override
  State<WebPlanExercisesView> createState() => _WebPlanExercisesViewState();
}

class _WebPlanExercisesViewState extends State<WebPlanExercisesView> {
  final Set<String> _completedToday = {};
  final Set<int> _activeDays = {0, 1, 2, 3}; 
  final List<String> _weekDays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
  final int _streakDays = 4;
  
  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';
  String? _hoveredExerciseId;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final plan = provider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return Center(
        child: Text(
          context.tr('no_treatment_plan_mobile'),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final resolvedExercises = plan.homeExercises.map((e) => HomeExerciseCatalog.resolve(e)).toList();
    final int totalMinutes = resolvedExercises.fold(0, (s, e) => s + e.durationMinutes);
    final double todayProgress = resolvedExercises.isEmpty ? 0 : _completedToday.length / resolvedExercises.length;

    // Filter Logic
    final filteredExercises = resolvedExercises.where((e) {
      final matchesCategory = _selectedCategoryFilter == 'all' || e.category.toLowerCase() == _selectedCategoryFilter.toLowerCase();
      final displayName = HomeExerciseCatalog.displayName(e, isAr).toLowerCase();
      return matchesCategory && displayName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Header Section
            _buildWebHeader(context, resolvedExercises.length, totalMinutes),
            const SizedBox(height: 32),

            // 2. High-Density SaaS Metric Matrix Rows (Fills out empty wide space)
            _buildMetricGridBlock(context, resolvedExercises.length, totalMinutes, isDark),
            const SizedBox(height: 40),

            // 3. Two-Column Dashboard Frame Workspace
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left dynamic content panel (7/11 structural scale ratio)
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchAndFilterBlock(context, isDark),
                      const SizedBox(height: 28),
                      if (filteredExercises.isEmpty)
                        _buildEmptySearchState(context, isDark)
                      else
                        _buildExercisesSaaSGrid(context, filteredExercises, isAr, isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 40),

                // Right static sidebar panel (4/11 structural scale ratio)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildStreakMatrixCard(context, isDark, todayProgress, totalMinutes),
                      const SizedBox(height: 24),
                      _buildWeeklyActivityCard(context, isDark),
                      const SizedBox(height: 24),
                      _buildMedicalAdvisoryCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context, int total, int minutes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Icon(LucideIcons.dumbbell, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التمارين العلاجية الذكية',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'متابعة وإدارة الأنشطة والتمارين المنزلية المحددة للمستفيد الحالي بانتظام',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricGridBlock(BuildContext context, int total, int minutes, bool isDark) {
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Row(
      children: [
        _metricTile('التمارين المنجزة اليوم', '${_completedToday.length} / $total', LucideIcons.checkCircle2, AppColors.success, bg, border),
        const SizedBox(width: 20),
        _metricTile('إجمالي الدقائق المجدولة', '$minutes دقيقة', LucideIcons.hourglass, AppColors.info, bg, border),
        const SizedBox(width: 20),
        _metricTile('الطاقة المستهلكة المتوقعة', '${(minutes * 5.8).toInt()} سعرة', LucideIcons.sparkles, AppColors.accent, bg, border),
        const SizedBox(width: 20),
        _metricTile('مستوى الالتزام العام', 'مستقر وممتاز', LucideIcons.shieldCheck, AppColors.primaryLight, bg, border),
      ],
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color, Color bg, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBlock(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'البحث السريع عن التمارين المسندة في الخطة...',
                      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSaaSCategoryFilterChips(isDark),
        ],
      ),
    );
  }

  Widget _buildSaaSCategoryFilterChips(bool isDark) {
    final categories = [
      {'id': 'all', 'label': 'جميع التمارين المسندة', 'icon': LucideIcons.layoutGrid},
      {'id': 'strength', 'label': 'تقوية العضلات', 'icon': LucideIcons.dumbbell},
      {'id': 'cardio', 'label': 'تمارين كارديو', 'icon': LucideIcons.heartPulse},
      {'id': 'flexibility', 'label': 'مرونة وإطالة عضلية', 'icon': LucideIcons.activity},
    ];

    return Row(
      children: categories.map((cat) {
        final isSelected = _selectedCategoryFilter == cat['id'];
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: ChoiceChip(
            label: Row(
              children: [
                Icon(cat['icon'] as IconData, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(cat['label'] as String),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) => setState(() => _selectedCategoryFilter = cat['id'] as String),
            selectedColor: AppColors.primary,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: isSelected ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExercisesSaaSGrid(BuildContext context, List<HomeExercise> exercises, bool isAr, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 220,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (context, idx) {
        final exercise = exercises[idx];
        final isCompleted = _completedToday.contains(exercise.id);
        final color = _categoryColor(exercise.category);
        final isHovered = _hoveredExerciseId == exercise.id;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredExerciseId = exercise.id),
          onExit: (_) => setState(() => _hoveredExerciseId = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success.withValues(alpha: 0.02) : (isDark ? AppColors.darkSurface : AppColors.surface),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCompleted 
                    ? AppColors.success.withValues(alpha: 0.4) 
                    : isHovered ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7)),
                width: isCompleted || isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.01),
                  blurRadius: isHovered ? 24 : 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                      child: Icon(_exerciseIcon(exercise.category), color: color, size: 20),
                    ),
                    _badgeIndicator(exercise.category),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HomeExerciseCatalog.displayName(exercise, isAr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.success : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _smallChip(LucideIcons.clock, '${exercise.durationMinutes} دق', AppColors.info),
                          if (exercise.sets > 1) _smallChip(LucideIcons.repeat, '${exercise.sets} مجموعات', AppColors.primaryLight),
                          if (exercise.reps > 1) _smallChip(LucideIcons.zap, '${exercise.reps} تكرار', AppColors.accent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.video, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('فيديو توضيحي متوفر', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12)),
                      ],
                    ),
                    IconButton.filled(
                      onPressed: () => setState(() {
                        if (isCompleted) _completedToday.remove(exercise.id);
                        else _completedToday.add(exercise.id);
                      }),
                      icon: Icon(isCompleted ? LucideIcons.check : LucideIcons.play, size: 14, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: isCompleted ? AppColors.success : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badgeIndicator(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        _categoryLabel(category),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _smallChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStreakMatrixCard(BuildContext context, bool isDark, double progress, int totalMinutes) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(LucideIcons.flame, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('معدل الالتزام المستمر', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$_streakDays', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Text('أيام متتالية', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('معدل إنجاز خطة اليوم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppColors.success : AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('النشاط الإجمالي الأسبوعي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              Text('${_activeDays.length}/7 أيام نشطة', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isActive = _activeDays.contains(i);
              final isToday = i == DateTime.now().weekday % 7;
              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : isToday ? AppColors.accent.withValues(alpha: 0.15) : (isDark ? AppColors.darkBackground : AppColors.background),
                      shape: BoxShape.circle,
                      border: Border.all(color: isToday ? AppColors.accent : Colors.transparent, width: 1.5),
                    ),
                    child: Center(
                      child: isActive
                          ? Icon(Icons.check, color: AppColors.accent, size: 14)
                          : Text(_weekDays[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isToday ? AppColors.accent : AppColors.textSecondary)),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalAdvisoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(LucideIcons.lightbulb, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('توجيهات فنية هامة', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'يرجى عدم تخطي جولات الإحماء العضلي، والتأكد من أداء حركة المفاصل بصورة آمنة ومريحة وفقاً لتعليمات الطبيب المعالج.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.searchX, size: 44, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('لم نجد أي تمارين تطابق خيارات البحث الحالية في لوحة المستفيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'cardio': return AppColors.error;
      case 'strength': return AppColors.primaryLight;
      case 'flexibility': return AppColors.info;
      default: return AppColors.accent;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'cardio': return LucideIcons.heartPulse;
      case 'strength': return LucideIcons.dumbbell;
      case 'flexibility': return LucideIcons.activity;
      default: return LucideIcons.zap;
    }
  }

  IconData _exerciseIcon(String cat) => _categoryIcon(cat);

  String _categoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'cardio': return 'كارديو';
      case 'strength': return 'تقوية عضلية';
      case 'flexibility': return 'إطالة ومرونة';
      default: return cat;
    }
  }
}