import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../data/home_exercise_catalog.dart';
import '../models/treatment_plan.dart';
import '../../clinical/ai_decision_support_card.dart';
import '../../clinical/clinical_eligibility_banner.dart';
import 'treatment_plan_builder.dart';

class Patient360View extends StatefulWidget {
  final Patient patient;

  const Patient360View({super.key, required this.patient});

  @override
  State<Patient360View> createState() => _Patient360ViewState();
}

class _Patient360ViewState extends State<Patient360View> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Patient _livePatient(DataProvider dp) => dp.getPatientById(widget.patient.id) ?? widget.patient;

  List<HomeExercise> _patientExercises(DataProvider dp) =>
      HomeExerciseCatalog.forPatientPlans(dp.treatmentPlans, widget.patient.id);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final patient = _livePatient(dataProvider);
    final activePlan = dataProvider.treatmentPlans.cast<TreatmentPlan?>().firstWhere(
      (p) => p?.patientId == patient.id && p?.status == 'Active',
      orElse: () => null,
    );
    final exercises = _patientExercises(dataProvider);

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.navy,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  child: Text(
                    patient.getLocalizedFullName(context).substring(0, 1),
                    style: TextStyle(fontSize: 32, color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.getLocalizedFullName(context),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildHeaderBadge(LucideIcons.hash, patient.emiratesId),
                          const SizedBox(width: 16),
                          _buildHeaderBadge(LucideIcons.user, '${patient.age} ${context.tr('age')}'),
                          const SizedBox(width: 16),
                          _buildHeaderBadge(LucideIcons.mapPin, patient.getLocalizedEmirate(context)),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: const EdgeInsets.all(24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: SizedBox(
                          width: 900,
                          height: 700,
                          child: TreatmentPlanBuilder(patient: patient, existingPlan: activePlan),
                        ),
                      ),
                    );
                  },
                  icon: Icon(activePlan == null ? LucideIcons.plusCircle : LucideIcons.edit),
                  label: Text(activePlan == null ? context.tr('create_treatment_plan') : context.tr('edit_plan')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: context.tr('overview')),
              Tab(text: context.tr('treatment_plan')),
              Tab(text: context.tr('medical_history')),
              Tab(text: context.tr('activity_log')),
            ],
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, patient, exercises),
                _buildTreatmentPlanTab(context, activePlan, dataProvider),
                _buildMedicalHistoryTab(context, patient, dataProvider, exercises),
                _buildActivityLogTab(context, dataProvider, patient),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Patient patient, List<HomeExercise> exercises) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AiDecisionSupportCard(patient: patient),
          // const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildMetricCard(context.tr('weight'), '${patient.weight} kg', LucideIcons.activity, AppColors.primary)),
              const SizedBox(width: 24),
              Expanded(child: _buildMetricCard(context.tr('bmi'), patient.bmi.toStringAsFixed(1), LucideIcons.activitySquare, patient.bmi >= 35.0 ? AppColors.error : AppColors.warning)),
              const SizedBox(width: 24),
              Expanded(child: _buildMetricCard(context.tr('compliance_score'), '${(patient.complianceRate * 100).toInt()}%', LucideIcons.checkCircle, AppColors.success)),
            ],
          ),
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: 28),
            _buildExerciseListSection(context, exercises),
          ],
          const SizedBox(height: 32),
          Text(context.tr('bmi_trend'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: patient.weightHistory.asMap().entries.map((e) {
                      double bmi = e.value / ((patient.height / 100) * (patient.height / 100));
                      return FlSpot(e.key.toDouble(), bmi);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlanTab(BuildContext context, TreatmentPlan? plan, DataProvider provider) {
    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(context.tr('no_active_plan'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.clinicalApprovalStatus == 'pending_review')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('care_plan_status_pending'),
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          _buildPlanSection(context.tr('medication_plan'), [
            _buildPlanRow(LucideIcons.pill, context.tr('select_dose'), context.mounjaroDoseLabel(plan.medicationDose)),
            _buildPlanRow(LucideIcons.clock, context.tr('injection_frequency'), context.tr('every_n_days', {'n': '${plan.medicationFrequencyDays}'})),
          ]),
          const SizedBox(height: 32),
          _buildPlanSection(context.tr('therapy_plan'), [
            _buildPlanRow(
              LucideIcons.mapPin,
              context.tr('therapy_center'),
              plan.assignedCenterId == null
                  ? context.tr('not_assigned')
                  : provider.therapyCenterLabel(context, plan.assignedCenterId),
            ),
            if (plan.assignedCenterId != null)
              _buildPlanRow(
                LucideIcons.map,
                context.tr('region'),
                provider.getTherapyCenterById(plan.assignedCenterId)?.getLocalizedEmirate(context) ?? '',
              ),
            _buildPlanRow(
              LucideIcons.calendar,
              context.tr('sessions'),
              '${plan.sessions.where((s) => s.isAttended).length} / ${plan.totalSessions} ${context.tr('completed')}',
            ),
          ]),
          const SizedBox(height: 32),
          _buildPlanSection(
            context.tr('home_exercises'),
            plan.homeExercises.map((e) {
              final resolved = HomeExerciseCatalog.resolve(e);
              return _buildPlanRow(
                LucideIcons.activity,
                HomeExerciseCatalog.displayName(resolved, context.isArabic),
                context.tr('exercise_duration_format', {
                  'minutes': '${resolved.durationMinutes}',
                  'sets': '${resolved.sets}',
                  'reps': '${resolved.reps}',
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlanRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: AppColors.textSecondary))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String label, String value, {IconData icon = LucideIcons.circle}) {
    return _buildPlanRow(icon, label, value);
  }

  Widget _buildExerciseListSection(BuildContext context, List<HomeExercise> exercises) {
    final isAr = context.isArabic;
    return _buildPlanSection(
      context.tr('assigned_home_exercises'),
      exercises.map((e) {
        final resolved = HomeExerciseCatalog.resolve(e);
        final completed = resolved.completedDates.length;
        return _buildPlanRow(
          LucideIcons.dumbbell,
          HomeExerciseCatalog.displayName(resolved, isAr),
          completed > 0
              ? context.tr('exercise_with_completions', {
                  'detail': context.tr('exercise_duration_format', {
                    'minutes': '${resolved.durationMinutes}',
                    'sets': '${resolved.sets}',
                    'reps': '${resolved.reps}',
                  }),
                  'count': '$completed',
                })
              : context.tr('exercise_duration_format', {
                  'minutes': '${resolved.durationMinutes}',
                  'sets': '${resolved.sets}',
                  'reps': '${resolved.reps}',
                }),
        );
      }).toList(),
    );
  }

  Widget _buildMedicalHistoryTab(
    BuildContext context,
    Patient patient,
    DataProvider provider,
    List<HomeExercise> exercises,
  ) {
    final plan = provider.treatmentPlans.cast<TreatmentPlan?>().firstWhere(
          (p) => p?.patientId == patient.id && p?.status == 'Active',
          orElse: () => null,
        );
    final conditions = patient.getLocalizedMedicalConditions(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClinicalEligibilityBanner(patient: patient),
          const SizedBox(height: 8),
          _buildPlanSection(context.tr('demographics_section'), [
            _buildHistoryRow(context.tr('full_name'), patient.getLocalizedFullName(context), icon: LucideIcons.user),
            _buildHistoryRow(context.tr('emirates_id'), patient.emiratesId, icon: LucideIcons.hash),
            _buildHistoryRow('${context.tr('age')} / ${context.tr('gender')}', '${patient.age} · ${patient.getLocalizedGender(context)}'),
            _buildHistoryRow(context.tr('nationality'), patient.getLocalizedNationality(context), icon: LucideIcons.globe),
            _buildHistoryRow(context.tr('residency_status'), patient.getLocalizedResidency(context)),
            _buildHistoryRow(context.tr('region'), patient.getLocalizedEmirate(context), icon: LucideIcons.mapPin),
          ]),
          const SizedBox(height: 24),
          _buildPlanSection(context.tr('clinical_assessment'), [
            _buildHistoryRow(context.tr('weight'), '${patient.weight.toStringAsFixed(1)} kg', icon: LucideIcons.scale),
            _buildHistoryRow(context.tr('height_cm'), '${patient.height.toStringAsFixed(0)} cm'),
            _buildHistoryRow(context.tr('col_bmi'), patient.bmi.toStringAsFixed(1), icon: LucideIcons.activity),
            _buildHistoryRow(
              context.tr('has_chronic_disease'),
              patient.hasChronicDisease ? context.tr('yes') : context.tr('no'),
            ),
            _buildHistoryRow(
              context.tr('hba1c_label'),
              patient.hba1cPercent != null ? '${patient.hba1cPercent!.toStringAsFixed(1)}%' : context.tr('not_recorded'),
            ),
            _buildHistoryRow(
              context.tr('fasting_glucose_label'),
              patient.fastingGlucoseMgDl != null
                  ? '${patient.fastingGlucoseMgDl!.toStringAsFixed(0)} mg/dL'
                  : context.tr('not_recorded'),
            ),
            _buildHistoryRow(
              context.tr('compliance_score'),
              '${(patient.complianceRate * 100).toInt()}%',
              icon: LucideIcons.checkCircle,
            ),
          ]),
          const SizedBox(height: 24),
          _buildPlanSection(context.tr('chronic_conditions_section'), [
            if (conditions.isEmpty)
              _buildHistoryRow(context.tr('condition_field'), context.tr('none_reported'))
            else
              ...conditions.map((c) => _buildHistoryRow(context.tr('condition_field'), c, icon: LucideIcons.heartPulse)),
          ]),
          const SizedBox(height: 24),
          _buildPlanSection(context.tr('medication_history_section'), [
            _buildHistoryRow(
              patient.lastDispensingDate == null
                  ? context.tr('prescribed_dose_plan')
                  : context.tr('active_prescription'),
              context.mounjaroDoseLabel(patient.currentDose),
              icon: LucideIcons.pill,
            ),
            _buildHistoryRow(
              context.tr('last_dispense_date'),
              patient.lastDispensingDate ?? context.tr('never_dispensed'),
              icon: LucideIcons.package,
            ),
            if (patient.lastDispensingCenterId != null)
              _buildHistoryRow(
                context.tr('last_dispensing_facility'),
                provider.dispensingFacilityLabel(context, patient.lastDispensingCenterId),
                icon: LucideIcons.building2,
              ),
            if (patient.dispenseRecords.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...patient.dispenseRecords.reversed.map((r) {
                return _buildHistoryRow(
                  context.tr('dispensing_facility'),
                  context.tr('dispense_record_line', {
                    'date': r.date,
                    'dose': context.mounjaroDoseLabel(r.dose),
                    'facility': provider.dispensingFacilityLabel(context, r.centerId),
                  }),
                  icon: LucideIcons.package,
                );
              }),
            ],
            _buildHistoryRow(
              context.tr('next_dispense_eligible'),
              patient.nextEligibleDate ?? context.tr('now'),
            ),
            _buildHistoryRow(
              context.tr('dose_history'),
              patient.doseHistory.isNotEmpty
                  ? patient.doseHistory.join(' → ')
                  : context.tr('no_dispense_history'),
            ),
            if (plan != null)
              _buildHistoryRow(
                context.tr('injection_interval'),
                context.tr('every_n_days', {'n': '${plan.medicationFrequencyDays}'}),
              ),
            if (plan?.assignedCenterId != null)
              _buildHistoryRow(
                context.tr('therapy_center'),
                provider.therapyCenterLabel(context, plan!.assignedCenterId),
                icon: LucideIcons.mapPin,
              ),
          ]),
          const SizedBox(height: 24),
          if (exercises.isNotEmpty) ...[
            _buildExerciseListSection(context, exercises),
            const SizedBox(height: 24),
          ],
          if (patient.clinicalAttachments.isNotEmpty)
            _buildPlanSection(
              context.tr('lab_documents_section'),
              patient.clinicalAttachments.map((doc) {
                return _buildHistoryRow(
                  doc.isPdf ? context.tr('document_pdf') : context.tr('document_image'),
                  doc.fileName,
                  icon: LucideIcons.fileText,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityLogTab(BuildContext context, DataProvider provider, Patient patient) {
    final patientLogs = provider.logs.where((l) => l.patientId == patient.id).toList();
    
    if (patientLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(context.tr('no_activity_logs'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: patientLogs.length,
      itemBuilder: (context, index) {
        final log = patientLogs[index];
        final kind = log.eventKind;
        final (Color color, IconData icon, String typeLabel) = switch (kind) {
          'dispense' => (AppColors.success, LucideIcons.package, context.tr('log_type_dispense')),
          'care_plan' => (AppColors.primary, LucideIcons.clipboardList, context.tr('log_type_care_plan')),
          'registration' => (AppColors.textPrimary, LucideIcons.userPlus, context.tr('log_type_registration')),
          'clinical_review' => (AppColors.warning, LucideIcons.stethoscope, context.tr('log_type_clinical_review')),
          _ => (AppColors.textSecondary, LucideIcons.activity, context.tr('log_type_other')),
        };

        final isCarePlan = kind == 'care_plan';
        final statusColor = log.status == 'Pending'
            ? AppColors.warning
            : log.status == 'Overridden'
                ? AppColors.error
                : AppColors.success;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _logTypeChip(typeLabel, color),
                          if (log.status != 'Success')
                            _logTypeChip(log.getLocalizedStatus(context), statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.getLocalizedAction(context),
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
                      ),
                      if (isCarePlan) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr('log_not_dispense_hint'),
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        kind == 'dispense'
                            ? context.tr('dispensed_at_facility', {
                                'facility': log.getLocalizedCenterName(context),
                              })
                            : '${context.tr('recorded_by')}: ${log.getLocalizedCenterName(context)}',
                        style: TextStyle(
                          color: kind == 'dispense' ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: kind == 'dispense' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  log.formatTimestamp(context),
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _logTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}