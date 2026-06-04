import '../models/treatment_plan.dart';

/// Single source of home exercises (library picker + plan display + medical history).
abstract final class HomeExerciseCatalog {
  static final List<HomeExercise> all = [
    HomeExercise(
      id: 'E1',
      name: 'Brisk Walking',
      nameAr: 'مشي سريع',
      description: 'Walk at a brisk pace.',
      descriptionAr: 'امش بخطوة سريعة.',
      category: 'Cardio',
      durationMinutes: 30,
      sets: 1,
      reps: 1,
      iconPath: 'activity',
    ),
    HomeExercise(
      id: 'E2',
      name: 'Bodyweight Squats',
      nameAr: 'قرفصاء بوزن الجسم',
      description: 'Keep back straight, lower until thighs are parallel.',
      descriptionAr: 'حافظ على استقامة ظهرك، وانزل حتى يتوازى فخذاك مع الأرض.',
      category: 'Strength',
      durationMinutes: 10,
      sets: 3,
      reps: 15,
      iconPath: 'arrow-down',
    ),
    HomeExercise(
      id: 'E3',
      name: 'Stretching Routine',
      nameAr: 'روتين إطالة',
      description: 'Full body stretching.',
      descriptionAr: 'إطالة لكامل الجسم.',
      category: 'Flexibility',
      durationMinutes: 15,
      sets: 1,
      reps: 1,
      iconPath: 'maximize',
    ),
    HomeExercise(
      id: 'E4',
      name: 'Light Yoga',
      nameAr: 'يوغا خفيفة',
      description: 'Gentle yoga flow for mobility.',
      descriptionAr: 'تدفق يوغا لطيف للحركة.',
      category: 'Flexibility',
      durationMinutes: 20,
      sets: 1,
      reps: 1,
      iconPath: 'activity',
    ),
    HomeExercise(
      id: 'E5',
      name: 'Core Strengthening',
      nameAr: 'تقوية العضلات الأساسية',
      description: 'Planks and controlled core work.',
      descriptionAr: 'بلانك وتمارين أساسية مضبوطة.',
      category: 'Strength',
      durationMinutes: 15,
      sets: 3,
      reps: 10,
      iconPath: 'activity',
    ),
  ];

  static HomeExercise? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Prefer catalog labels; fall back to values stored on the care plan.
  static HomeExercise resolve(HomeExercise fromPlan) {
    final master = byId(fromPlan.id);
    if (master == null) return fromPlan;
    return HomeExercise(
      id: fromPlan.id,
      name: master.name,
      nameAr: master.nameAr,
      description: master.description,
      descriptionAr: master.descriptionAr,
      category: master.category,
      durationMinutes: fromPlan.durationMinutes,
      sets: fromPlan.sets,
      reps: fromPlan.reps,
      iconPath: master.iconPath,
      completedDates: fromPlan.completedDates,
    );
  }

  static String displayName(HomeExercise e, bool isArabic) =>
      isArabic ? e.nameAr : e.name;

  /// All exercises assigned on any care plan for this beneficiary (deduped by id).
  static List<HomeExercise> forPatientPlans(Iterable<TreatmentPlan> plans, String patientId) {
    final seen = <String>{};
    final out = <HomeExercise>[];
    for (final plan in plans) {
      if (plan.patientId != patientId) continue;
      for (final ex in plan.homeExercises) {
        if (seen.add(ex.id)) {
          out.add(resolve(ex));
        }
      }
    }
    return out;
  }
}
