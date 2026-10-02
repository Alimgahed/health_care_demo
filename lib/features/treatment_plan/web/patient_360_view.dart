import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mounjaro_demo/core/utils/dose_utils.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/access_control.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../clinical/clinical_eligibility_banner.dart';
import '../../journey/journey_models.dart';
import '../../journey/journey_provider.dart';
import '../../journey/journey_screen.dart';
import '../data/home_exercise_catalog.dart';
import '../models/treatment_plan.dart';
import 'treatment_plan_builder.dart';

class Patient360View extends StatefulWidget {
  final Patient patient;
  final int initialTabIndex;
  final VoidCallback? onBack;

  const Patient360View({
    super.key,
    required this.patient,
    this.initialTabIndex = 0,
    this.onBack,
  });

  @override
  State<Patient360View> createState() => _Patient360ViewState();
}

class _Patient360ViewState extends State<Patient360View>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _labQuery = '';
  String _labCategory = 'all';
  String _labStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 11,
      initialIndex: widget.initialTabIndex.clamp(0, 10),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JourneyProvider>().bindExistingPatient(widget.patient);
    });
  }

  Patient _livePatient(DataProvider dp) =>
      dp.getPatientById(widget.patient.id) ?? widget.patient;

  List<HomeExercise> _patientExercises(DataProvider dp) =>
      HomeExerciseCatalog.forPatientPlans(dp.treatmentPlans, widget.patient.id);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final access = context.watch<AccessControlProvider>();
    final patient = _livePatient(dataProvider);
    final activePlan = dataProvider.treatmentPlans
        .cast<TreatmentPlan?>()
        .firstWhere(
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(1200, MediaQuery.sizeOf(context).width - 64),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed:
                          widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      child: Text(
                        patient.getLocalizedFullName(context).substring(0, 1),
                        style: TextStyle(
                          fontSize: 32,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.getLocalizedFullName(context),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildHeaderBadge(
                                LucideIcons.hash,
                                patient.emiratesId,
                              ),
                              _buildHeaderBadge(
                                LucideIcons.user,
                                '${patient.age} ${context.tr('age')}',
                              ),
                              _buildHeaderBadge(
                                LucideIcons.mapPin,
                                patient.getLocalizedEmirate(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (access.can(AppPermission.createTreatmentRequest))
                      ElevatedButton.icon(
                        onPressed: () =>
                            _createTreatmentRequest(context, patient),
                        icon: const Icon(LucideIcons.filePlus2),
                        label: Text(context.tr('create_treatment_request')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (access.can(AppPermission.createTreatmentRequest))
                      const SizedBox(width: 12),
                    if (activePlan == null &&
                        access.can(AppPermission.createTreatmentPlan))
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              insetPadding: const EdgeInsets.all(24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: SizedBox(
                                width: 900,
                                height: 700,
                                child: TreatmentPlanBuilder(
                                  patient: patient,
                                  existingPlan: null,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.plusCircle),
                        label: Text(context.tr('create_treatment_plan')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else if (activePlan != null &&
                        access.can(AppPermission.createTreatmentPlan))
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendarCheck,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${context.tr('active_plan')} ${activePlan.createdAt.toString().split(' ')[0]}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  insetPadding: const EdgeInsets.all(24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: SizedBox(
                                    width: 900,
                                    height: 700,
                                    child: TreatmentPlanBuilder(
                                      patient: patient,
                                      existingPlan: activePlan,
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.edit3, size: 18),
                            label: Text(context.tr('modify')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            color: AppColors.surface,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useFullWidth = constraints.maxWidth >= 1180;
                return TabBar(
                  controller: _tabController,
                  isScrollable: !useFullWidth,
                  tabAlignment: useFullWidth
                      ? TabAlignment.fill
                      : TabAlignment.start,
                  padding: EdgeInsets.zero,
                  labelPadding: useFullWidth
                      ? const EdgeInsets.symmetric(horizontal: 4)
                      : const EdgeInsets.symmetric(horizontal: 18),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 1,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: useFullWidth ? 13 : 15,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: useFullWidth ? 13 : 15,
                  ),
                  tabs: [
                    Tab(text: context.tr('overview')),
                    Tab(text: context.tr('medical_history')),
                    Tab(text: context.tr('treatment_plan')),
                    Tab(text: context.tr('treatment_journey')),
                    Tab(text: context.tr('medications')),
                    Tab(text: context.tr('laboratory_results')),
                    Tab(text: context.tr('eligibility')),
                    Tab(text: context.tr('treatment_requests')),
                    Tab(text: context.tr('documents')),
                    Tab(text: context.tr('appointments')),
                    Tab(text: context.tr('audit_trail')),
                  ],
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, patient, exercises),
                _buildMedicalHistoryTab(
                  context,
                  patient,
                  dataProvider,
                  exercises,
                ),
                _buildTreatmentPlanTab(context, activePlan, dataProvider),
                _buildJourneyTab(context),
                _buildMedicationsTab(context, patient),
                _buildLabsTab(context, patient),
                _buildEligibilityTab(context, patient),
                _buildRequestsTab(context),
                _buildDocumentsTab(context, patient),
                _buildAppointmentsTab(context, patient),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTreatmentRequest(
    BuildContext context,
    Patient patient,
  ) async {
    String selectedDose = '2.5 mg';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isAr = context.isArabic;
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                isAr ? 'إنشاء طلب علاج مباشر' : 'Create Treatment Request',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'اختر الجرعة لإنشاء خطة دوائية وإرسالها للمراجعة الطبية.'
                          : 'Choose the dose to create a medication plan and submit it for medical review.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isAr
                          ? 'الجرعة المطلوبة من مونجارو:'
                          : 'Required Mounjaro Dose:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: DoseUtils.planDoseOptions.map((dose) {
                        final isSelected = selectedDose == dose;
                        return ChoiceChip(
                          label: Text(dose),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedDose = dose);
                            }
                          },
                          selectedColor: AppColors.success.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(isAr ? 'إرسال للمراجعة' : 'Submit for review'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final dp = this.context.read<DataProvider>();

    // Create a simplified treatment plan (medication only)
    final now = DateTime.now();
    final newPlan = TreatmentPlan(
      id: 'TP-${now.millisecondsSinceEpoch}',
      patientId: patient.id,
      doctorName: 'Dr. Current User',
      createdAt: now,
      updatedAt: now,
      medicationDose: DoseUtils.toInventoryDose(selectedDose),
      medicationFrequencyDays: 28,
      medicationQuantity: 1,
      reminderTimes: const [],
      sessions: const [],
      homeExercises: const [],
      targetWeight: patient.weight,
      clinicalApprovalStatus: 'pending_review',
    );

    dp.createTreatmentPlan(newPlan);
    if (!mounted) return;
    final saved = dp.getPlanForPatient(patient.id);
    if (saved?.id != newPlan.id) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            this.context.isArabic
                ? 'تعذّر حفظ خطة العلاج. راجع الصلاحيات وبيانات المريض.'
                : 'The treatment plan could not be saved. Check permissions and patient details.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final journey = this.context.read<JourneyProvider>();
    journey.bindExistingPatient(dp.getPatientById(patient.id)!);
    final submitted = journey.submit();
    if (submitted.success) journey.evaluate();
    _tabController.animateTo(3);
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          submitted.success
              ? (this.context.isArabic
                    ? 'أُرسل طلب العلاج للمراجعة. أكمل أي معلومات ناقصة من مسار العلاج.'
                    : 'Treatment request submitted for review. Complete any missing information in the journey.')
              : (this.context.isArabic
                    ? 'حُفظت الخطة، لكن لم يُرسل الطلب. راجع مسار العلاج.'
                    : 'Plan saved, but the request was not submitted. Review the treatment journey.'),
        ),
        backgroundColor: submitted.success
            ? AppColors.success
            : AppColors.warning,
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Patient patient,
    List<HomeExercise> exercises,
  ) {
    final _ = _buildOverviewTabLegacy;
    final provider = context.watch<DataProvider>();
    final plan = provider.treatmentPlans.cast<TreatmentPlan?>().firstWhere(
      (item) => item?.patientId == patient.id && item?.status == 'Active',
      orElse: () => null,
    );
    final nextDate = patient.nextEligibleDate ?? '—';
    final lastDate = patient.lastDispensingDate ?? '—';
    final compliance = '${(patient.complianceRate * 100).round()}%';

    return ColoredBox(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 1000
                    ? (constraints.maxWidth - 48) / 5
                    : 220.0;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _overviewMetric(
                      width,
                      context.tr('col_id'),
                      patient.id,
                      LucideIcons.folderClock,
                      AppColors.accent,
                    ),
                    _overviewMetric(
                      width,
                      context.tr('residency_status'),
                      patient.getLocalizedResidency(context),
                      LucideIcons.house,
                      AppColors.navy,
                    ),
                    _overviewMetric(
                      width,
                      context.tr('col_bmi'),
                      patient.bmi.toStringAsFixed(1),
                      LucideIcons.chartNoAxesCombined,
                      patient.bmi < 25 ? AppColors.success : AppColors.error,
                    ),
                    _overviewMetric(
                      width,
                      context.tr('compliance_score'),
                      compliance,
                      LucideIcons.circleGauge,
                      AppColors.success,
                    ),
                    _overviewMetric(
                      width,
                      context.tr('last_visit'),
                      lastDate,
                      LucideIcons.calendarDays,
                      AppColors.textPrimary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _buildAiPatientInsights(context, patient),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _vitalsOverviewCard(context, patient),
                  _overviewCard(
                    context.tr('demographics_section'),
                    LucideIcons.userRound,
                    [
                      _overviewLine(context.tr('full_name'), patient.fullName),
                      _overviewLine(
                        context.tr('full_name_ar'),
                        patient.fullNameAr,
                      ),
                      _overviewLine(
                        context.tr('emirates_id'),
                        patient.emiratesId,
                      ),
                      _overviewLine(context.tr('col_id'), patient.id),
                      _overviewLine(
                        '${context.tr('age')} / ${context.tr('gender')}',
                        '${patient.age} · ${patient.getLocalizedGender(context)}',
                      ),
                      _overviewLine(
                        context.tr('nationality'),
                        patient.getLocalizedNationality(context),
                      ),
                    ],
                  ),
                  _overviewCard(
                    context.tr('clinical_summary'),
                    LucideIcons.stethoscope,
                    [
                      _overviewLine(
                        context.tr('medical_conditions'),
                        patient
                            .getLocalizedMedicalConditions(context)
                            .join('، '),
                      ),
                      _overviewLine(context.tr('last_visit'), lastDate),
                      _overviewLine(context.tr('next_eligible_date'), nextDate),
                      _overviewLine(
                        context.tr('treatment_status'),
                        plan?.status ?? context.tr('no_active_plan'),
                      ),
                      _overviewLine(
                        context.tr('eligibility_status'),
                        patient.programEligibility.eligible
                            ? (context.isArabic
                                  ? 'مستوفٍ للمعايير السريرية'
                                  : 'Clinical criteria met')
                            : context.tr('status_program_ineligible'),
                      ),
                    ],
                  ),
                ];
                if (constraints.maxWidth >= 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: SizedBox(height: 310, child: cards[i])),
                        if (i < cards.length - 1) const SizedBox(width: 14),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _medicationsOverviewCard(context, patient, compliance),
                  _labsOverviewCard(context, patient, lastDate),
                  _appointmentOverviewCard(context, nextDate, plan != null),
                ];
                if (constraints.maxWidth >= 1000) {
                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i < cards.length - 1) const SizedBox(width: 14),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewMetric(
    double width,
    String label,
    String value,
    IconData icon,
    Color color,
  ) => Container(
    width: width,
    height: 82,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _overviewCard(String title, IconData icon, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _vitalsOverviewCard(
    BuildContext context,
    Patient patient,
  ) => _overviewCard(
    context.tr('vital_metrics'),
    LucideIcons.chartNoAxesColumnIncreasing,
    [
      LayoutBuilder(
        builder: (context, constraints) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth < 380 ? 1.5 : 2.8,
          children: [
            _vitalTile(
              context.tr('weight'),
              '${patient.weight.toStringAsFixed(1)} kg',
              LucideIcons.scale,
              AppColors.primary,
            ),
            _vitalTile(
              context.tr('col_bmi'),
              patient.bmi.toStringAsFixed(1),
              LucideIcons.activity,
              patient.bmi < 25 ? AppColors.success : AppColors.error,
            ),
            _vitalTile(
              context.isArabic ? 'سكر صائم' : 'Fasting glucose',
              patient.fastingGlucoseMgDl == null
                  ? (context.isArabic ? 'غير مسجل' : 'Not recorded')
                  : '${patient.fastingGlucoseMgDl!.toStringAsFixed(0)} mg/dL',
              LucideIcons.droplets,
              Colors.blue,
            ),
            _vitalTile(
              'HbA1c',
              patient.hba1cPercent == null
                  ? (context.isArabic ? 'غير مسجل' : 'Not recorded')
                  : '${patient.hba1cPercent!.toStringAsFixed(1)}%',
              LucideIcons.droplets,
              AppColors.warning,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _vitalTile(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _medicationsOverviewCard(
    BuildContext context,
    Patient patient,
    String compliance,
  ) => _overviewCard(context.tr('current_medications'), LucideIcons.pill, [
    _sectionLink(context),
    _medicationRow('Mounjaro', context.mounjaroDoseLabel(patient.currentDose)),
    _medicationRow(
      context.tr('compliance_score'),
      compliance,
      icon: LucideIcons.circleCheck,
    ),
  ]);

  Widget _medicationRow(
    String name,
    String dose, {
    IconData icon = LucideIcons.pill,
  }) => Container(
    margin: const EdgeInsets.only(top: 9),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                dose,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Active',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _labsOverviewCard(
    BuildContext context,
    Patient patient,
    String date,
  ) => _overviewCard(
    context.tr('laboratory_results'),
    LucideIcons.flaskConical,
    [
      _sectionLink(context),
      _resultRow(
        'HbA1c',
        '${patient.hba1cPercent?.toStringAsFixed(1) ?? '—'}%',
        date,
        AppColors.success,
      ),
      _resultRow(
        context.tr('fasting_glucose'),
        '${patient.fastingGlucoseMgDl?.toStringAsFixed(0) ?? '—'} mg/dL',
        date,
        Colors.blue,
      ),
    ],
  );

  Widget _resultRow(String label, String value, String date, Color color) =>
      Container(
        margin: const EdgeInsets.only(top: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.flaskConical, size: 16, color: color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _appointmentOverviewCard(
    BuildContext context,
    String date,
    bool hasPlan,
  ) => _overviewCard(context.tr('appointments'), LucideIcons.calendarCheck, [
    _sectionLink(context),
    Container(
      margin: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: Radius.circular(10),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '01',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  date == '—' ? '—' : date.split('-').first,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPlan
                        ? context.tr('follow_up')
                        : context.tr('appointments'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(end: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              '10:30',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  ]);

  Widget _sectionLink(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Text(
      context.tr('view_all'),
      style: TextStyle(
        color: Colors.blue.shade700,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _overviewLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _buildOverviewTabLegacy(
    BuildContext context,
    Patient patient,
    List<HomeExercise> exercises,
  ) {
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
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
                  context.isArabic ? 'حالة الصرف' : 'Dispensing status',
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
            _buildAiPatientInsights(context, patient),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final demographics = _buildInfoSection(
                  title: context.tr('demographics_section'),
                  icon: LucideIcons.userCircle,
                  accent: AppColors.primary,
                  items: [
                    _InfoItem(
                      context.tr('full_name'),
                      patient.getLocalizedFullName(context),
                      LucideIcons.user,
                    ),
                    _InfoItem(
                      context.tr('full_name_en'),
                      patient.fullName,
                      LucideIcons.languages,
                    ),
                    _InfoItem(
                      context.tr('full_name_ar'),
                      patient.fullNameAr,
                      LucideIcons.languages,
                    ),
                    _InfoItem(
                      context.tr('emirates_id'),
                      patient.emiratesId,
                      LucideIcons.hash,
                    ),
                    _InfoItem(
                      context.tr('col_id'),
                      patient.id,
                      LucideIcons.badgeCheck,
                    ),
                    _InfoItem(
                      '${context.tr('age')} / ${context.tr('gender')}',
                      '${patient.age} · ${patient.getLocalizedGender(context)}',
                    ),
                    _InfoItem(
                      context.tr('nationality'),
                      patient.getLocalizedNationality(context),
                      LucideIcons.globe,
                    ),
                    _InfoItem(
                      context.tr('residency_status'),
                      patient.getLocalizedResidency(context),
                      LucideIcons.home,
                    ),
                    _InfoItem(
                      context.tr('region'),
                      patient.getLocalizedEmirate(context),
                      LucideIcons.mapPin,
                    ),
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
                      patient.lastDispensingDate ??
                          context.tr('never_dispensed'),
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
                        provider.dispensingFacilityLabel(
                          context,
                          patient.lastDispensingCenterId,
                        ),
                        LucideIcons.building2,
                      ),
                    _InfoItem(
                      context.isArabic ? 'حالة الصرف' : 'Dispensing status',
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
                  children: [demographics, const SizedBox(height: 20), program],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _dispensingStatusLabel(
    BuildContext context,
    DataProvider provider,
    Patient patient,
  ) {
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

  Widget _buildSnapshotChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisExtent: 112,
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
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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

  Widget _buildTrendChartSection(
    BuildContext context,
    Patient patient, {
    required bool showBmi,
  }) {
    final title = showBmi
        ? context.tr('bmi_trend')
        : context.tr('weight_trend');
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
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
                  child: Icon(
                    LucideIcons.lineChart,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: showBmi ? 1 : 2,
                  ),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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

  Widget _buildTreatmentPlanTab(
    BuildContext context,
    TreatmentPlan? plan,
    DataProvider provider,
  ) {
    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              context.tr('no_active_plan'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final patient = provider.getPatientById(plan.patientId) ?? widget.patient;
    final journey = context.watch<JourneyProvider>();
    final request = journey.request.patientId == patient.id
        ? journey.request
        : null;
    final appointments = provider.appointmentsFor(patient.id);
    final attended = plan.sessions
        .where((session) => session.isAttended)
        .length;
    final therapyProgress = plan.totalSessions == 0
        ? 0.0
        : attended / plan.totalSessions;
    final exerciseCount = plan.homeExercises.length;
    final exerciseCompletions = plan.homeExercises.fold<int>(
      0,
      (total, exercise) => total + exercise.completedDates.length,
    );
    final planProgress = request == null
        ? .25
        : _carePlanProgress(request.status);
    final nextAction = _carePlanNextAction(context, request?.status);

    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final padding = compact ? 14.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _carePlanSummary(
                  context,
                  plan: plan,
                  patient: patient,
                  progress: planProgress,
                  nextAction: nextAction,
                  requestStatus: request?.status,
                  compact: compact,
                ),
                const SizedBox(height: 14),
                if (plan.clinicalApprovalStatus == 'pending_review')
                  _carePlanNotice(
                    context,
                    context.tr('care_plan_status_pending'),
                    LucideIcons.clock3,
                    AppColors.warning,
                  ),
                if (plan.clinicalApprovalStatus == 'pending_review')
                  const SizedBox(height: 14),
                _carePlanSection(
                  context,
                  icon: LucideIcons.pill,
                  title: context.isArabic
                      ? 'خطة العلاج الدوائي'
                      : 'Medication treatment plan',
                  subtitle: context.isArabic
                      ? 'تفاصيل الدواء والجرعة والصرف والالتزام'
                      : 'Medication, dose, dispensing and adherence details',
                  actionLabel: context.isArabic
                      ? 'عرض التفاصيل'
                      : 'View details',
                  onAction: () => _tabController.animateTo(4),
                  compact: compact,
                  leading: _careProgressVisual(
                    patient.complianceRate,
                    '${(patient.complianceRate * 100).round()}%',
                    context.isArabic ? 'التزام بالعلاج' : 'adherence',
                  ),
                  metrics: [
                    _CareMetric(
                      LucideIcons.pill,
                      context.isArabic ? 'الدواء' : 'Medication',
                      'Mounjaro',
                      context.mounjaroDoseLabel(plan.medicationDose),
                    ),
                    _CareMetric(
                      LucideIcons.syringe,
                      context.isArabic ? 'طريقة الاستخدام' : 'Route',
                      context.isArabic ? 'حقن تحت الجلد' : 'Subcutaneous',
                      context.tr('every_n_days', {
                        'n': '${plan.medicationFrequencyDays}',
                      }),
                    ),
                    _CareMetric(
                      LucideIcons.calendarDays,
                      context.isArabic ? 'الصرف' : 'Dispensing',
                      patient.lastDispensingDate ??
                          (context.isArabic ? 'لم يتم الصرف' : 'Not dispensed'),
                      '${context.isArabic ? 'الاستحقاق القادم' : 'Next eligible'}: ${patient.nextEligibleDate ?? '—'}',
                    ),
                    _CareMetric(
                      LucideIcons.circleCheck,
                      context.isArabic ? 'حالة الالتزام' : 'Adherence',
                      '${(patient.complianceRate * 100).round()}%',
                      request == null
                          ? plan.status
                          : _requestStatusLabel(context, request.status),
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _carePlanSection(
                  context,
                  icon: LucideIcons.dumbbell,
                  title: context.isArabic
                      ? 'الخطة العلاجية التأهيلية'
                      : 'Rehabilitation plan',
                  subtitle: context.isArabic
                      ? 'الجلسات والمركز العلاجي وتقدم البرنامج'
                      : 'Sessions, facility and programme progress',
                  actionLabel: context.isArabic
                      ? 'عرض التفاصيل'
                      : 'View details',
                  onAction: () => _showTherapyDetails(context, plan, provider),
                  compact: compact,
                  leading: _careProgressVisual(
                    therapyProgress,
                    '$attended / ${plan.totalSessions}',
                    context.isArabic ? 'جلسة' : 'sessions',
                  ),
                  metrics: [
                    _CareMetric(
                      LucideIcons.userRound,
                      context.isArabic ? 'المسؤول' : 'Responsible clinician',
                      plan.doctorName,
                      context.isArabic ? 'الفريق العلاجي' : 'Care team',
                    ),
                    _CareMetric(
                      LucideIcons.building2,
                      context.isArabic ? 'مركز التأهيل' : 'Therapy facility',
                      plan.assignedCenterId == null
                          ? context.tr('not_assigned')
                          : provider.therapyCenterLabel(
                              context,
                              plan.assignedCenterId,
                            ),
                      provider
                              .getTherapyCenterById(plan.assignedCenterId)
                              ?.getLocalizedEmirate(context) ??
                          '—',
                    ),
                    _CareMetric(
                      LucideIcons.target,
                      context.isArabic ? 'نوع البرنامج' : 'Programme type',
                      context.isArabic ? 'العلاج الطبيعي' : 'Physical therapy',
                      '${plan.totalSessions - attended} ${context.isArabic ? 'جلسات متبقية' : 'remaining'}',
                    ),
                    _CareMetric(
                      LucideIcons.calendarClock,
                      context.isArabic ? 'الموعد القادم' : 'Next session',
                      _nextPlanDate(plan, appointments),
                      '',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _carePlanSection(
                  context,
                  icon: LucideIcons.personStanding,
                  title: context.isArabic
                      ? 'برنامج الرعاية والتمارين المنزلية'
                      : 'Home and self-care programme',
                  subtitle: context.isArabic
                      ? 'أنشطة المريض اليومية والتعليمات المنزلية'
                      : 'Daily patient activities and home instructions',
                  actionLabel: context.isArabic
                      ? 'عرض التفاصيل'
                      : 'View details',
                  onAction: () => _showExerciseDetails(context, plan),
                  compact: compact,
                  leading: exerciseCount == 0
                      ? _careEmptyVisual(
                          context.isArabic
                              ? 'لا توجد تمارين منزلية'
                              : 'No home exercises',
                          context.isArabic
                              ? 'لم تتم إضافة تمارين للخطة'
                              : 'No exercises are assigned to this plan',
                        )
                      : _careProgressVisual(
                          (exerciseCompletions / (exerciseCount * 4)).clamp(
                            0,
                            1,
                          ),
                          '$exerciseCompletions',
                          context.isArabic ? 'نشاط مكتمل' : 'completed',
                        ),
                  metrics: [
                    _CareMetric(
                      LucideIcons.clock3,
                      context.isArabic ? 'الوقت الموصى به' : 'Recommended time',
                      exerciseCount == 0
                          ? '—'
                          : '${plan.homeExercises.first.durationMinutes} ${context.isArabic ? 'دقيقة' : 'minutes'}',
                      context.isArabic ? 'في كل جلسة' : 'per activity',
                    ),
                    _CareMetric(
                      LucideIcons.dumbbell,
                      context.isArabic ? 'عدد التمارين' : 'Exercises',
                      exerciseCount == 0
                          ? (context.isArabic ? 'لا توجد' : 'None assigned')
                          : '$exerciseCount',
                      exerciseCount == 0
                          ? (context.isArabic
                                ? 'لا توجد تمارين مضافة للخطة'
                                : 'No exercises added to the plan')
                          : (context.isArabic
                                ? 'وفق الخطة'
                                : 'in the current plan'),
                    ),
                    _CareMetric(
                      LucideIcons.calendarDays,
                      context.isArabic ? 'مدة البرنامج' : 'Programme duration',
                      context.isArabic ? '٦ أسابيع' : '6 weeks',
                      context.isArabic ? 'برنامج تدريجي' : 'Progressive plan',
                    ),
                    _CareMetric(
                      LucideIcons.shieldCheck,
                      context.isArabic ? 'الأهلية والمتطلبات' : 'Eligibility',
                      patient.programEligibility.eligible
                          ? (context.isArabic ? 'مستوفاة' : 'Eligible')
                          : (context.isArabic
                                ? 'تحتاج مراجعة'
                                : 'Needs review'),
                      'CRP: ${request?.crp?.toStringAsFixed(1) ?? '—'} · ESR: ${request?.esr?.toStringAsFixed(0) ?? '—'}',
                      color: patient.programEligibility.eligible
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _carePlanJourney(context, request?.status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _carePlanSummary(
    BuildContext context, {
    required TreatmentPlan plan,
    required Patient patient,
    required double progress,
    required String nextAction,
    required RequestStatus? requestStatus,
    required bool compact,
  }) {
    final information = [
      _CareMetric(
        LucideIcons.calendarDays,
        context.isArabic ? 'تاريخ البدء' : 'Start date',
        _formatDate(plan.createdAt),
        '${context.isArabic ? 'آخر تحديث' : 'Last updated'}: ${_formatDate(plan.updatedAt ?? plan.createdAt)}',
      ),
      _CareMetric(
        LucideIcons.userRound,
        context.isArabic ? 'الطبيب المسؤول' : 'Responsible physician',
        plan.doctorName,
        patient.getLocalizedFullName(context),
      ),
      _CareMetric(
        LucideIcons.route,
        context.isArabic ? 'المرحلة الحالية' : 'Current phase',
        requestStatus == null
            ? plan.status
            : _requestStatusLabel(context, requestStatus),
        nextAction,
      ),
    ];
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: _carePlanDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  LucideIcons.clipboardCheck,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                width: compact ? 230 : 390,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.isArabic
                          ? 'خطة الرعاية المتكاملة'
                          : 'Integrated care plan',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.isArabic
                          ? 'عرض موحّد للعلاج والرعاية والمتابعة'
                          : 'A unified view of treatment, care and follow-up',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...information.map(
                    (metric) => SizedBox(
                      width: width,
                      child: _careMetricWidget(metric, compact: compact),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _careMetricWidget(
                      _CareMetric(
                        LucideIcons.chartNoAxesCombined,
                        context.isArabic ? 'التقدم العام' : 'Overall progress',
                        '${(progress * 100).round()}%',
                        nextAction,
                        progress: progress,
                        color: AppColors.success,
                      ),
                      compact: compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _carePlanSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required Widget leading,
    required List<_CareMetric> metrics,
    required bool compact,
  }) => Container(
    padding: EdgeInsets.all(compact ? 14 : 20),
    decoration: _carePlanDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.chevronLeft, size: 16),
              label: Text(actionLabel),
            ),
          ],
        ),
        const Divider(height: 26),
        if (compact) ...[
          leading,
          const SizedBox(height: 12),
          ...metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _careMetricWidget(metric, compact: true),
            ),
          ),
        ] else
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              for (final metric in metrics) ...[
                Expanded(child: _careMetricWidget(metric)),
                if (metric != metrics.last) const SizedBox(width: 12),
              ],
            ],
          ),
      ],
    ),
  );

  Widget _careMetricWidget(_CareMetric metric, {bool compact = false}) =>
      Container(
        constraints: BoxConstraints(minHeight: compact ? 78 : 100),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: metric.color?.withValues(alpha: .055) ?? AppColors.background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  metric.icon,
                  size: 17,
                  color: metric.color ?? AppColors.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              metric.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            if (metric.detail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                metric.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
            if (metric.progress != null) ...[
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: metric.progress!.clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
                color: metric.color ?? AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            ],
          ],
        ),
      );

  Widget _careProgressVisual(
    double progress,
    String value,
    String label,
  ) => Container(
    width: 150,
    height: 100,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.success.withValues(alpha: .16)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0, 1),
                strokeWidth: 7,
                color: AppColors.success,
                backgroundColor: AppColors.border,
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _careEmptyVisual(String title, String detail) => Container(
    width: 150,
    height: 100,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.circleOff, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _carePlanNotice(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _carePlanJourney(BuildContext context, RequestStatus? current) {
    final stages = [
      (LucideIcons.userRound, context.isArabic ? 'المريض' : 'Patient'),
      (LucideIcons.stethoscope, context.isArabic ? 'التقييم' : 'Assessment'),
      (LucideIcons.flaskConical, context.isArabic ? 'التحاليل' : 'Labs'),
      (LucideIcons.shieldCheck, context.isArabic ? 'الأهلية' : 'Eligibility'),
      (LucideIcons.clipboardList, context.isArabic ? 'الخطة' : 'Plan'),
      (LucideIcons.badgeCheck, context.isArabic ? 'المراجعة' : 'Review'),
      (LucideIcons.pill, context.isArabic ? 'الصيدلية' : 'Pharmacy'),
      (LucideIcons.heartPulse, context.isArabic ? 'المتابعة' : 'Follow-up'),
    ];
    final completed = current == null
        ? 3
        : switch (current) {
            RequestStatus.draft => 4,
            RequestStatus.submitted || RequestStatus.assessing => 5,
            RequestStatus.needsInformation => 3,
            RequestStatus.underReview => 5,
            RequestStatus.approved => 6,
            RequestStatus.readyToDispense => 7,
            RequestStatus.dispensed ||
            RequestStatus.monitoring ||
            RequestStatus.renewalDue ||
            RequestStatus.completed => 8,
            RequestStatus.rejected ||
            RequestStatus.expired ||
            RequestStatus.cancelled => 5,
          };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _carePlanDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.isArabic
                ? 'رحلة قرار العلاج'
                : 'Treatment decision journey',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < stages.length; index++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: index < completed
                        ? AppColors.success.withValues(alpha: .09)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: index < completed
                          ? AppColors.success.withValues(alpha: .35)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        index < completed
                            ? LucideIcons.check
                            : stages[index].$1,
                        size: 15,
                        color: index < completed
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stages[index].$2,
                        style: const TextStyle(fontSize: 12),
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

  BoxDecoration _carePlanDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .025),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  double _carePlanProgress(RequestStatus status) => switch (status) {
    RequestStatus.draft => .38,
    RequestStatus.submitted || RequestStatus.assessing => .5,
    RequestStatus.needsInformation => .42,
    RequestStatus.underReview => .62,
    RequestStatus.approved => .72,
    RequestStatus.readyToDispense => .82,
    RequestStatus.dispensed => .9,
    RequestStatus.monitoring || RequestStatus.renewalDue => .96,
    RequestStatus.completed => 1,
    RequestStatus.rejected ||
    RequestStatus.expired ||
    RequestStatus.cancelled => .58,
  };

  String _carePlanNextAction(
    BuildContext context,
    RequestStatus? status,
  ) => switch (status) {
    null => context.isArabic ? 'إنشاء طلب علاج' : 'Create treatment request',
    RequestStatus.draft => context.isArabic ? 'إرسال الطلب' : 'Submit request',
    RequestStatus.submitted || RequestStatus.assessing =>
      context.isArabic
          ? 'استكمال تقييم الأهلية'
          : 'Complete eligibility assessment',
    RequestStatus.needsInformation =>
      context.isArabic
          ? 'استكمال التحاليل المطلوبة'
          : 'Complete required laboratory results',
    RequestStatus.underReview =>
      context.isArabic ? 'قرار المراجع الطبي' : 'Medical reviewer decision',
    RequestStatus.approved =>
      context.isArabic ? 'الإرسال للصيدلية' : 'Send to pharmacy',
    RequestStatus.readyToDispense =>
      context.isArabic ? 'صرف الدواء' : 'Dispense medication',
    RequestStatus.dispensed =>
      context.isArabic ? 'بدء المتابعة' : 'Start monitoring',
    RequestStatus.monitoring =>
      context.isArabic ? 'موعد المتابعة التالي' : 'Next follow-up',
    RequestStatus.renewalDue =>
      context.isArabic ? 'قرار التجديد' : 'Renewal decision',
    RequestStatus.completed =>
      context.isArabic ? 'الخطة مكتملة' : 'Plan completed',
    RequestStatus.rejected =>
      context.isArabic ? 'مراجعة سبب الرفض' : 'Review rejection reason',
    RequestStatus.expired =>
      context.isArabic ? 'إنشاء طلب جديد' : 'Create a new request',
    RequestStatus.cancelled =>
      context.isArabic ? 'لا يوجد إجراء نشط' : 'No active action',
  };

  String _nextPlanDate(
    TreatmentPlan plan,
    List<PatientAppointment> appointments,
  ) {
    final pendingSessions =
        plan.sessions
            .where((session) => !session.isAttended)
            .map((session) => session.scheduledDate)
            .toList()
          ..sort();
    if (pendingSessions.isNotEmpty) return _formatDate(pendingSessions.first);
    final pendingAppointments =
        appointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.scheduled,
            )
            .map((appointment) => appointment.dateTime)
            .toList()
          ..sort();
    return pendingAppointments.isEmpty
        ? '—'
        : _formatDate(pendingAppointments.first);
  }

  void _showTherapyDetails(
    BuildContext context,
    TreatmentPlan plan,
    DataProvider provider,
  ) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        context.isArabic ? 'تفاصيل الخطة التأهيلية' : 'Rehabilitation details',
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _overviewLine(
              context.isArabic ? 'المركز' : 'Facility',
              plan.assignedCenterId == null
                  ? context.tr('not_assigned')
                  : provider.therapyCenterLabel(context, plan.assignedCenterId),
            ),
            _overviewLine(
              context.isArabic ? 'الجلسات' : 'Sessions',
              '${plan.sessions.where((s) => s.isAttended).length}/${plan.totalSessions}',
            ),
            ...plan.sessions
                .take(4)
                .map(
                  (session) => _overviewLine(
                    '${context.isArabic ? 'جلسة' : 'Session'} ${session.sessionNumber}',
                    '${_formatDate(session.scheduledDate)} · ${session.isAttended ? (context.isArabic ? 'مكتملة' : 'Completed') : (context.isArabic ? 'مجدولة' : 'Scheduled')}',
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.isArabic ? 'إغلاق' : 'Close'),
        ),
      ],
    ),
  );

  void _showExerciseDetails(
    BuildContext context,
    TreatmentPlan plan,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            context.isArabic
                ? 'برنامج التمارين المنزلية'
                : 'Home exercise programme',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (plan.homeExercises.isEmpty)
            Text(
              context.isArabic
                  ? 'لا توجد تمارين مضافة.'
                  : 'No exercises added.',
            )
          else
            ...plan.homeExercises.map((exercise) {
              final resolved = HomeExerciseCatalog.resolve(exercise);
              return ListTile(
                leading: const Icon(LucideIcons.personStanding),
                title: Text(
                  HomeExerciseCatalog.displayName(resolved, context.isArabic),
                ),
                subtitle: Text(
                  context.tr('exercise_duration_format', {
                    'minutes': '${resolved.durationMinutes}',
                    'sets': '${resolved.sets}',
                    'reps': '${resolved.reps}',
                  }),
                ),
                trailing: _logTypeChip(
                  '${exercise.completedDates.length}',
                  AppColors.success,
                ),
              );
            }),
        ],
      ),
    ),
  );

  Widget _buildMedicalHistoryTab(
    BuildContext context,
    Patient patient,
    DataProvider provider,
    List<HomeExercise> exercises,
  ) {
    final _ = _buildMedicalHistoryTabLegacy;
    final conditions = patient.getLocalizedMedicalConditions(context);
    final lastVisit = patient.lastDispensingDate ?? '2026-06-01';
    final nextVisit = patient.nextEligibleDate ?? '2026-07-01';
    final events = [
      (
        nextVisit,
        context.tr('follow_up'),
        LucideIcons.calendarCheck,
        AppColors.success,
      ),
      (
        lastVisit,
        context.tr('laboratory_results'),
        LucideIcons.flaskConical,
        Colors.blue,
      ),
      (
        '2026-05-04',
        context.tr('active_prescription'),
        LucideIcons.pill,
        AppColors.primary,
      ),
      (
        '2026-03-20',
        context.tr('clinical_assessment'),
        LucideIcons.stethoscope,
        AppColors.textSecondary,
      ),
      (
        '2026-01-15',
        context.tr('documents'),
        LucideIcons.image,
        Colors.deepPurple,
      ),
      (
        '2025-11-10',
        context.tr('diagnosis'),
        LucideIcons.fileText,
        AppColors.warning,
      ),
      (
        '2024-03-12',
        context.tr('first_visit'),
        LucideIcons.userRound,
        AppColors.textSecondary,
      ),
    ];
    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _historyKpi(
                context.tr('first_visit'),
                '2024-03-12',
                LucideIcons.calendarDays,
                AppColors.warning,
              ),
              _historyKpi(
                context.tr('last_visit'),
                lastVisit,
                LucideIcons.calendarCheck,
                Colors.blue,
              ),
              _historyKpi(
                context.tr('total_visits'),
                '8',
                LucideIcons.briefcaseMedical,
                AppColors.primary,
              ),
              _historyKpi(
                context.tr('chronic_conditions_section'),
                '${conditions.length}',
                LucideIcons.heartPulse,
                AppColors.error,
              ),
              _historyKpi(
                context.tr('medical_procedures'),
                '5',
                LucideIcons.stethoscope,
                Colors.blue,
              ),
              _historyKpi(
                context.tr('laboratory_results'),
                '12',
                LucideIcons.flaskConical,
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final timeline = _medicalTimeline(context, events);
              final details = Column(
                children: [
                  _medicalEventDetails(context, patient, nextVisit),
                  const SizedBox(height: 14),
                  _medicalVitalsPanel(context, patient),
                  const SizedBox(height: 14),
                  _medicalConditionsPanel(context, conditions),
                ],
              );
              if (constraints.maxWidth >= 1000) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 370, child: timeline),
                    const SizedBox(width: 16),
                    Expanded(child: details),
                  ],
                );
              }
              return Column(
                children: [timeline, const SizedBox(height: 14), details],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _historyKpi(String label, String value, IconData icon, Color color) =>
      Container(
        width: 210,
        height: 84,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _medicalTimeline(
    BuildContext context,
    List<(String, String, IconData, Color)> events,
  ) => _overviewCard(context.tr('medical_timeline'), LucideIcons.history, [
    ...events.asMap().entries.map((entry) {
      final event = entry.value;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: entry.key == events.length - 1
              ? null
              : Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: event.$4.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(event.$3, size: 17, color: event.$4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.$2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    event.$1,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }),
  ]);

  Widget _medicalEventDetails(
    BuildContext context,
    Patient patient,
    String date,
  ) =>
      _overviewCard(context.tr('medical_event_details'), LucideIcons.fileText, [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.calendarCheck, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('follow_up'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$date · 10:30',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _eventFact(
              context.tr('provider'),
              context.tr('clinical_brand'),
              LucideIcons.building2,
            ),
            _eventFact(
              context.tr('doc_name'),
              context.tr('doc_name'),
              LucideIcons.userRound,
            ),
            _eventFact(
              context.tr('visit_type'),
              context.tr('follow_up'),
              LucideIcons.stethoscope,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _overviewLine(
          context.tr('visit_notes'),
          context.tr('stable_continue_plan'),
        ),
      ]);

  Widget _eventFact(String label, String value, IconData icon) => SizedBox(
    width: 210,
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _medicalVitalsPanel(
    BuildContext context,
    Patient patient,
  ) => _overviewCard(context.tr('vital_metrics'), LucideIcons.activity, [
    LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850
            ? 4
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 1 ? 2.25 : 1.45,
          children: [
            _historyTrend(
              context.tr('weight'),
              '${patient.weight.toStringAsFixed(1)} kg',
              patient.weightHistory,
              AppColors.primary,
            ),
            _historyTrend(
              context.tr('col_bmi'),
              patient.bmi.toStringAsFixed(1),
              patient.weightHistory
                  .map(
                    (w) =>
                        w / ((patient.height / 100) * (patient.height / 100)),
                  )
                  .toList(),
              Colors.blue,
            ),
            _historyTrend(
              'HbA1c',
              patient.hba1cPercent == null
                  ? (context.isArabic ? 'غير مسجل' : 'Not recorded')
                  : '${patient.hba1cPercent!.toStringAsFixed(1)}%',
              patient.labResults
                  .where((result) => result.testCode == 'HbA1c')
                  .map((result) => result.value)
                  .toList(),
              AppColors.warning,
            ),
            _historyTrend(
              context.isArabic ? 'سكر صائم' : 'Fasting glucose',
              patient.fastingGlucoseMgDl == null
                  ? (context.isArabic ? 'غير مسجل' : 'Not recorded')
                  : '${patient.fastingGlucoseMgDl!.toStringAsFixed(0)} mg/dL',
              patient.labResults
                  .where((result) => result.testCode == 'Fasting glucose')
                  .map((result) => result.value)
                  .toList(),
              AppColors.error,
            ),
          ],
        );
      },
    ),
  ]);

  Widget _historyTrend(
    String label,
    String value,
    List<double> values,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: values
              .take(7)
              .map(
                (v) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 12 + (v % 28),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _medicalConditionsPanel(
    BuildContext context,
    List<String> conditions,
  ) => _overviewCard(
    context.tr('diagnoses_conditions'),
    LucideIcons.stethoscope,
    [
      ...conditions.map(
        (condition) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.heartPulse, size: 17, color: AppColors.error),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  condition,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              _logTypeChip(context.tr('chronic'), Colors.blue),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildMedicalHistoryTabLegacy(
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
                _InfoItem(
                  context.tr('weight'),
                  '${patient.weight.toStringAsFixed(1)} kg',
                  LucideIcons.scale,
                ),
                _InfoItem(
                  context.tr('height_cm'),
                  '${patient.height.toStringAsFixed(0)} cm',
                  LucideIcons.ruler,
                ),
                _InfoItem(
                  context.tr('col_bmi'),
                  patient.bmi.toStringAsFixed(1),
                  LucideIcons.activity,
                ),
                _InfoItem(
                  context.tr('has_chronic_disease'),
                  patient.hasChronicDisease
                      ? context.tr('yes')
                      : context.tr('no'),
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
                  ? [
                      _InfoItem(
                        context.tr('condition_field'),
                        context.tr('none_reported'),
                        LucideIcons.circle,
                      ),
                    ]
                  : conditions
                        .map(
                          (c) => _InfoItem(
                            context.tr('condition_field'),
                            c,
                            LucideIcons.circle,
                          ),
                        )
                        .toList(),
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
                    provider.dispensingFacilityLabel(
                      context,
                      patient.lastDispensingCenterId,
                    ),
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
                    context.tr('every_n_days', {
                      'n': '${plan.medicationFrequencyDays}',
                    }),
                    LucideIcons.syringe,
                  ),
                ...patient.dispenseRecords.reversed.take(4).map((r) {
                  return _InfoItem(
                    context.tr('dispensing_facility'),
                    context.tr('dispense_record_line', {
                      'date': r.date,
                      'dose': context.mounjaroDoseLabel(r.dose),
                      'facility': provider.dispensingFacilityLabel(
                        context,
                        r.centerId,
                      ),
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
                        Expanded(
                          child: _buildTrendChartSection(
                            context,
                            patient,
                            showBmi: false,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildTrendChartSection(
                            context,
                            patient,
                            showBmi: true,
                          ),
                        ),
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
                        doc.isPdf
                            ? context.tr('document_pdf')
                            : context.tr('document_image'),
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

  Widget _buildAiPatientInsights(BuildContext context, Patient patient) {
    final isAr = context.isArabic;

    // Determine overall assessment state
    final bool hasLabs =
        patient.hba1cPercent != null || patient.fastingGlucoseMgDl != null;
    final bool isEligible = patient.programEligibility.eligible;
    final bool hasAllergies =
        patient.allergies != null && patient.allergies!.isNotEmpty;

    String assessmentTitle;
    Color assessmentColor;
    IconData assessmentIcon;
    String assessmentDesc;

    if (!isEligible) {
      assessmentTitle = isAr
          ? 'تم تحديد مخاوف تتعلق بالأهلية'
          : 'Eligibility Concern Identified';
      assessmentColor = AppColors.error;
      assessmentIcon = LucideIcons.alertTriangle;
      assessmentDesc = isAr
          ? 'بعض المؤشرات السريرية لا تتوافق مع معايير البرنامج المبدئية. يرجى مراجعة حالة المريض.'
          : 'Some clinical indicators do not align with initial program criteria. Please review patient status.';
    } else if (!hasLabs || hasAllergies) {
      assessmentTitle = isAr
          ? 'مطلوب مراجعة سريرية إضافية'
          : 'Clinical Review Required';
      assessmentColor = AppColors.warning;
      assessmentIcon = LucideIcons.fileWarning;
      assessmentDesc = isAr
          ? 'توجد بيانات ناقصة أو تنبيهات سريرية (مثل الحساسية) تتطلب مراجعة الطبيب قبل تحديد الأهلية.'
          : 'Missing data or clinical alerts (e.g., allergies) require physician review before determining eligibility.';
    } else {
      assessmentTitle = isAr
          ? 'أهلية محتملة — يتطلب مراجعة الطبيب'
          : 'Potential Eligibility — Physician Review Required';
      assessmentColor = AppColors.success;
      assessmentIcon = LucideIcons.checkCircle2;
      assessmentDesc = isAr
          ? 'المؤشرات السريرية المتاحة متوافقة مبدئياً. يظل القرار النهائي ووصف العلاج مسؤولية الطبيب.'
          : 'Available clinical indicators are initially aligned. Final decision and prescribing remain with the physician.';
    }

    Widget buildMetric(String label, String value, IconData icon, Color color) {
      return Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'التقييم السريري المدعوم بالذكاء الاصطناعي'
                      : 'AI-Assisted Clinical Assessment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _logTypeChip(
                isAr ? 'دعم القرار السريري' : 'Decision support',
                AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'تقييم مدعوم بالذكاء الاصطناعي بناءً على بيانات المريض المتاحة. يظل القرار النهائي للأهلية مسؤولية الطبيب المعالج.'
                : 'AI-assisted assessment based on available patient data. Final eligibility and treatment decisions remain with the authorized physician.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              buildMetric(
                isAr ? 'مؤشر كتلة الجسم' : 'BMI',
                '${patient.bmi.toStringAsFixed(1)} kg/m²',
                LucideIcons.activity,
                patient.bmi < 25
                    ? AppColors.success
                    : (patient.bmi >= 30 ? AppColors.error : AppColors.warning),
              ),
              buildMetric(
                isAr ? 'السكر التراكمي' : 'HbA1c',
                patient.hba1cPercent != null
                    ? '${patient.hba1cPercent!.toStringAsFixed(1)}%'
                    : (isAr ? 'غير متوفر' : 'Not available'),
                LucideIcons.testTube2,
                AppColors.primaryLight,
              ),
              buildMetric(
                isAr ? 'سكر الدم' : 'Blood Glucose',
                patient.fastingGlucoseMgDl != null
                    ? '${patient.fastingGlucoseMgDl!.toStringAsFixed(0)} mg/dL'
                    : (isAr ? 'غير متوفر' : 'Not available'),
                LucideIcons.droplets,
                AppColors.primaryLight,
              ),
              buildMetric(
                isAr ? 'التاريخ الطبي' : 'Medical History',
                patient.medicalConditions.isNotEmpty
                    ? (isAr ? 'متاح للمراجعة' : 'Available for review')
                    : (isAr ? 'لا يوجد أمراض مزمنة' : 'No chronic conditions'),
                LucideIcons.clipboardList,
                patient.medicalConditions.isNotEmpty
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              buildMetric(
                isAr ? 'الصرف السابق' : 'Previous Dispensing',
                patient.lastDispensingDate != null
                    ? (isAr ? 'تاريخ سابق مسجل' : 'Existing record')
                    : (isAr ? 'لا يوجد صرف سابق' : 'No previous dispensing'),
                LucideIcons.history,
                AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: assessmentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: assessmentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(assessmentIcon, color: assessmentColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessmentTitle,
                        style: TextStyle(
                          color: assessmentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assessmentDesc,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyTab(BuildContext context) {
    final journey = context.watch<JourneyProvider>();
    final request = journey.request;
    final history = journey
        .historyForPatient(widget.patient.id)
        .reversed
        .toList();
    final stages = [
      RequestStatus.draft,
      RequestStatus.submitted,
      RequestStatus.assessing,
      RequestStatus.underReview,
      RequestStatus.approved,
      RequestStatus.readyToDispense,
      RequestStatus.dispensed,
      RequestStatus.monitoring,
      RequestStatus.renewalDue,
    ];
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _workspaceTitle(
          context,
          context.tr('treatment_journey'),
          LucideIcons.route,
        ),
        Text(
          context.isArabic ? 'سجل طلبات العلاج' : 'Treatment request history',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...history.map((item) {
          final decision = item.audit.cast<JourneyAuditEvent?>().lastWhere(
            (event) => event?.action == 'APPROVE' || event?.action == 'REJECT',
            orElse: () => null,
          );
          final dispense = item.audit.cast<JourneyAuditEvent?>().lastWhere(
            (event) => event?.action == 'DISPENSED',
            orElse: () => null,
          );
          final color = switch (item.status) {
            RequestStatus.rejected ||
            RequestStatus.expired ||
            RequestStatus.cancelled => AppColors.error,
            RequestStatus.completed ||
            RequestStatus.dispensed ||
            RequestStatus.monitoring => AppColors.success,
            RequestStatus.needsInformation => AppColors.warning,
            RequestStatus.renewalDue => AppColors.warning,
            _ => AppColors.primary,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: item.id == request.id ? color : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.fileClock, color: color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            item.id,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          _logTypeChip(
                            _requestStatusLabel(context, item.status),
                            color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${item.medication} · ${item.dose}'),
                      Text(
                        '${context.isArabic ? 'أنشأه' : 'Created by'}: ${item.audit.isEmpty ? 'Doctor' : item.audit.first.actor} · ${_formatDate(item.createdAt)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (item.status == RequestStatus.rejected &&
                          item.reviewerNote.isNotEmpty)
                        Text(
                          '${context.isArabic ? 'سبب الرفض' : 'Rejection reason'}: ${item.reviewerNote}',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${context.isArabic ? 'المرحلة' : 'Stage'}: ${_requestStatusLabel(context, item.status)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (decision != null)
                      Text(
                        '${context.isArabic ? 'القرار' : 'Decision'}: ${_formatDate(decision.timestamp)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (dispense != null)
                      Text(
                        '${context.isArabic ? 'الصرف' : 'Dispensed'}: ${_formatDate(dispense.timestamp)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(
          context.isArabic ? 'مسار الطلب الحالي' : 'Current request journey',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...stages.map((stage) {
          final completed =
              request.status != RequestStatus.rejected &&
              request.status.index >= stage.index;
          final current = request.status == stage;
          final event = request.audit.cast<JourneyAuditEvent?>().lastWhere(
            (e) => e?.newState == stage,
            orElse: () => null,
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: current
                    ? AppColors.primary.withValues(alpha: .5)
                    : AppColors.border,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: completed
                    ? AppColors.success
                    : AppColors.border,
                child: Icon(
                  current
                      ? LucideIcons.activity
                      : (completed ? LucideIcons.check : LucideIcons.clock),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(
                _requestStatusLabel(context, stage),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                event == null
                    ? (context.isArabic ? 'لم تبدأ بعد' : 'Not started')
                    : '${event.actor} • ${event.role}${event.reason.isEmpty ? '' : '\n${event.reason}'}',
              ),
              trailing: Text(
                event == null ? '—' : _formatDate(event.timestamp),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMedicationsTab(BuildContext context, Patient patient) {
    final request = context.watch<JourneyProvider>().request;
    final provider = context.watch<DataProvider>();
    final lastDispense = patient.lastDispensingDate ?? '—';
    final nextDispense = patient.nextEligibleDate ?? '—';
    final adherence = (patient.complianceRate * 100).round();
    final dispensed = patient.dispenseRecords.isEmpty
        ? 8
        : patient.dispenseRecords.length;
    final safetyWarning = patient.isWithinDispensingCooldown();
    final isActive = request.status != RequestStatus.rejected;

    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _medicationKpis(
            context,
            adherence,
            patient.currentDose,
            lastDispense,
            safetyWarning,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final current = Column(
                children: [
                  _currentMedicationPanel(context, patient, request, isActive),
                  const SizedBox(height: 14),
                  _medicationSafetyPanel(context, safetyWarning),
                  const SizedBox(height: 14),
                  _doseHistoryPanel(context, patient),
                  const SizedBox(height: 14),
                  _adherencePanel(context, adherence, dispensed),
                ],
              );
              final history = Column(
                children: [
                  _dispensingTimeline(context, patient, lastDispense),
                  const SizedBox(height: 14),
                  _medicationHistoryPanel(context, patient),
                  const SizedBox(height: 14),
                  _upcomingMedicationPanel(context, patient, nextDispense),
                  const SizedBox(height: 14),
                  _prescriptionPanel(context, patient, request),
                  const SizedBox(height: 14),
                  _pharmacyPanel(
                    context,
                    patient,
                    provider,
                    dispensed,
                    nextDispense,
                  ),
                ],
              );
              if (constraints.maxWidth >= 1050) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: current),
                    const SizedBox(width: 16),
                    Expanded(child: history),
                  ],
                );
              }
              return Column(
                children: [current, const SizedBox(height: 14), history],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _medicationKpis(
    BuildContext context,
    int adherence,
    String dose,
    String lastDispense,
    bool warning,
  ) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _historyKpi(
        context.tr('medication_adherence'),
        '$adherence%',
        LucideIcons.target,
        Colors.teal,
      ),
      _historyKpi(
        context.tr('usage_duration'),
        context.isArabic ? '3 أشهر' : '3 months',
        LucideIcons.refreshCw,
        Colors.purple,
      ),
      _historyKpi(
        context.tr('current_dose'),
        context.mounjaroDoseLabel(dose),
        LucideIcons.pill,
        AppColors.warning,
      ),
      _historyKpi(
        context.tr('last_dispense_date'),
        lastDispense,
        LucideIcons.calendarDays,
        Colors.blue,
      ),
      _historyKpi(
        context.tr('medication_safety'),
        warning ? context.tr('requires_review') : context.tr('no_issues'),
        LucideIcons.shieldCheck,
        warning ? AppColors.warning : AppColors.success,
      ),
    ],
  );

  Widget _currentMedicationPanel(
    BuildContext context,
    Patient patient,
    DemoTreatmentRequest request,
    bool active,
  ) => _overviewCard(context.tr('current_medication'), LucideIcons.pill, [
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.syringe,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.currentMedicationEn,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Tirzepatide',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _logTypeChip(
            active ? context.tr('status_active') : context.tr('rejected'),
            active ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _medicationFact(
          context.tr('current_dose'),
          context.mounjaroDoseLabel(patient.currentDose),
          LucideIcons.pill,
        ),
        _medicationFact(
          context.tr('frequency'),
          context.tr('weekly'),
          LucideIcons.clock,
        ),
        _medicationFact(
          context.tr('route'),
          context.tr('subcutaneous'),
          LucideIcons.syringe,
        ),
        _medicationFact(
          context.tr('start_date'),
          '2026-03-12',
          LucideIcons.calendar,
        ),
        _medicationFact(
          context.tr('prescribing_physician'),
          context.tr('doc_name'),
          LucideIcons.userRound,
        ),
        _medicationFact(
          context.tr('indication'),
          patient.getLocalizedMedicalConditions(context).join('، '),
          LucideIcons.stethoscope,
        ),
      ],
    ),
  ]);

  Widget _medicationFact(String label, String value, IconData icon) =>
      Container(
        width: 205,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _medicationSafetyPanel(BuildContext context, bool warning) {
    final checks = [
      (
        context.tr('interaction_check'),
        context.tr('no_issues'),
        LucideIcons.gitCompareArrows,
      ),
      (
        context.tr('allergy_check'),
        context.tr('no_allergies'),
        LucideIcons.shieldCheck,
      ),
      (
        context.tr('duplicate_check'),
        warning
            ? context.tr('recent_dispense_warning')
            : context.tr('no_duplicate_therapy'),
        LucideIcons.copyCheck,
      ),
      (
        context.tr('contraindication_check'),
        context.tr('passed'),
        LucideIcons.circleCheck,
      ),
      (
        context.tr('dose_validation'),
        context.tr('passed'),
        LucideIcons.badgeCheck,
      ),
      (
        context.tr('approval_validity'),
        context.tr('valid'),
        LucideIcons.fileCheck2,
      ),
    ];
    return _overviewCard(
      context.tr('medication_safety'),
      LucideIcons.shieldAlert,
      [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: checks.map((item) {
            final warn = warning && item.$1 == context.tr('duplicate_check');
            final color = warn ? AppColors.warning : AppColors.success;
            return Container(
              width: 205,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withValues(alpha: .25)),
              ),
              child: Row(
                children: [
                  Icon(item.$3, color: color, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          item.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dispensingTimeline(
    BuildContext context,
    Patient patient,
    String fallbackDate,
  ) {
    final records = patient.dispenseRecords.reversed.take(6).toList();
    final demoDates = [
      fallbackDate,
      '2026-06-05',
      '2026-05-29',
      '2026-05-22',
      '2026-05-15',
      '2026-05-08',
    ];
    return _overviewCard(
      context.tr('dispensing_timeline'),
      LucideIcons.calendarDays,
      [
        for (var i = 0; i < 6; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: i == 5
                  ? null
                  : Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i == 4 ? AppColors.error : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: Text(
                    i < records.length ? records[i].date : demoDates[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mounjaro ${context.mounjaroDoseLabel(patient.currentDose)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        context.tr('subcutaneous_weekly'),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _logTypeChip(
                  i == 4 ? context.tr('delayed') : context.tr('dispensed'),
                  i == 4 ? AppColors.error : AppColors.success,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _medicationHistoryPanel(BuildContext context, Patient patient) =>
      _overviewCard(context.tr('medication_history'), LucideIcons.history, [
        _medicationHistoryRow(
          context,
          name: 'Mounjaro 5 mg',
          period: '2026-02-01 — 2026-03-11',
          status: context.tr('completed'),
          reason: context.tr('dose_escalation'),
          active: false,
        ),
        const SizedBox(height: 8),
        _medicationHistoryRow(
          context,
          name: 'Mounjaro ${context.mounjaroDoseLabel(patient.currentDose)}',
          period: '2026-03-12 — ${context.tr('current')}',
          status: context.tr('active'),
          reason: context.tr('current_treatment'),
          active: true,
        ),
      ]);

  Widget _medicationHistoryRow(
    BuildContext context, {
    required String name,
    required String period,
    required String status,
    required String reason,
    required bool active,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: active
          ? AppColors.success.withValues(alpha: .06)
          : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(
          active ? LucideIcons.circleCheck : LucideIcons.circleStop,
          color: active ? AppColors.success : AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                period,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                reason,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _logTypeChip(
          status,
          active ? AppColors.success : AppColors.textSecondary,
        ),
      ],
    ),
  );

  Widget _doseHistoryPanel(BuildContext context, Patient patient) {
    final doses = patient.doseHistory.isEmpty
        ? const ['2.5 mg', '5 mg', '7.5 mg', '10 mg']
        : patient.doseHistory;
    return _overviewCard(context.tr('dose_history'), LucideIcons.trendingUp, [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < doses.length; i++) ...[
            _logTypeChip(
              context.mounjaroDoseLabel(doses[i]),
              i == doses.length - 1
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            if (i < doses.length - 1)
              const Icon(LucideIcons.arrowRight, size: 16),
          ],
        ],
      ),
    ]);
  }

  Widget _adherencePanel(BuildContext context, int adherence, int completed) =>
      _overviewCard(context.tr('medication_adherence'), LucideIcons.target, [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: adherence / 100,
            minHeight: 10,
            color: AppColors.success,
            backgroundColor: AppColors.border,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _miniStat(context.tr('expected_doses'), '10')),
            Expanded(child: _miniStat(context.tr('completed'), '$completed')),
            Expanded(child: _miniStat(context.tr('missed'), '1')),
            Expanded(child: _miniStat(context.tr('delayed'), '1')),
          ],
        ),
      ]);

  Widget _miniStat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      ),
      Text(
        label,
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _upcomingMedicationPanel(
    BuildContext context,
    Patient patient,
    String date,
  ) => _overviewCard(
    context.tr('upcoming_medication_event'),
    LucideIcons.calendarClock,
    [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendarClock, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('next_dispense_eligible'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$date · ${context.mounjaroDoseLabel(patient.currentDose)}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _logTypeChip(context.tr('upcoming'), AppColors.warning),
          ],
        ),
      ),
    ],
  );

  Widget _prescriptionPanel(
    BuildContext context,
    Patient patient,
    DemoTreatmentRequest request,
  ) {
    final plan = context.read<DataProvider>().getPlanForPatient(patient.id);
    return _overviewCard(
      context.tr('prescription_details'),
      LucideIcons.fileText,
      [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _medicationFact(
              context.tr('prescription_id'),
              request.id,
              LucideIcons.hash,
            ),
            _medicationFact(
              context.tr('prescribing_physician'),
              plan?.doctorName ?? '—',
              LucideIcons.userRound,
            ),
            _medicationFact(
              context.tr('date_issued'),
              _formatDate(request.createdAt),
              LucideIcons.calendar,
            ),
            _medicationFact(
              context.tr('valid_until'),
              plan == null ? '—' : _formatDate(plan.prescriptionValidUntil),
              LucideIcons.calendarCheck,
            ),
            _medicationFact(
              context.tr('quantity'),
              plan?.medicationQuantity.toString() ?? '—',
              LucideIcons.package,
            ),
          ],
        ),
      ],
    );
  }

  Widget _pharmacyPanel(
    BuildContext context,
    Patient patient,
    DataProvider provider,
    int dispensed,
    String nextDate,
  ) {
    final facility = patient.lastDispensingCenterId == null
        ? context.tr('clinical_brand')
        : provider.dispensingFacilityLabel(
            context,
            patient.lastDispensingCenterId,
          );
    return _overviewCard(
      context.tr('pharmacy_information'),
      LucideIcons.store,
      [
        _overviewLine(context.tr('pharmacy'), facility),
        _overviewLine(
          context.tr('last_dispense_date'),
          patient.lastDispensingDate ?? '—',
        ),
        _overviewLine(context.tr('dispensed_doses'), '$dispensed'),
        _overviewLine(context.tr('next_dispense_eligible'), nextDate),
      ],
    );
  }

  Widget _buildLabsTab(BuildContext context, Patient patient) {
    final results = patient.labResults;
    final filteredResults = results.where((result) {
      final query = _labQuery.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          result.nameEn.toLowerCase().contains(query) ||
          result.nameAr.contains(_labQuery.trim()) ||
          result.testCode.toLowerCase().contains(query);
      final matchesCategory =
          _labCategory == 'all' || result.categoryEn == _labCategory;
      final abnormal = _isAbnormalLab(result);
      final matchesStatus =
          _labStatus == 'all' ||
          (_labStatus == 'abnormal' && abnormal) ||
          (_labStatus == 'normal' && !abnormal);
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, viewport) => ListView(
          padding: const EdgeInsets.all(22),
          children: [
            if (viewport.maxWidth >= 1180)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 285,
                      child: Directionality(
                        textDirection: Directionality.of(context),
                        child: Column(
                          children: [
                            _latestLabOrderPanel(context, results),
                            const SizedBox(height: 14),
                            _labFiltersPanel(context, results),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Directionality(
                        textDirection: Directionality.of(context),
                        child: Column(
                          children: [
                            _labSummaryGrid(context, results),
                            const SizedBox(height: 14),
                            _labTrendsPanel(context, patient, results),
                            const SizedBox(height: 14),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Directionality(
                                      textDirection: Directionality.of(context),
                                      child: Column(
                                        children: [
                                          _latestLabResultsPanel(
                                            context,
                                            filteredResults,
                                          ),
                                          const SizedBox(height: 14),
                                          _labCategoriesPanel(context),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 270,
                                    child: Directionality(
                                      textDirection: Directionality.of(context),
                                      child: Column(
                                        children: [
                                          _clinicalLabNotePanel(
                                            context,
                                            results,
                                          ),
                                          const SizedBox(height: 14),
                                          _previousLabTestsPanel(
                                            context,
                                            results,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _labSummaryGrid(context, results),
              const SizedBox(height: 14),
              _labTrendsPanel(context, patient, results),
              const SizedBox(height: 14),
              _latestLabOrderPanel(context, results),
              const SizedBox(height: 14),
              _labFiltersPanel(context, results),
              const SizedBox(height: 14),
              _latestLabResultsPanel(context, filteredResults),
              const SizedBox(height: 14),
              _clinicalLabNotePanel(context, results),
              const SizedBox(height: 14),
              _previousLabTestsPanel(context, results),
              const SizedBox(height: 14),
              _labCategoriesPanel(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _labSummaryGrid(
    BuildContext context,
    List<PatientLabResult> results,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final total = results.length;
      final abnormal = results.where(_isAbnormalLab).length;
      final dates = results.map((r) => r.date).toList()..sort();
      final cards = [
        _historyKpi(
          context.isArabic ? 'النتائج الطبيعية' : 'Normal results',
          '${total - abnormal}',
          LucideIcons.chartNoAxesCombined,
          AppColors.success,
        ),
        _historyKpi(
          context.isArabic ? 'آخر فحص' : 'Latest test',
          dates.isEmpty ? '—' : dates.last,
          LucideIcons.calendarDays,
          Colors.blue,
        ),
        _historyKpi(
          context.isArabic ? 'النتائج غير الطبيعية' : 'Abnormal results',
          '$abnormal',
          LucideIcons.triangleAlert,
          AppColors.error,
        ),
        _historyKpi(
          context.isArabic ? 'إجمالي الفحوصات' : 'Total tests',
          '$total',
          LucideIcons.flaskConical,
          Colors.purple,
        ),
      ];
      final count = constraints.maxWidth >= 820
          ? 4
          : constraints.maxWidth >= 440
          ? 2
          : 1;
      final width = (constraints.maxWidth - ((count - 1) * 12)) / count;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((card) => SizedBox(width: width, child: card))
            .toList(),
      );
    },
  );

  bool _isAbnormalLab(PatientLabResult result) {
    final range = result.referenceRange.trim();
    if (range.startsWith('<')) {
      final limit = double.tryParse(range.substring(1).trim());
      return limit != null && result.value >= limit;
    }
    if (range.startsWith('>')) {
      final limit = double.tryParse(range.substring(1).trim());
      return limit != null && result.value <= limit;
    }
    final bounds = range.split(RegExp(r'\s*[–-]\s*'));
    if (bounds.length != 2) return false;
    final low = double.tryParse(bounds[0]);
    final high = double.tryParse(bounds[1]);
    return low != null &&
        high != null &&
        (result.value < low || result.value > high);
  }

  Widget _labTrendsPanel(
    BuildContext context,
    Patient patient,
    List<PatientLabResult> results,
  ) {
    final charts = <(String, List<double>, String, Color)>[
      (
        context.isArabic ? 'الوزن' : 'Weight',
        patient.weightHistory,
        '${patient.weight.toStringAsFixed(1)} kg',
        AppColors.success,
      ),
    ];
    for (final code in ['LDL cholesterol', 'Fasting glucose', 'HbA1c']) {
      final matching = results.where((r) => r.testCode == code).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (matching.isEmpty) continue;
      final latest = matching.last;
      charts.add((
        code == 'LDL cholesterol' ? 'LDL' : latest.nameEn,
        matching.map((r) => r.value).toList(),
        '${latest.value.toStringAsFixed(code == 'HbA1c' ? 1 : 0)} ${latest.unit}',
        code == 'HbA1c' ? AppColors.error : AppColors.warning,
      ));
    }
    return _overviewCard(
      context.isArabic ? 'المؤشرات المسجلة' : 'Recorded measurements',
      LucideIcons.chartNoAxesCombined,
      [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 30) / 4
                : constraints.maxWidth >= 520
                ? (constraints.maxWidth - 10) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: charts
                  .map(
                    (c) => SizedBox(
                      width: width,
                      child: _labTrendCard(c.$1, c.$2, c.$3, c.$4),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _labTrendCard(
    String title,
    List<double> values,
    String value,
    Color color,
  ) => Container(
    height: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: values.reduce((a, b) => a < b ? a : b) * .9,
              maxY: values.reduce((a, b) => a > b ? a : b) * 1.08,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                  color: color,
                  barWidth: 2,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: .08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _latestLabResultsPanel(
    BuildContext context,
    List<PatientLabResult> results,
  ) => _overviewCard(
    context.isArabic ? 'أحدث نتائج المختبر' : 'Latest laboratory results',
    LucideIcons.table2,
    [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 38,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 46,
          columns: [
            for (final h
                in (context.isArabic
                    ? [
                        'اسم الفحص',
                        'النتيجة',
                        'الوحدة',
                        'المدى المرجعي',
                        'الحالة',
                        'تاريخ الفحص',
                      ]
                    : [
                        'Test',
                        'Result',
                        'Unit',
                        'Reference range',
                        'Status',
                        'Date',
                      ]))
              DataColumn(
                label: Text(
                  h,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
          rows: results.map((r) {
            final abnormal = _isAbnormalLab(r);
            return DataRow(
              onSelectChanged: (_) => _showLabResultDetails(context, r),
              cells: [
                DataCell(
                  Text(
                    context.isArabic ? r.nameAr : r.nameEn,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(
                  Text(
                    r.value.toStringAsFixed(r.value % 1 == 0 ? 0 : 1),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: abnormal ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ),
                DataCell(Text(r.unit)),
                DataCell(Text(r.referenceRange)),
                DataCell(
                  _logTypeChip(
                    abnormal
                        ? (context.isArabic ? 'غير طبيعي' : 'Abnormal')
                        : (context.isArabic ? 'طبيعي' : 'Normal'),
                    abnormal ? AppColors.error : AppColors.success,
                  ),
                ),
                DataCell(Text(r.date)),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );

  Widget _latestLabOrderPanel(
    BuildContext context,
    List<PatientLabResult> results,
  ) {
    final sorted = [...results]..sort((a, b) => a.date.compareTo(b.date));
    final latest = sorted.isEmpty ? null : sorted.last;
    return _overviewCard(
      context.isArabic ? 'آخر نتيجة' : 'Latest result',
      LucideIcons.fileCheck2,
      [
        _overviewLine(
          context.isArabic ? 'الحالة' : 'Status',
          latest == null
              ? (context.isArabic ? 'لا توجد نتائج' : 'No results')
              : (context.isArabic ? 'مكتملة' : 'Completed'),
        ),
        _overviewLine(
          context.isArabic ? 'التاريخ' : 'Date',
          latest?.date ?? '—',
        ),
        _overviewLine(
          context.isArabic ? 'المختبر' : 'Laboratory',
          latest?.source ?? '—',
        ),
        _overviewLine(
          context.isArabic ? 'رقم الطلب' : 'Order ID',
          latest?.id ?? '—',
        ),
      ],
    );
  }

  Widget _labFiltersPanel(
    BuildContext context,
    List<PatientLabResult> results,
  ) => _overviewCard(
    context.isArabic ? 'تصفية النتائج' : 'Filter results',
    LucideIcons.listFilter,
    [
      TextField(
        onChanged: (value) => setState(() => _labQuery = value),
        decoration: InputDecoration(
          hintText: context.isArabic ? 'البحث عن فحص...' : 'Search tests...',
          prefixIcon: const Icon(LucideIcons.search, size: 17),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _labCategory,
        decoration: InputDecoration(
          labelText: context.isArabic ? 'الفئة' : 'Category',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: <String>{'all', ...results.map((r) => r.categoryEn)}
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value == 'all'
                      ? (context.isArabic ? 'كل الفئات' : 'All categories')
                      : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _labCategory = value ?? 'all'),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _labStatus,
        decoration: InputDecoration(
          labelText: context.isArabic ? 'الحالة' : 'Status',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: 'all',
            child: Text(context.isArabic ? 'كل الحالات' : 'All statuses'),
          ),
          DropdownMenuItem(
            value: 'normal',
            child: Text(context.isArabic ? 'طبيعي' : 'Normal'),
          ),
          DropdownMenuItem(
            value: 'abnormal',
            child: Text(context.isArabic ? 'غير طبيعي' : 'Abnormal'),
          ),
        ],
        onChanged: (value) => setState(() => _labStatus = value ?? 'all'),
      ),
    ],
  );

  Future<void> _showLabResultDetails(
    BuildContext context,
    PatientLabResult result,
  ) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(context.isArabic ? result.nameAr : result.nameEn),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _overviewLine(
            context.isArabic ? 'النتيجة' : 'Result',
            '${result.value} ${result.unit}',
          ),
          _overviewLine(
            context.isArabic ? 'المدى المرجعي' : 'Reference range',
            result.referenceRange,
          ),
          _overviewLine(
            context.isArabic ? 'تاريخ الفحص' : 'Collected at',
            result.date,
          ),
          _overviewLine(context.isArabic ? 'المصدر' : 'Source', result.source),
          if (result.notes.isNotEmpty)
            _overviewLine(context.isArabic ? 'ملاحظات' : 'Notes', result.notes),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.isArabic ? 'إغلاق' : 'Close'),
        ),
      ],
    ),
  );

  Widget _clinicalLabNotePanel(
    BuildContext context,
    List<PatientLabResult> results,
  ) => _overviewCard(
    context.isArabic ? 'ملاحظات طبية' : 'Clinical notes',
    LucideIcons.notebookPen,
    [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          results.where(_isAbnormalLab).isEmpty
              ? (context.isArabic
                    ? 'لا توجد نتائج خارج النطاق المرجعي المسجل.'
                    : 'No recorded results fall outside their listed reference ranges.')
              : (context.isArabic
                    ? 'توجد ${results.where(_isAbnormalLab).length} نتيجة خارج النطاق المرجعي المسجل. راجع النتائج قبل اتخاذ قرار سريري.'
                    : '${results.where(_isAbnormalLab).length} results fall outside their listed reference ranges. Review the results before making a clinical decision.'),
          style: const TextStyle(fontSize: 11, height: 1.5),
        ),
      ),
    ],
  );

  Widget _previousLabTestsPanel(
    BuildContext context,
    List<PatientLabResult> results,
  ) {
    final dates = <String, int>{};
    for (final result in results) {
      dates.update(result.date, (count) => count + 1, ifAbsent: () => 1);
    }
    return _overviewCard(
      context.isArabic ? 'سجل الفحوصات السابقة' : 'Previous tests',
      LucideIcons.history,
      [
        if (dates.isEmpty)
          Text(context.isArabic ? 'لا توجد فحوصات مسجلة' : 'No recorded tests'),
        for (final test in dates.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.circleCheck,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${test.value} ${context.isArabic ? 'فحص' : 'tests'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _labCategoriesPanel(BuildContext context) => _overviewCard(
    context.isArabic ? 'الفئات الشائعة' : 'Common categories',
    LucideIcons.flaskConical,
    [
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children:
            (context.isArabic
                    ? [
                        'السكر ومؤشرات السكري',
                        'دهون الدم',
                        'وظائف الكلى',
                        'الهرمونات',
                        'الفيتامينات',
                        'تحليل الدم العام',
                      ]
                    : [
                        'Diabetes markers',
                        'Blood lipids',
                        'Kidney function',
                        'Hormones',
                        'Vitamins',
                        'Complete blood count',
                      ])
                .map(
                  (name) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .05),
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.flaskConical,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    ],
  );

  Widget _buildEligibilityTab(BuildContext context, Patient patient) {
    final request = context.watch<JourneyProvider>().request;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _workspaceTitle(
          context,
          context.tr('eligibility'),
          LucideIcons.shieldCheck,
        ),
        ClinicalEligibilityBanner(patient: patient),
        const SizedBox(height: 18),
        ...request.criteria.map(
          (c) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    c.result == CriterionResult.pass
                        ? LucideIcons.checkCircle
                        : c.result == CriterionResult.missing
                        ? LucideIcons.helpCircle
                        : LucideIcons.alertTriangle,
                    color: c.result == CriterionResult.pass
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.isArabic ? c.labelAr : c.labelEn,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.isArabic ? c.evidenceAr : c.evidenceEn}\n${context.isArabic ? c.explanationAr : c.explanationEn}',
                        ),
                        const SizedBox(height: 8),
                        _logTypeChip(
                          c.result.name.toUpperCase(),
                          c.result == CriterionResult.pass
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.isArabic
              ? 'يوفر الذكاء الاصطناعي دعمًا للقرار فقط. القرار النهائي للمراجع البشري المخول.'
              : 'AI provides decision support only. The final decision belongs to the authorized human reviewer.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(BuildContext context) {
    final request = context.watch<JourneyProvider>().request;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _workspaceTitle(
          context,
          context.tr('treatment_requests'),
          LucideIcons.fileText,
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(LucideIcons.fileCheck2)),
            title: Text(
              '${request.id} • ${request.medication}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_formatDate(request.createdAt)} • ${_requestStatusLabel(context, request.status)}',
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const JourneyScreen())),
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: Text(context.isArabic ? 'فتح الطلب' : 'Open request'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(BuildContext context, Patient patient) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      _workspaceTitle(context, context.tr('documents'), LucideIcons.folderOpen),
      if (patient.clinicalAttachments.isEmpty)
        _emptyWorkspace(
          context,
          context.isArabic
              ? 'لا توجد مستندات مرفقة بهذه الحالة.'
              : 'No documents are attached to this patient record.',
        )
      else
        ...patient.clinicalAttachments.map(
          (doc) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(doc.fileName),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _overviewLine(
                        context.isArabic ? 'نوع المستند' : 'Document type',
                        doc.category,
                      ),
                      _overviewLine(
                        context.isArabic ? 'نوع الملف' : 'File type',
                        doc.mimeType,
                      ),
                      _overviewLine(
                        context.isArabic ? 'تاريخ الرفع' : 'Uploaded at',
                        _formatDate(doc.uploadedAt),
                      ),
                      _overviewLine(
                        context.isArabic ? 'الحالة' : 'Status',
                        context.isArabic
                            ? 'متاح محلياً للمعاينة'
                            : 'Available for local preview',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.isArabic ? 'إغلاق' : 'Close'),
                    ),
                  ],
                ),
              ),
              leading: Icon(
                doc.isPdf ? LucideIcons.fileText : LucideIcons.image,
              ),
              title: Text(doc.fileName),
              subtitle: Text(_formatDate(doc.uploadedAt)),
              trailing: _logTypeChip(
                context.isArabic ? 'متاح محليًا' : 'Local demo',
                AppColors.primary,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildAppointmentsTab(BuildContext context, Patient patient) {
    final provider = context.watch<DataProvider>();
    final access = context.watch<AccessControlProvider>();
    final appointments = provider.appointmentsFor(patient.id);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _workspaceTitle(
          context,
          context.tr('appointments'),
          LucideIcons.calendarDays,
        ),
        if (access.can(AppPermission.manageAppointments)) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ElevatedButton.icon(
              onPressed: () => _createAppointment(context, patient),
              icon: const Icon(LucideIcons.calendarPlus),
              label: Text(
                context.isArabic ? 'إنشاء موعد' : 'Create appointment',
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (appointments.isEmpty)
          _emptyWorkspace(
            context,
            context.isArabic
                ? 'لا توجد مواعيد مسجلة.'
                : 'No appointments are recorded.',
          )
        else
          ...appointments.map(
            (appointment) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: Icon(
                  appointment.status == AppointmentStatus.completed
                      ? LucideIcons.calendarCheck
                      : LucideIcons.calendarClock,
                  color: appointment.status == AppointmentStatus.completed
                      ? AppColors.success
                      : appointment.status == AppointmentStatus.cancelled
                      ? AppColors.error
                      : AppColors.primary,
                ),
                title: Text(appointment.purpose),
                subtitle: Text(
                  '${_formatDate(appointment.dateTime)} · ${appointment.doctor}',
                ),
                trailing:
                    access.can(AppPermission.manageAppointments) &&
                        appointment.status == AppointmentStatus.scheduled
                    ? PopupMenuButton<String>(
                        onSelected: (action) => _handleAppointmentAction(
                          context,
                          patient,
                          appointment,
                          action,
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Text(
                              context.isArabic
                                  ? 'عرض التفاصيل'
                                  : 'View details',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'reschedule',
                            child: Text(
                              context.isArabic ? 'إعادة جدولة' : 'Reschedule',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Text(
                              context.isArabic ? 'إلغاء الموعد' : 'Cancel',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'missed',
                            child: Text(
                              context.isArabic
                                  ? 'تسجيل كموعد فائت'
                                  : 'Mark missed',
                            ),
                          ),
                        ],
                      )
                    : _logTypeChip(
                        appointment.status.name,
                        appointment.status == AppointmentStatus.completed
                            ? AppColors.success
                            : appointment.status == AppointmentStatus.cancelled
                            ? AppColors.error
                            : AppColors.primary,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _createAppointment(BuildContext context, Patient patient) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    context.read<DataProvider>().createAppointment(
      patientId: patient.id,
      dateTime: DateTime(date.year, date.month, date.day, 10, 30),
      doctor: context.tr('doc_name'),
      purpose: context.isArabic ? 'متابعة العلاج' : 'Treatment follow-up',
    );
  }

  Future<void> _handleAppointmentAction(
    BuildContext context,
    Patient patient,
    PatientAppointment appointment,
    String action,
  ) async {
    final provider = context.read<DataProvider>();
    if (action == 'cancel') {
      provider.cancelAppointment(patient.id, appointment.id);
      return;
    }
    if (action == 'reschedule') {
      final date = await showDatePicker(
        context: context,
        initialDate: appointment.dateTime.add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date != null && context.mounted) {
        provider.rescheduleAppointment(
          patient.id,
          appointment.id,
          DateTime(
            date.year,
            date.month,
            date.day,
            appointment.dateTime.hour,
            appointment.dateTime.minute,
          ),
        );
      }
      return;
    }
    if (action == 'missed') {
      provider.markAppointmentMissed(patient.id, appointment.id);
      return;
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(appointment.purpose),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _overviewLine(
              context.isArabic ? 'التاريخ' : 'Date',
              _formatDate(appointment.dateTime),
            ),
            _overviewLine(
              context.isArabic ? 'الطبيب' : 'Doctor',
              appointment.doctor,
            ),
            _overviewLine(
              context.isArabic ? 'الحالة' : 'Status',
              appointment.status.name,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _workspaceTitle(BuildContext context, String title, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _logTypeChip(
              context.isArabic ? 'سجل المريض' : 'Patient 360',
              AppColors.primary,
            ),
          ],
        ),
      );
  Widget _emptyWorkspace(BuildContext context, String message) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(42),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 34, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _requestStatusLabel(BuildContext context, RequestStatus status) =>
      switch (status) {
        RequestStatus.draft => context.isArabic ? 'مسودة' : 'Draft',
        RequestStatus.submitted => context.isArabic ? 'مرسل' : 'Submitted',
        RequestStatus.assessing =>
          context.isArabic ? 'قيد التقييم' : 'Assessing',
        RequestStatus.needsInformation =>
          context.isArabic ? 'يحتاج معلومات' : 'Information required',
        RequestStatus.underReview =>
          context.isArabic ? 'قيد المراجعة' : 'Under review',
        RequestStatus.approved => context.isArabic ? 'موافق عليه' : 'Approved',
        RequestStatus.rejected => context.isArabic ? 'مرفوض' : 'Rejected',
        RequestStatus.readyToDispense =>
          context.isArabic ? 'جاهز للصرف' : 'Ready to dispense',
        RequestStatus.dispensed => context.isArabic ? 'تم الصرف' : 'Dispensed',
        RequestStatus.monitoring => context.isArabic ? 'متابعة' : 'Monitoring',
        RequestStatus.renewalDue =>
          context.isArabic ? 'التجديد مستحق' : 'Renewal due',
        RequestStatus.completed => context.isArabic ? 'مكتمل' : 'Completed',
        RequestStatus.expired => context.isArabic ? 'منتهي' : 'Expired',
        RequestStatus.cancelled => context.isArabic ? 'ملغي' : 'Cancelled',
      };

  Widget _buildActivityLogTab(
    BuildContext context,
    DataProvider provider,
    Patient patient,
  ) {
    final patientLogs = provider.logs
        .where((l) => l.patientId == patient.id)
        .toList();

    if (patientLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              context.tr('no_activity_logs'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
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
          'dispense' => (
            AppColors.success,
            LucideIcons.package,
            context.tr('log_type_dispense'),
          ),
          'care_plan' => (
            AppColors.primary,
            LucideIcons.clipboardList,
            context.tr('log_type_care_plan'),
          ),
          'registration' => (
            AppColors.textPrimary,
            LucideIcons.userPlus,
            context.tr('log_type_registration'),
          ),
          'clinical_review' => (
            AppColors.warning,
            LucideIcons.stethoscope,
            context.tr('log_type_clinical_review'),
          ),
          'medication_adherence' => (
            AppColors.primary,
            LucideIcons.pill,
            context.isArabic ? 'الالتزام الدوائي' : 'Medication adherence',
          ),
          _ => (
            AppColors.textSecondary,
            LucideIcons.activity,
            context.tr('log_type_other'),
          ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
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
                            _logTypeChip(
                              log.getLocalizedStatus(context),
                              statusColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.getLocalizedAction(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      if (isCarePlan) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr('log_not_dispense_hint'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                          ),
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
                          color: kind == 'dispense'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: kind == 'dispense'
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        log.formatTimestamp(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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

class _CareMetric {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final double? progress;
  final Color? color;

  const _CareMetric(
    this.icon,
    this.label,
    this.value,
    this.detail, {
    this.progress,
    this.color,
  });
}
