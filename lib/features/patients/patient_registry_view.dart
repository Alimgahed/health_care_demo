import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/demo/demo_session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/platform_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../clinical/register_patient_dialog.dart';
import '../treatment_plan/web/patient_360_view.dart';

class PatientRegistryView extends StatefulWidget {
  final void Function(Patient patient, int tabIndex)? onOpenPatient;

  const PatientRegistryView({super.key, this.onOpenPatient});

  @override
  State<PatientRegistryView> createState() => _PatientRegistryViewState();
}

class _PatientRegistryViewState extends State<PatientRegistryView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _residency = 'all';
  int _page = 0;
  static const _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(Patient patient, [int tab = 0]) {
    context.read<DemoSessionProvider>().selectPatient(patient.id);
    if (widget.onOpenPatient != null) {
      widget.onOpenPatient!(patient, tab);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Patient360View(patient: patient, initialTabIndex: tab),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final patients = data.patients.where((patient) {
      final query = _query.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          patient.getLocalizedFullName(context).toLowerCase().contains(query) ||
          patient.emiratesId.contains(query) ||
          patient.id.toLowerCase().contains(query);
      final matchesResidency =
          _residency == 'all' ||
          (_residency == 'citizen' &&
              patient.residencyStatus == ResidencyStatus.citizen) ||
          (_residency == 'resident' &&
              patient.residencyStatus == ResidencyStatus.resident);
      return matchesQuery && matchesResidency;
    }).toList();
    final pages = (patients.length / _pageSize).ceil().clamp(1, 999999);
    final page = _page.clamp(0, pages - 1);
    final visible = patients.skip(page * _pageSize).take(_pageSize).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 950;
        return ColoredBox(
          color: AppColors.background,
          child: Padding(
            padding: AppLayout.pagePadding(constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _registryTitle(context),
                      _registerButton(context),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _registryTitle(context)),
                      _registerButton(context),
                    ],
                  ),
                const SizedBox(height: 16),
                _kpis(context, data, compact: compact),
                const SizedBox(height: 14),
                _filters(context, compact: compact),
                const SizedBox(height: 12),
                Expanded(
                  child: patients.isEmpty
                      ? PlatformStateView(
                          kind: data.patients.isEmpty
                              ? PlatformStateKind.empty
                              : PlatformStateKind.noResults,
                          title: context.isArabic
                              ? (data.patients.isEmpty
                                    ? 'لا يوجد مرضى بعد'
                                    : 'لا توجد نتائج')
                              : (data.patients.isEmpty
                                    ? 'No patients yet'
                                    : 'No matching patients'),
                          message: context.isArabic
                              ? (data.patients.isEmpty
                                    ? 'سجل مريضاً لبدء المتابعة السريرية.'
                                    : 'غيّر البحث أو عامل التصفية لعرض المرضى.')
                              : (data.patients.isEmpty
                                    ? 'Register a patient to begin clinical follow-up.'
                                    : 'Try another name, identifier, or residency filter.'),
                          actionLabel: data.patients.isEmpty
                              ? context.tr('register_patient')
                              : (context.isArabic
                                    ? 'مسح عوامل التصفية'
                                    : 'Clear filters'),
                          onAction: data.patients.isEmpty
                              ? () async {
                                  await RegisterPatientDialog.show(context);
                                }
                              : () => setState(() {
                                  _searchController.clear();
                                  _query = '';
                                  _residency = 'all';
                                  _page = 0;
                                }),
                        )
                      : compact
                      ? _compactList(context, visible)
                      : _table(context, visible),
                ),
                const SizedBox(height: 10),
                _pagination(context, patients.length, page, pages),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _registryTitle(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('patient_registry'),
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        context.tr('patient_registry_sub'),
        style: TextStyle(color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _registerButton(BuildContext context) => ElevatedButton.icon(
    onPressed: () async {
      await RegisterPatientDialog.show(context);
    },
    icon: const Icon(LucideIcons.userPlus, size: 18),
    label: Text(context.tr('register_patient')),
  );

  Widget _kpis(
    BuildContext context,
    DataProvider data, {
    required bool compact,
  }) {
    final items = [
      (
        data.totalPatientCount,
        context.tr('total_patients'),
        AppColors.info,
        LucideIcons.users,
      ),
      (
        data.activePatientCount,
        context.tr('status_active'),
        AppColors.success,
        LucideIcons.circleCheck,
      ),
      (
        data.eligiblePatientCount,
        context.tr('eligibility'),
        AppColors.error,
        LucideIcons.triangleAlert,
      ),
      (
        data.patientsUnderTreatmentCount,
        context.tr('under_treatment'),
        AppColors.warning,
        LucideIcons.calendarClock,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: compact
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : (constraints.maxWidth - AppSpacing.sm * 3) / 4,
              child: Container(
                height: 92,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: items[i].$3.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(items[i].$4, color: items[i].$3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${items[i].$1}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            items[i].$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
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
    );
  }

  Widget _filters(BuildContext context, {required bool compact}) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: compact
        ? Column(
            children: [
              _searchField(context),
              const SizedBox(height: AppSpacing.xs),
              Wrap(spacing: AppSpacing.xs, children: _residencyChips(context)),
            ],
          )
        : Row(
            children: [
              Expanded(child: _searchField(context)),
              ..._residencyChips(context),
            ],
          ),
  );

  Widget _searchField(BuildContext context) => TextField(
    controller: _searchController,
    onChanged: (value) => setState(() {
      _query = value;
      _page = 0;
    }),
    decoration: InputDecoration(
      hintText: context.tr('search_name_or_id'),
      prefixIcon: const Icon(LucideIcons.search, size: 18),
      border: InputBorder.none,
    ),
  );

  List<Widget> _residencyChips(BuildContext context) => [
    for (final item in [
      ('all', 'all'),
      ('citizen', 'citizens'),
      ('resident', 'residents'),
    ])
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: ChoiceChip(
          label: Text(context.tr(item.$2)),
          selected: _residency == item.$1,
          onSelected: (_) => setState(() {
            _residency = item.$1;
            _page = 0;
          }),
          selectedColor: AppColors.primary.withValues(alpha: .13),
        ),
      ),
  ];

  Widget _compactList(BuildContext context, List<Patient> patients) =>
      ListView.separated(
        itemCount: patients.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, index) {
          final patient = patients[index];
          return Card(
            child: InkWell(
              onTap: () => _open(patient),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.getLocalizedFullName(context),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      patient.id,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _status(context, patient),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _table(BuildContext context, List<Patient> patients) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          _tableRow(context, null, header: true),
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (_, index) =>
                  _tableRow(context, patients[index], shaded: index == 0),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tableRow(
    BuildContext context,
    Patient? patient, {
    bool header = false,
    bool shaded = false,
  }) {
    final textStyle = TextStyle(
      fontSize: 12,
      color: header ? AppColors.textSecondary : AppColors.textPrimary,
      fontWeight: header ? FontWeight.w700 : FontWeight.w500,
    );
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
    return Container(
      height: header ? 43 : 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: header
            ? AppColors.background
            : shaded
            ? AppColors.primary.withValues(alpha: .06)
            : AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: header
                ? Text(context.tr('col_patient'), style: textStyle)
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: .1,
                        ),
                        child: Text(
                          patient!
                              .getLocalizedFullName(context)
                              .substring(0, 1),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              patient.getLocalizedFullName(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (context.read<DataProvider>().getPlanForPatient(
                                  patient.id,
                                ) !=
                                null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.clipboardCheck,
                                    size: 10,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.isArabic
                                        ? 'توجد خطة علاج حالية'
                                        : 'Active treatment plan',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.clipboardX,
                                    size: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.isArabic
                                        ? 'لا توجد خطة علاج'
                                        : 'No active plan',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          cell(header ? context.tr('col_id') : patient!.id, 10),
          cell(
            header
                ? context.tr('col_dose')
                : context.mounjaroDoseLabel(patient!.currentDose),
            13,
          ),
          Expanded(
            flex: 9,
            child: header
                ? Text(context.tr('col_bmi'), style: textStyle)
                : _bmi(context, patient!.bmi),
          ),
          cell(
            header
                ? context.tr('col_residency')
                : patient!.getLocalizedResidency(context),
            11,
          ),
          Expanded(
            flex: 14,
            child: header
                ? Text(context.tr('col_status'), style: textStyle)
                : _status(context, patient!),
          ),
          cell(
            header
                ? context.tr('last_visit')
                : patient!.lastDispensingDate ?? '—',
            12,
          ),
          Expanded(
            flex: 15,
            child: header
                ? Text(context.tr('actions'), style: textStyle)
                : Row(
                    children: [
                      _action(
                        LucideIcons.eye,
                        context.tr('view_details'),
                        () => _open(patient!),
                      ),
                      _action(
                        LucideIcons.clipboardList,
                        context.tr('treatment_plan'),
                        () => _open(patient!, 2),
                      ),
                      _action(
                        LucideIcons.chartNoAxesCombined,
                        context.tr('treatment_journey'),
                        () => _open(patient!, 3),
                      ),
                      _action(
                        LucideIcons.calendarDays,
                        context.tr('appointments'),
                        () => _open(patient!, 9),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bmi(BuildContext context, double bmi) {
    final color = bmi < 18.5
        ? Colors.blue
        : bmi < 25
        ? AppColors.success
        : bmi < 30
        ? AppColors.warning
        : AppColors.error;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Text(
          bmi.toStringAsFixed(1),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _status(BuildContext context, Patient patient) {
    final eligible = patient.programEligibility.eligible;
    final inCooldown = patient.isWithinDispensingCooldown();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final bool isGreen = eligible && !inCooldown;
    final String label = !eligible
        ? context.tr('status_program_ineligible')
        : inCooldown
        ? (isArabic ? 'فترة إعادة الصرف سارية' : 'Refill interval active')
        : (isArabic ? 'مستوفٍ للمعايير السريرية' : 'Clinical criteria met');

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: StatusBadge(
        label: label,
        status: isGreen ? BadgeStatus.success : BadgeStatus.warning,
      ),
    );
  }

  Widget _action(IconData icon, String tooltip, VoidCallback onPressed) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18),
      );

  Widget _pagination(
    BuildContext context,
    int count,
    int page,
    int pages,
  ) => Row(
    children: [
      Text(
        context.tr('patients_pagination', {
          'count': '$count',
          'page': '${page + 1}',
          'total': '$pages',
        }),
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const Spacer(),
      IconButton(
        onPressed: page > 0 ? () => setState(() => _page--) : null,
        icon: Icon(
          context.isArabic ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
        ),
      ),
      for (var i = 0; i < pages.clamp(1, 3); i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: OutlinedButton(
            onPressed: () => setState(() => _page = i),
            style: OutlinedButton.styleFrom(
              backgroundColor: i == page ? AppColors.primary : null,
              foregroundColor: i == page ? Colors.white : AppColors.textPrimary,
              minimumSize: const Size(42, 42),
              padding: EdgeInsets.zero,
            ),
            child: Text('${i + 1}'),
          ),
        ),
      IconButton(
        onPressed: page < pages - 1 ? () => setState(() => _page++) : null,
        icon: Icon(
          context.isArabic ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        ),
      ),
    ],
  );
}
