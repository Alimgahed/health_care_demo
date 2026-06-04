import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../data/home_exercise_catalog.dart';
import '../models/treatment_plan.dart';

class HomeExercisesScreen extends StatelessWidget {
  final TreatmentPlan plan;

  const HomeExercisesScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('home_exercises')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: plan.homeExercises.length,
        itemBuilder: (context, index) {
          final ex = HomeExerciseCatalog.resolve(plan.homeExercises[index]);
          final isCompletedToday = ex.completedDates.any((d) => 
            d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isCompletedToday ? AppColors.success : AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.activity, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAr ? ex.nameAr : ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(context.tr('exercise_duration_format', {
                              'minutes': '${ex.durationMinutes}',
                              'sets': '${ex.sets}',
                              'reps': '${ex.reps}',
                            })),
                          ],
                        ),
                      ),
                      if (isCompletedToday)
                        const Icon(LucideIcons.checkCircle, color: AppColors.success)
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(isAr ? ex.descriptionAr : ex.description, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  if (!isCompletedToday)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final provider = Provider.of<DataProvider>(context, listen: false);
                          provider.completeExercise(plan.id, ex.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('success'))));
                        },
                        icon: const Icon(LucideIcons.check),
                        label: Text(context.tr('mark_complete')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
