import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import 'therapy_center_picker.dart';
import 'home_exercise_library.dart';

class TreatmentPlanBuilder extends StatefulWidget {
  final Patient patient;
  final TreatmentPlan? existingPlan;

  const TreatmentPlanBuilder({super.key, required this.patient, this.existingPlan});

  @override
  State<TreatmentPlanBuilder> createState() => _TreatmentPlanBuilderState();
}

class _TreatmentPlanBuilderState extends State<TreatmentPlanBuilder> {
  int _currentStep = 0;
  
  // Step 1
  String _selectedDose = '2.5 mg';
  int _frequencyDays = 7;
  
  // Step 2
  PhysicalTherapyCenter? _selectedCenter;
  int _totalSessions = 12;
  
  // Step 3
  List<HomeExercise> _selectedExercises = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _selectedDose = widget.existingPlan!.medicationDose;
      _frequencyDays = widget.existingPlan!.medicationFrequencyDays;
      _totalSessions = widget.existingPlan!.totalSessions;
      _selectedExercises = widget.existingPlan!.homeExercises;
      // We'd also look up the center here. For brevity, skipping.
    }
  }

  void _savePlan(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    final newPlan = TreatmentPlan(
      id: 'TP-${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patient.id,
      doctorName: 'Dr. Current User', // Mocked
      createdAt: DateTime.now(),
      medicationDose: _selectedDose,
      medicationFrequencyDays: _frequencyDays,
      reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
      assignedCenterId: _selectedCenter?.id,
      totalSessions: _selectedCenter != null ? _totalSessions : 0,
      sessions: _selectedCenter != null ? List.generate(_totalSessions, (i) => TherapySession(
        id: 'S-${DateTime.now().millisecondsSinceEpoch}-$i',
        sessionNumber: i + 1,
        scheduledDate: DateTime.now().add(Duration(days: (i + 1) * 7)),
      )) : [],
      homeExercises: _selectedExercises,
      targetWeight: widget.patient.weight - 10, // Just a simple mock target
    );
    
    dataProvider.createTreatmentPlan(newPlan);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.translate('save_plan') + ' ✓')));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.translate('create_treatment_plan'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        
        Expanded(
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 3) setState(() => _currentStep++);
              else _savePlan(context);
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(_currentStep == 3 ? t.translate('save_plan') : 'Next'),
                    ),
                    const SizedBox(width: 16),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(t.translate('medication_plan')),
                isActive: _currentStep >= 0,
                content: _buildMedicationStep(t),
              ),
              Step(
                title: Text(t.translate('therapy_plan')),
                isActive: _currentStep >= 1,
                content: _buildTherapyStep(t),
              ),
              Step(
                title: Text(t.translate('home_exercises')),
                isActive: _currentStep >= 2,
                content: _buildExercisesStep(t),
              ),
              Step(
                title: const Text('Review'),
                isActive: _currentStep >= 3,
                content: _buildReviewStep(t),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.translate('select_dose'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          children: ['2.5 mg', '5.0 mg', '7.5 mg', '10.0 mg'].map((dose) => ChoiceChip(
            label: Text(dose),
            selected: _selectedDose == dose,
            onSelected: (val) => setState(() => _selectedDose = dose),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: _selectedDose == dose ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.bold),
          )).toList(),
        ),
        const SizedBox(height: 32),
        Text(t.translate('injection_frequency'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Slider(
          value: _frequencyDays.toDouble(),
          min: 7,
          max: 14,
          divisions: 1,
          label: '$_frequencyDays Days',
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _frequencyDays = val.toInt()),
        ),
      ],
    );
  }

  Widget _buildTherapyStep(AppLocalizations t) {
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
                Expanded(child: Text('Selected: ${_selectedCenter!.getLocalizedName(context)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                TextButton(
                  onPressed: () => setState(() => _selectedCenter = null),
                  child: const Text('Change'),
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
                  child: SizedBox(width: 800, height: 600, child: TherapyCenterPicker(patientEmirate: widget.patient.emirate)),
                ),
              );
              if (center != null) {
                setState(() => _selectedCenter = center);
              }
            },
            icon: const Icon(LucideIcons.map),
            label: Text(t.translate('assign_center')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          
        if (_selectedCenter != null) ...[
          const SizedBox(height: 32),
          Text(t.translate('sessions'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Slider(
            value: _totalSessions.toDouble(),
            min: 4,
            max: 24,
            divisions: 20,
            label: '$_totalSessions Sessions',
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _totalSessions = val.toInt()),
          ),
        ]
      ],
    );
  }

  Widget _buildExercisesStep(AppLocalizations t) {
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
            if (exercises != null) {
              setState(() => _selectedExercises = exercises);
            }
          },
          icon: const Icon(LucideIcons.plus),
          label: Text(t.translate('home_exercises')),
        ),
        const SizedBox(height: 24),
        ..._selectedExercises.map((e) => ListTile(
          leading: const Icon(LucideIcons.activity),
          title: Text(e.name),
          subtitle: Text('${e.durationMinutes} min • ${e.sets}x${e.reps}'),
          trailing: IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.error),
            onPressed: () => setState(() => _selectedExercises.remove(e)),
          ),
        )),
      ],
    );
  }

  Widget _buildReviewStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Treatment Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ListTile(
          title: Text(t.translate('medication_plan')),
          subtitle: Text('$_selectedDose every $_frequencyDays days'),
          leading: const Icon(LucideIcons.pill),
        ),
        ListTile(
          title: Text(t.translate('therapy_plan')),
          subtitle: Text(_selectedCenter != null ? '${_selectedCenter!.name} • $_totalSessions sessions' : 'None'),
          leading: const Icon(LucideIcons.mapPin),
        ),
        ListTile(
          title: Text(t.translate('home_exercises')),
          subtitle: Text('${_selectedExercises.length} exercises selected'),
          leading: const Icon(LucideIcons.activity),
        ),
      ],
    );
  }
}
