import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../data/home_exercise_catalog.dart';
import '../models/treatment_plan.dart';
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
                if (activePlan == null)
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
                            child: TreatmentPlanBuilder(patient: patient, existingPlan: null),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.plusCircle),
                    label: Text(context.tr('create_treatment_plan')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') {
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
                      } else if (value == 'add') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('cannot_add_new_plan_error')),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit, size: 18, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(context.tr('edit_current_plan')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            Icon(LucideIcons.plusCircle, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(context.tr('add_new_plan')),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(LucideIcons.settings, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('manage_plan'),
                            style:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                           Icon(LucideIcons.chevronDown, color: AppColors.textPrimary, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              tabs: [
                Tab(text: context.tr('overview')),
                Tab(text: context.tr('treatment_plan')),
                Tab(text: context.tr('medical_history')),
                Tab(text: context.tr('activity_log')),
              ],
            ),
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
    final provider = Provider.of<DataProvider>(context, listen: false);
    final dispenseStatus = provider.dispensingUiStatus(patient);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('patient_overview_snapshot'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSnapshotChip(
                  context.tr('col_id'),
                  patient.id,
                  LucideIcons.badgeCheck,
                  AppColors.primary,
                ),
                _buildSnapshotChip(
                  context.tr('residency_status'),
                  patient.getLocalizedResidency(context),
                  LucideIcons.home,
                  AppColors.navy,
                ),
                _buildSnapshotChip(
                  patient.programEligibility.eligible ? context.tr('eligible_dispensation') : context.tr('status_program_ineligible'),
                  _dispensingStatusLabel(context, provider, patient),
                  LucideIcons.package,
                  _dispensingStatusColor(dispenseStatus),
                ),
                _buildSnapshotChip(
                  context.tr('compliance_score'),
                  '${(patient.complianceRate * 100).toInt()}%',
                  LucideIcons.checkCircle,
                  AppColors.success,
                ),
                if (patient.lastDispensingDate != null)
                  _buildSnapshotChip(
                    context.tr('last_dispense_date'),
                    patient.lastDispensingDate!,
                    LucideIcons.calendar,
                    AppColors.textPrimary,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final demographics = _buildInfoSection(
                  title: context.tr('demographics_section'),
                  icon: LucideIcons.userCircle,
                  accent: AppColors.primary,
                  items: [
                    _InfoItem(context.tr('full_name'), patient.getLocalizedFullName(context), LucideIcons.user),
                    _InfoItem(context.tr('full_name_en'), patient.fullName, LucideIcons.languages),
                    _InfoItem(context.tr('full_name_ar'), patient.fullNameAr, LucideIcons.languages),
                    _InfoItem(context.tr('emirates_id'), patient.emiratesId, LucideIcons.hash),
                    _InfoItem(context.tr('col_id'), patient.id, LucideIcons.badgeCheck),
                    _InfoItem('${context.tr('age')} / ${context.tr('gender')}', '${patient.age} · ${patient.getLocalizedGender(context)}'),
                    _InfoItem(context.tr('nationality'), patient.getLocalizedNationality(context), LucideIcons.globe),
                    _InfoItem(context.tr('residency_status'), patient.getLocalizedResidency(context), LucideIcons.home),
                    _InfoItem(context.tr('region'), patient.getLocalizedEmirate(context), LucideIcons.mapPin),
                  ],
                );
                final program = _buildInfoSection(
                  title: context.tr('program_dispensing_section'),
                  icon: LucideIcons.clipboardCheck,
                  accent: AppColors.navy,
                  items: [
                    _InfoItem(
                      context.tr('select_dose'),
                      context.mounjaroDoseLabel(patient.currentDose),
                      LucideIcons.pill,
                    ),
                    _InfoItem(
                      context.tr('last_dispense_date'),
                      patient.lastDispensingDate ?? context.tr('never_dispensed'),
                      LucideIcons.calendar,
                    ),
                    _InfoItem(
                      context.tr('next_dispense_eligible'),
                      patient.nextEligibleDate ?? context.tr('now'),
                      LucideIcons.clock,
                    ),
                    if (patient.lastDispensingCenterId != null)
                      _InfoItem(
                        context.tr('last_dispensing_facility'),
                        provider.dispensingFacilityLabel(context, patient.lastDispensingCenterId),
                        LucideIcons.building2,
                      ),
                    _InfoItem(
                      context.tr('eligible_dispensation'),
                      _dispensingStatusLabel(context, provider, patient),
                      LucideIcons.shieldCheck,
                    ),
                    _InfoItem(
                      context.tr('compliance_score'),
                      '${(patient.complianceRate * 100).toInt()}%',
                      LucideIcons.checkCircle,
                    ),
                  ],
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: demographics),
                      const SizedBox(width: 20),
                      Expanded(child: program),
                    ],
                  );
                }
                return Column(
                  children: [
                    demographics,
                    const SizedBox(height: 20),
                    program,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _dispensingStatusLabel(BuildContext context, DataProvider provider, Patient patient) {
    switch (provider.dispensingUiStatus(patient)) {
      case DispensingUiStatus.eligible:
        return context.tr('eligible_dispensation');
      case DispensingUiStatus.approvedEarly:
        return context.tr('status_clinical_approved_dispense');
      case DispensingUiStatus.pendingCarePlan:
        return context.tr('status_pending_care_plan');
      case DispensingUiStatus.pendingClinicalReview:
        return context.tr('status_pending_clinical_review');
      case DispensingUiStatus.clinicalIneligible:
        return context.tr('status_program_ineligible');
    }
  }

  Color _dispensingStatusColor(DispensingUiStatus status) {
    switch (status) {
      case DispensingUiStatus.eligible:
      case DispensingUiStatus.approvedEarly:
        return AppColors.success;
      case DispensingUiStatus.pendingCarePlan:
      case DispensingUiStatus.pendingClinicalReview:
        return AppColors.warning;
      case DispensingUiStatus.clinicalIneligible:
        return AppColors.error;
    }
  }

  Widget _buildSnapshotChip(String label, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color accent,
    required List<_InfoItem> items,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: items.isEmpty && trailing != null
                ? trailing
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth >= 520 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisExtent: 72,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (_, i) => _buildInfoCell(items[i]),
                          );
                        },
                      ),
                      if (trailing != null) ...[
                        const SizedBox(height: 16),
                        trailing,
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartSection(BuildContext context, Patient patient, {required bool showBmi}) {
    final title = showBmi ? context.tr('bmi_trend') : context.tr('weight_trend');
    final spots = patient.weightHistory.asMap().entries.map((e) {
      final y = showBmi
          ? e.value / ((patient.height / 100) * (patient.height / 100))
          : e.value;
      return FlSpot(e.key.toDouble(), y);
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.lineChart, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: showBmi ? 1 : 2),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final weightLoss = patient.weightHistory.length >= 2
        ? (patient.weightHistory.first - patient.weight).toStringAsFixed(1)
        : null;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClinicalEligibilityBanner(patient: patient),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSnapshotChip(
                  context.tr('weight'),
                  '${patient.weight.toStringAsFixed(1)} kg',
                  LucideIcons.scale,
                  AppColors.primary,
                ),
                _buildSnapshotChip(
                  context.tr('col_bmi'),
                  patient.bmi.toStringAsFixed(1),
                  LucideIcons.activity,
                  patient.bmi >= 35.0 ? AppColors.error : AppColors.warning,
                ),
                if (weightLoss != null)
                  _buildSnapshotChip(
                    context.tr('weight_loss'),
                    '$weightLoss kg',
                    LucideIcons.trendingDown,
                    AppColors.success,
                  ),
                if (patient.hba1cPercent != null)
                  _buildSnapshotChip(
                    context.tr('hba1c_label'),
                    '${patient.hba1cPercent!.toStringAsFixed(1)}%',
                    LucideIcons.droplets,
                    AppColors.navy,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              title: context.tr('clinical_assessment'),
              icon: LucideIcons.stethoscope,
              accent: AppColors.error,
              items: [
                _InfoItem(context.tr('weight'), '${patient.weight.toStringAsFixed(1)} kg', LucideIcons.scale),
                _InfoItem(context.tr('height_cm'), '${patient.height.toStringAsFixed(0)} cm', LucideIcons.ruler),
                _InfoItem(context.tr('col_bmi'), patient.bmi.toStringAsFixed(1), LucideIcons.activity),
                _InfoItem(
                  context.tr('has_chronic_disease'),
                  patient.hasChronicDisease ? context.tr('yes') : context.tr('no'),
                  LucideIcons.heartPulse,
                ),
                _InfoItem(
                  context.tr('hba1c_label'),
                  patient.hba1cPercent != null
                      ? '${patient.hba1cPercent!.toStringAsFixed(1)}%'
                      : context.tr('not_recorded'),
                  LucideIcons.droplets,
                ),
                _InfoItem(
                  context.tr('fasting_glucose_label'),
                  patient.fastingGlucoseMgDl != null
                      ? '${patient.fastingGlucoseMgDl!.toStringAsFixed(0)} mg/dL'
                      : context.tr('not_recorded'),
                  LucideIcons.activity,
                ),
                _InfoItem(
                  context.tr('compliance_score'),
                  '${(patient.complianceRate * 100).toInt()}%',
                  LucideIcons.checkCircle,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoSection(
              title: context.tr('chronic_conditions_section'),
              icon: LucideIcons.heartPulse,
              accent: AppColors.warning,
              items: conditions.isEmpty
                  ? [_InfoItem(context.tr('condition_field'), context.tr('none_reported'), LucideIcons.circle)]
                  : conditions.map((c) => _InfoItem(context.tr('condition_field'), c, LucideIcons.circle)).toList(),
            ),
            const SizedBox(height: 20),
            _buildInfoSection(
              title: context.tr('medication_history_section'),
              icon: LucideIcons.pill,
              accent: AppColors.navy,
              items: [
                _InfoItem(
                  patient.lastDispensingDate == null
                      ? context.tr('prescribed_dose_plan')
                      : context.tr('active_prescription'),
                  context.mounjaroDoseLabel(patient.currentDose),
                  LucideIcons.pill,
                ),
                _InfoItem(
                  context.tr('last_dispense_date'),
                  patient.lastDispensingDate ?? context.tr('never_dispensed'),
                  LucideIcons.calendar,
                ),
                if (patient.lastDispensingCenterId != null)
                  _InfoItem(
                    context.tr('last_dispensing_facility'),
                    provider.dispensingFacilityLabel(context, patient.lastDispensingCenterId),
                    LucideIcons.building2,
                  ),
                _InfoItem(
                  context.tr('next_dispense_eligible'),
                  patient.nextEligibleDate ?? context.tr('now'),
                  LucideIcons.clock,
                ),
                _InfoItem(
                  context.tr('dose_history'),
                  patient.doseHistory.isNotEmpty
                      ? patient.doseHistory.join(' → ')
                      : context.tr('no_dispense_history'),
                  LucideIcons.history,
                ),
                if (plan != null)
                  _InfoItem(
                    context.tr('injection_interval'),
                    context.tr('every_n_days', {'n': '${plan.medicationFrequencyDays}'}),
                    LucideIcons.syringe,
                  ),
                ...patient.dispenseRecords.reversed.take(4).map((r) {
                  return _InfoItem(
                    context.tr('dispensing_facility'),
                    context.tr('dispense_record_line', {
                      'date': r.date,
                      'dose': context.mounjaroDoseLabel(r.dose),
                      'facility': provider.dispensingFacilityLabel(context, r.centerId),
                    }),
                    LucideIcons.package,
                  );
                }),
              ],
            ),
            if (patient.weightHistory.length >= 2) ...[
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTrendChartSection(context, patient, showBmi: false)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildTrendChartSection(context, patient, showBmi: true)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildTrendChartSection(context, patient, showBmi: false),
                      const SizedBox(height: 20),
                      _buildTrendChartSection(context, patient, showBmi: true),
                    ],
                  );
                },
              ),
            ],
            if (patient.clinicalAttachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildInfoSection(
                title: context.tr('lab_documents_section'),
                icon: LucideIcons.fileText,
                accent: AppColors.primary,
                items: patient.clinicalAttachments
                    .map(
                      (doc) => _InfoItem(
                        doc.isPdf ? context.tr('document_pdf') : context.tr('document_image'),
                        doc.fileName,
                        LucideIcons.fileText,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
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

class _InfoItem {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoItem(this.label, this.value, [this.icon]);
}