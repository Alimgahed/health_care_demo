import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/utils/dose_utils.dart';
import '../models/treatment_plan.dart';
import 'therapy_center_picker.dart';
import 'home_exercise_library.dart';
import '../../clinical/clinical_eligibility_banner.dart';

class TreatmentPlanBuilder extends StatefulWidget {
  final Patient patient;
  final TreatmentPlan? existingPlan;

  const TreatmentPlanBuilder({super.key, required this.patient, this.existingPlan});

  @override
  State<TreatmentPlanBuilder> createState() => _TreatmentPlanBuilderState();
}

class _TreatmentPlanBuilderState extends State<TreatmentPlanBuilder> {
  int _currentStep = 0;

  String _selectedDose = '2.5 mg';
  int _frequencyDays = 7;

  PhysicalTherapyCenter? _selectedCenter;
  int _totalSessions = 12;

  List<HomeExercise> _selectedExercises = [];

  static const List<int> _frequencyOptions = [7, 14, 30];

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _selectedDose = DoseUtils.toInventoryDose(widget.existingPlan!.medicationDose);
      _frequencyDays = widget.existingPlan!.medicationFrequencyDays;
      _totalSessions = widget.existingPlan!.totalSessions;
      _selectedExercises = List.from(widget.existingPlan!.homeExercises);
    }
  }

  String _frequencyLabel(BuildContext context, int days) {
    switch (days) {
      case 7:
        return context.tr('frequency_weekly');
      case 14:
        return context.tr('frequency_biweekly');
      case 30:
        return context.tr('frequency_monthly');
      default:
        return context.tr('every_n_days', {'n': '$days'});
    }
  }

  bool _willNeedClinicalReview(DataProvider dp) {
    final p = dp.getPatientById(widget.patient.id) ?? widget.patient;
    return p.lastDispensingDate != null &&
        p.isWithinDispensingCooldown(cooldownDays: _frequencyDays);
  }

  void _savePlan(BuildContext context) {
    final live = Provider.of<DataProvider>(context, listen: false).getPatientById(widget.patient.id) ?? widget.patient;
    if (!live.programEligibility.eligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('plan_blocked_ineligible')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final inventoryDose = DoseUtils.toInventoryDose(_selectedDose);
    final needsReview = _willNeedClinicalReview(dataProvider);

    final newPlan = TreatmentPlan(
      id: 'TP-${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patient.id,
      doctorName: 'Dr. Current User',
      createdAt: DateTime.now(),
      medicationDose: inventoryDose,
      medicationFrequencyDays: _frequencyDays,
      reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
      assignedCenterId: _selectedCenter?.id,
      totalSessions: _selectedCenter != null ? _totalSessions : 0,
      sessions: _selectedCenter != null
          ? List.generate(
              _totalSessions,
              (i) => TherapySession(
                id: 'S-${DateTime.now().millisecondsSinceEpoch}-$i',
                sessionNumber: i + 1,
                scheduledDate: DateTime.now().add(Duration(days: (i + 1) * 7)),
              ),
            )
          : [],
      homeExercises: _selectedExercises,
      targetWeight: widget.patient.weight - 10,
    );

    dataProvider.createTreatmentPlan(newPlan);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          needsReview
              ? context.tr('plan_submitted_for_review')
              : context.tr('care_plan_synced'),
        ),
        backgroundColor: needsReview ? AppColors.warning : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final livePatient = dp.getPatientById(widget.patient.id) ?? widget.patient;
    final needsReviewOnSave = _willNeedClinicalReview(dp);
    final ineligible = !livePatient.programEligibility.eligible;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('create_treatment_plan'),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        if (ineligible)
          ClinicalEligibilityBanner(patient: livePatient),
        if (needsReviewOnSave && !ineligible)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.warning.withValues(alpha: 0.12),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('plan_pending_review_banner', {'date': livePatient.lastDispensingDate ?? ''}),
                    style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() => _currentStep++);
              } else {
                _savePlan(context);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              final saveBlocked = ineligible && _currentStep >= 3;
              return Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: saveBlocked ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(_currentStep == 3 ? context.tr('save_plan') : context.tr('next')),
                    ),
                    const SizedBox(width: 16),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(context.tr('back')),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(context.tr('medication_plan')),
                isActive: _currentStep >= 0,
                content: _buildMedicationStep(context),
              ),
              Step(
                title: Text(context.tr('therapy_plan')),
                isActive: _currentStep >= 1,
                content: _buildTherapyStep(context),
              ),
              Step(
                title: Text(context.tr('home_exercises')),
                isActive: _currentStep >= 2,
                content: _buildExercisesStep(context),
              ),
              Step(
                title: Text(context.tr('review_step')),
                isActive: _currentStep >= 3,
                content: _buildReviewStep(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('select_dose'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: DoseUtils.planDoseOptions.map((dose) {
            final display = context.mounjaroDoseLabel(dose);
            final selected = DoseUtils.dosesMatch(_selectedDose, dose);
            return ChoiceChip(
              label: Text(display),
              selected: selected,
              onSelected: (_) => setState(() => _selectedDose = dose),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text(context.tr('injection_frequency'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _frequencyOptions.map((days) {
            final selected = _frequencyDays == days;
            return ChoiceChip(
              label: Text(_frequencyLabel(context, days)),
              selected: selected,
              onSelected: (_) => setState(() => _frequencyDays = days),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTherapyStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCenter != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: AppColors.success),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    context.tr('selected_center', {'name': _selectedCenter!.getLocalizedName(context)}),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedCenter = null),
                  child: Text(context.tr('change')),
                ),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              final center = await showDialog<PhysicalTherapyCenter>(
                context: context,
                builder: (context) => Dialog(
                  child: SizedBox(
                    width: 800,
                    height: 600,
                    child: TherapyCenterPicker(
                      patientLatitude: widget.patient.latitude,
                      patientLongitude: widget.patient.longitude,
                      patientEmirate: widget.patient.getLocalizedEmirate(context),
                    ),
                  ),
                ),
              );
              if (center != null) setState(() => _selectedCenter = center);
            },
            icon: const Icon(LucideIcons.map),
            label: Text(context.tr('assign_center')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        if (_selectedCenter != null) ...[
          const SizedBox(height: 32),
          Text(context.tr('sessions'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Slider(
            value: _totalSessions.toDouble(),
            min: 4,
            max: 24,
            divisions: 20,
            label: '$_totalSessions',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _totalSessions = v.round()),
          ),
        ],
      ],
    );
  }

  Widget _buildExercisesStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final exercises = await showDialog<List<HomeExercise>>(
              context: context,
              builder: (context) => const Dialog(
                child: SizedBox(width: 800, height: 600, child: HomeExerciseLibrary()),
              ),
            );
            if (exercises != null) setState(() => _selectedExercises = exercises);
          },
          icon: const Icon(LucideIcons.plus),
          label: Text(context.tr('home_exercises')),
        ),
        const SizedBox(height: 24),
        ..._selectedExercises.map((e) {
          return ListTile(
            leading: const Icon(LucideIcons.activity),
            title: Text(context.isArabic ? e.nameAr : e.name),
            subtitle: Text(context.tr('exercise_duration_format', {
              'minutes': '${e.durationMinutes}',
              'sets': '${e.sets}',
              'reps': '${e.reps}',
            })),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.error),
              onPressed: () => setState(() => _selectedExercises.remove(e)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('review_treatment_plan'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ListTile(
          title: Text(context.tr('medication_plan')),
          subtitle: Text(context.tr('medication_schedule_line', {
            'dose': context.mounjaroDoseLabel(_selectedDose),
            'days': '$_frequencyDays',
          })),
          leading: const Icon(LucideIcons.pill),
        ),
        ListTile(
          title: Text(context.tr('therapy_plan')),
          subtitle: Text(
            _selectedCenter != null
                ? context.tr('therapy_review_summary', {
                    'center': _selectedCenter!.getLocalizedName(context),
                    'sessions': '$_totalSessions',
                  })
                : context.tr('therapy_review_none'),
          ),
          leading: const Icon(LucideIcons.mapPin),
        ),
        ListTile(
          title: Text(context.tr('home_exercises')),
          subtitle: Text(context.tr('exercises_selected', {'count': '${_selectedExercises.length}'})),
          leading: const Icon(LucideIcons.activity),
        ),
      ],
    );
  }
}
