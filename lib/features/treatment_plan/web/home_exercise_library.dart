import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../data/home_exercise_catalog.dart';
import '../models/treatment_plan.dart';

class HomeExerciseLibrary extends StatefulWidget {
  const HomeExerciseLibrary({super.key});

  @override
  State<HomeExerciseLibrary> createState() => _HomeExerciseLibraryState();
}

class _HomeExerciseLibraryState extends State<HomeExerciseLibrary> {
  final List<HomeExercise> _selected = [];
  String _categoryFilter = 'All';

  List<HomeExercise> get _allExercises => HomeExerciseCatalog.all;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final filtered = _allExercises.where((e) => _categoryFilter == 'All' || e.category == _categoryFilter).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.navy,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('home_exercises'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.surface,
          child: Row(
            children: ['All', 'Cardio', 'Strength', 'Flexibility'].map((cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_categoryLabel(context, cat)),
                selected: _categoryFilter == cat,
                onSelected: (val) => setState(() => _categoryFilter = cat),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final ex = filtered[index];
              final isSelected = _selected.any((e) => e.id == ex.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(ex);
                      } else {
                        _selected.removeWhere((e) => e.id == ex.id);
                      }
                    });
                  },
                  secondary: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(LucideIcons.activity, color: AppColors.primary),
                  ),
                  title: Text(isAr ? ex.nameAr : ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    [
                      context.tr('exercise_duration_format', {
                        'minutes': '${ex.durationMinutes}',
                        'sets': '${ex.sets}',
                        'reps': '${ex.reps}',
                      }),
                      isAr ? ex.descriptionAr : ex.description,
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('exercises_picked_count', {'count': '${_selected.length}'}), style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: Text(context.tr('add_to_plan')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _categoryLabel(BuildContext context, String cat) {
    switch (cat) {
      case 'All':
        return context.tr('filter_all');
      case 'Cardio':
        return context.tr('cardio');
      case 'Strength':
        return context.tr('strength');
      case 'Flexibility':
        return context.tr('flexibility');
      default:
        return cat;
    }
  }
}