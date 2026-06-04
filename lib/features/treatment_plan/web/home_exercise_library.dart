import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../models/treatment_plan.dart';

class HomeExerciseLibrary extends StatefulWidget {
  const HomeExerciseLibrary({super.key});

  @override
  State<HomeExerciseLibrary> createState() => _HomeExerciseLibraryState();
}

class _HomeExerciseLibraryState extends State<HomeExerciseLibrary> {
  final List<HomeExercise> _selected = [];
  String _categoryFilter = 'All';

  final List<HomeExercise> _allExercises = [
    HomeExercise(
      id: 'E1', name: 'Brisk Walking', nameAr: 'مشي سريع', 
      description: 'Walk at a brisk pace.', descriptionAr: 'امش بخطوة سريعة.', 
      category: 'Cardio', durationMinutes: 30, sets: 1, reps: 1, iconPath: 'activity'
    ),
    HomeExercise(
      id: 'E2', name: 'Bodyweight Squats', nameAr: 'قرفصاء بوزن الجسم', 
      description: 'Keep back straight, lower until thighs are parallel.', descriptionAr: 'حافظ على استقامة ظهرك، وانزل حتى يتوازى فخذاك مع الأرض.', 
      category: 'Strength', durationMinutes: 10, sets: 3, reps: 15, iconPath: 'arrow-down'
    ),
    HomeExercise(
      id: 'E3', name: 'Stretching Routine', nameAr: 'روتين إطالة', 
      description: 'Full body stretching.', descriptionAr: 'إطالة لكامل الجسم.', 
      category: 'Flexibility', durationMinutes: 15, sets: 1, reps: 1, iconPath: 'maximize'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
              Text(t.translate('home_exercises'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                label: Text(t.translate(cat.toLowerCase()) != cat.toLowerCase() ? t.translate(cat.toLowerCase()) : cat),
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
                      if (val == true) _selected.add(ex);
                      else _selected.removeWhere((e) => e.id == ex.id);
                    });
                  },
                  secondary: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(LucideIcons.activity, color: AppColors.primary),
                  ),
                  title: Text(isAr ? ex.nameAr : ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${ex.durationMinutes} min • ${ex.sets}x${ex.reps}\n${isAr ? ex.descriptionAr : ex.description}'),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_selected.length} ${t.translate('exercises')} selected', style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('Add to Plan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
