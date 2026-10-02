import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/mock_data.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../journey/journey_models.dart';
import 'report_analytics_data.dart';
import 'report_export.dart' as report_export;

class ProgramReportsCenter extends StatefulWidget {
  const ProgramReportsCenter({super.key});

  @override
  ProgramReportsCenterState createState() => ProgramReportsCenterState();
}

/// Compatibility route for existing report navigation and widget tests.
class RegionalAnalytics extends ProgramReportsCenter {
  const RegionalAnalytics({super.key});
}

typedef RegionalAnalyticsState = ProgramReportsCenterState;

class ProgramReportsCenterState extends State<ProgramReportsCenter> {
  ReportFilters _filters = const ReportFilters();
  DateTime _refreshedAt = DateTime.now();
  bool _isExporting = false;

  String _text(BuildContext context, String ar, String en) =>
      context.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final source = context.watch<DataProvider>();
    final report = ReportAnalyticsData.derive(
      source,
      _filters,
      now: _refreshedAt,
    );

    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        children: [
          _buildHeader(context, report),
          const SizedBox(height: 16),
          _buildFilters(context, source, report),
          const SizedBox(height: 16),
          _buildKpis(context, report),
          const SizedBox(height: 16),
          _buildJourney(context, report),
          const SizedBox(height: 16),
          _buildClinicalAndDispensing(context, report),
          const SizedBox(height: 16),
          _buildRegionalAndOperations(context, report),
          const SizedBox(height: 16),
          _buildProvidersAndFinance(context, report),
          const SizedBox(height: 16),
          _buildInsightsAndDataBoundaries(context, report),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReportAnalyticsData report) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text(context, 'مركز أداء البرنامج', 'Program performance'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _text(
            context,
            'صورة تشغيلية من سجلات النظام الحالية',
            'Operational results from current application records',
          ),
          style: TextStyle(
            color: Colors.white.withValues(alpha: .75),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _headerTag(
              icon: LucideIcons.database,
              label: _text(
                context,
                'بيانات محلية مشتركة',
                'Shared in-app data',
              ),
            ),
            Text(
              '${_text(context, 'آخر تحديث', 'Updated')}: ${_timeLabel(context, report.generatedAt)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .75),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('reports-refresh'),
          onPressed: _refresh,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: Text(_text(context, 'تحديث البيانات', 'Refresh data')),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: .42)),
          ),
        ),
        FilledButton.icon(
          key: const ValueKey('reports-export'),
          onPressed: _isExporting ? null : () => exportCurrentReport(),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.download, size: 16),
          label: Text(_text(context, 'تصدير CSV', 'Export CSV')),
          style: FilledButton.styleFrom(
            foregroundColor: AppColors.navy,
            backgroundColor: AppColors.accentLight,
          ),
        ),
        PopupMenuButton<String>(
          key: const ValueKey('reports-export-options'),
          tooltip: _text(context, 'خيارات التصدير', 'Export options'),
          enabled: !_isExporting,
          onSelected: (format) => exportCurrentReport(format: format),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'json',
              child: Text(_text(context, 'تنزيل JSON', 'Download JSON')),
            ),
            PopupMenuItem(
              value: 'print',
              child: Text(
                _text(context, 'طباعة / حفظ PDF', 'Print / Save PDF'),
              ),
            ),
          ],
          child: Container(
            height: 48,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.chevronDown,
              color: AppColors.navy,
              size: 17,
            ),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mark = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.chartNoAxesCombined,
              color: AppColors.accentLight,
              size: 22,
            ),
          );
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                mark,
                const SizedBox(width: 14),
                Expanded(child: heading),
                const SizedBox(width: 16),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mark,
                  const SizedBox(width: 14),
                  Expanded(child: heading),
                ],
              ),
              const SizedBox(height: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _headerTag({
    required IconData icon,
    required String label,
    bool accent = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: accent
          ? AppColors.accent.withValues(alpha: .16)
          : Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accent
            ? AppColors.accent.withValues(alpha: .42)
            : Colors.white.withValues(alpha: .16),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: accent ? AppColors.accentLight : Colors.white70,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: accent ? AppColors.accentLight : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _buildFilters(
    BuildContext context,
    DataProvider source,
    ReportAnalyticsData report,
  ) {
    final emirates = source.patients.map((p) => p.emirate).toSet().toList()
      ..sort();
    final centers = source.centers
        .where(
          (center) =>
              _filters.emirate == null || center.region == _filters.emirate,
        )
        .toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _text(context, 'نطاق التقرير', 'Report scope'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '${_dateLabel(report.periodStart)} — ${_dateLabel(report.periodEnd)}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              if (_filters.hasFilters)
                TextButton.icon(
                  key: const ValueKey('reports-reset-filters'),
                  onPressed: () => setState(
                    () => _filters = ReportFilters(
                      periodDays: _filters.periodDays,
                    ),
                  ),
                  icon: const Icon(LucideIcons.rotateCcw, size: 14),
                  label: Text(_text(context, 'مسح التصفية', 'Reset filters')),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _filter<int>(
                key: const ValueKey('reports-period-filter'),
                icon: LucideIcons.calendarRange,
                label: _text(context, 'الفترة', 'Period'),
                value: _filters.periodDays,
                entries: [30, 90, 180, 365]
                    .map(
                      (days) => DropdownMenuItem(
                        value: days,
                        child: Text(_periodName(context, days)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    _update(_filters.copyWith(periodDays: value ?? 180)),
              ),
              _filter<String?>(
                key: const ValueKey('reports-emirate-filter'),
                icon: LucideIcons.mapPin,
                label: _text(context, 'الإمارة', 'Emirate'),
                value: _filters.emirate,
                entries: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_text(context, 'كل الإمارات', 'All emirates')),
                  ),
                  ...emirates.map(
                    (name) => DropdownMenuItem<String?>(
                      value: name,
                      child: Text(_localizedEmirate(context, name)),
                    ),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    emirate: value,
                    clearEmirate: value == null,
                    clearCenter: true,
                  ),
                ),
              ),
              _filter<String?>(
                key: const ValueKey('reports-facility-filter'),
                icon: LucideIcons.building2,
                label: _text(context, 'المنشأة', 'Facility'),
                value: _filters.centerId,
                entries: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_text(context, 'كل المنشآت', 'All facilities')),
                  ),
                  ...centers.map(
                    (center) => DropdownMenuItem<String?>(
                      value: center.id,
                      child: Text(
                        center.getLocalizedName(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    centerId: value,
                    clearCenter: value == null,
                  ),
                ),
              ),
              _filter<ResidencyStatus?>(
                key: const ValueKey('reports-residency-filter'),
                icon: LucideIcons.users,
                label: _text(context, 'فئة الإقامة', 'Residency'),
                value: _filters.residency,
                entries: [
                  DropdownMenuItem<ResidencyStatus?>(
                    value: null,
                    child: Text(_text(context, 'كل الفئات', 'All categories')),
                  ),
                  DropdownMenuItem<ResidencyStatus?>(
                    value: ResidencyStatus.citizen,
                    child: Text(_text(context, 'مواطن', 'Citizen')),
                  ),
                  DropdownMenuItem<ResidencyStatus?>(
                    value: ResidencyStatus.resident,
                    child: Text(_text(context, 'مقيم', 'Resident')),
                  ),
                  DropdownMenuItem<ResidencyStatus?>(
                    value: ResidencyStatus.visitor,
                    child: Text(_text(context, 'زائر', 'Visitor')),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    residency: value,
                    clearResidency: value == null,
                  ),
                ),
              ),
              _filter<String?>(
                key: const ValueKey('reports-care-filter'),
                icon: LucideIcons.heartPulse,
                label: _text(context, 'حالة الخطة', 'Care plan'),
                value: _filters.careStatus,
                entries: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_text(context, 'كل الحالات', 'All statuses')),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'active',
                    child: Text(_text(context, 'خطة نشطة', 'Active plan')),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'withoutPlan',
                    child: Text(
                      _text(context, 'بدون خطة نشطة', 'No active plan'),
                    ),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    careStatus: value,
                    clearCareStatus: value == null,
                  ),
                ),
              ),
              _filter<PharmacyRequestStatus?>(
                key: const ValueKey('reports-request-filter'),
                icon: LucideIcons.clipboardList,
                label: _text(context, 'حالة طلب الصرف', 'Dispensing request'),
                value: _filters.requestStatus,
                entries: [
                  DropdownMenuItem<PharmacyRequestStatus?>(
                    value: null,
                    child: Text(_text(context, 'كل الطلبات', 'All requests')),
                  ),
                  ...PharmacyRequestStatus.values.map(
                    (status) => DropdownMenuItem<PharmacyRequestStatus?>(
                      value: status,
                      child: Text(_requestStatus(context, status)),
                    ),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    requestStatus: value,
                    clearRequestStatus: value == null,
                  ),
                ),
              ),
              _filter<RequestStatus?>(
                key: const ValueKey('reports-workflow-filter'),
                icon: LucideIcons.gitBranch,
                label: _text(context, 'حالة طلب العلاج', 'Treatment workflow'),
                value: _filters.treatmentRequestStatus,
                entries: [
                  DropdownMenuItem<RequestStatus?>(
                    value: null,
                    child: Text(_text(context, 'كل الحالات', 'All statuses')),
                  ),
                  ...RequestStatus.values.map(
                    (status) => DropdownMenuItem<RequestStatus?>(
                      value: status,
                      child: Text(_treatmentStatus(context, status)),
                    ),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    treatmentRequestStatus: value,
                    clearTreatmentRequestStatus: value == null,
                  ),
                ),
              ),
              _filter<String?>(
                key: const ValueKey('reports-doctor-filter'),
                icon: LucideIcons.stethoscope,
                label: _text(context, 'الطبيب', 'Doctor'),
                value: _filters.doctorId,
                entries: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_text(context, 'كل الأطباء', 'All doctors')),
                  ),
                  ...source.doctors.map(
                    (doctor) => DropdownMenuItem<String?>(
                      value: doctor.id,
                      child: Text(
                        doctor.getLocalizedName(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => _update(
                  _filters.copyWith(
                    doctorId: value,
                    clearDoctor: value == null,
                  ),
                ),
              ),
            ],
          ),
          if (_filters.hasFilters) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                if (_filters.emirate != null)
                  _activeFilter(
                    context,
                    _localizedEmirate(context, _filters.emirate!),
                    () => _update(
                      _filters.copyWith(clearEmirate: true, clearCenter: true),
                    ),
                  ),
                if (_filters.centerId != null)
                  _activeFilter(
                    context,
                    source
                            .getDispensingCenterById(_filters.centerId)
                            ?.getLocalizedName(context) ??
                        _filters.centerId!,
                    () => _update(_filters.copyWith(clearCenter: true)),
                  ),
                if (_filters.residency != null)
                  _activeFilter(
                    context,
                    _residencyName(context, _filters.residency!),
                    () => _update(_filters.copyWith(clearResidency: true)),
                  ),
                if (_filters.careStatus != null)
                  _activeFilter(
                    context,
                    _filters.careStatus == 'active'
                        ? _text(context, 'خطة نشطة', 'Active plan')
                        : _text(context, 'بدون خطة نشطة', 'No active plan'),
                    () => _update(_filters.copyWith(clearCareStatus: true)),
                  ),
                if (_filters.requestStatus != null)
                  _activeFilter(
                    context,
                    _requestStatus(context, _filters.requestStatus!),
                    () => _update(_filters.copyWith(clearRequestStatus: true)),
                  ),
                if (_filters.treatmentRequestStatus != null)
                  _activeFilter(
                    context,
                    _treatmentStatus(context, _filters.treatmentRequestStatus!),
                    () => _update(
                      _filters.copyWith(clearTreatmentRequestStatus: true),
                    ),
                  ),
                if (_filters.doctorId != null)
                  _activeFilter(
                    context,
                    source.doctors
                            .where((doctor) => doctor.id == _filters.doctorId)
                            .firstOrNull
                            ?.getLocalizedName(context) ??
                        '',
                    () => _update(_filters.copyWith(clearDoctor: true)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _filter<T>({
    required Key key,
    required IconData icon,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> entries,
    required ValueChanged<T?> onChanged,
  }) => Container(
    key: key,
    width: 176,
    height: 43,
    padding: const EdgeInsetsDirectional.only(start: 10, end: 6),
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: DropdownButtonFormField<T>(
            key: ValueKey('dropdown-${key.toString()}-$value'),
            initialValue: value,
            isExpanded: true,
            icon: const Icon(LucideIcons.chevronDown, size: 14),
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
            ),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
            dropdownColor: AppColors.surface,
            items: entries,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );

  Widget _activeFilter(
    BuildContext context,
    String label,
    VoidCallback clear,
  ) => InputChip(
    label: Text(label, style: const TextStyle(fontSize: 10)),
    onDeleted: clear,
    deleteIconColor: AppColors.textSecondary,
    visualDensity: VisualDensity.compact,
    backgroundColor: AppColors.primary.withValues(alpha: .07),
    side: BorderSide(color: AppColors.primary.withValues(alpha: .14)),
  );

  Widget _buildKpis(BuildContext context, ReportAnalyticsData report) {
    final items = <_KpiItem>[
      _KpiItem(
        _text(context, 'مرضى السجل', 'Patients in registry'),
        '${report.patients.length}',
        _text(
          context,
          'لقطة حالية · بعد تطبيق النطاق',
          'Current roster · filtered cohort',
        ),
        LucideIcons.users,
        AppColors.info,
        'Current patients in the shared registry after cohort filters. The roster has no registration timestamps, so this is a current snapshot, not a period count.',
      ),
      _KpiItem(
        _text(context, 'مستوفون للأهلية', 'Eligible patients'),
        '${report.eligiblePatients}',
        report.patients.isEmpty
            ? _text(context, 'لا يوجد مقام', 'No denominator')
            : '${(report.eligiblePatients / report.patients.length * 100).toStringAsFixed(1)}% ${_text(context, 'من المرضى', 'of roster')}',
        LucideIcons.shieldCheck,
        AppColors.success,
        'Patients passing configured clinical eligibility rules divided by the filtered current roster. This is a clinical rule result, not a coverage decision.',
      ),
      _KpiItem(
        _text(context, 'خطط علاج نشطة', 'Active treatment plans'),
        '${report.activePlans}',
        _text(context, 'حسب الخطط المرتبطة بالمريض', 'Linked active plans'),
        LucideIcons.clipboardCheck,
        AppColors.primary,
        'Filtered patients with an active TreatmentPlan in DataProvider. This is a current snapshot and is not restricted to the selected activity period.',
      ),
      _KpiItem(
        _text(context, 'عمليات تسليم الدواء', 'Dispensing handovers'),
        '${report.handovers.length}',
        _text(context, 'داخل الفترة المحددة', 'In selected period'),
        LucideIcons.syringe,
        const Color(0xff15966a),
        'Count of dated PatientDispenseRecord handovers inside the selected range. The model does not hold package quantity per historical handover, so this is not a unit count.',
      ),
      _KpiItem(
        _text(context, 'بانتظار المراجعة الطبية', 'Awaiting medical review'),
        '${report.pendingMedicalReview}',
        _text(
          context,
          'طلبات نشطة قيد المراجعة · لقطة حالية',
          'Current requests under review',
        ),
        LucideIcons.fileClock,
        AppColors.warning,
        'Distinct patients with their latest canonical treatment request in submitted, assessing, needs-information or under-review state. Current workflow snapshot; date window does not apply.',
      ),
      _KpiItem(
        _text(context, 'منشآت بمخزون منخفض', 'Low-stock facilities'),
        '${report.lowStockFacilities}',
        _text(context, 'أقل من 10 وحدات متاحة', 'Below 10 available units'),
        LucideIcons.packageSearch,
        report.lowStockFacilities > 0 ? AppColors.error : AppColors.success,
        'Selected facilities where current available stock across supported doses is below the operational threshold of 10 units. This is a current inventory snapshot.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1420
            ? 6
            : constraints.maxWidth >= 1080
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _kpiCard(context, items[index]),
        );
      },
    );
  }

  Widget _kpiCard(BuildContext context, _KpiItem item) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: _surfaceDecoration(),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, size: 19, color: item.color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: item.definition,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      LucideIcons.info,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.context,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildJourney(BuildContext context, ReportAnalyticsData report) {
    final counts = report.journeyCounts;
    final labels = context.isArabic
        ? const [
            'السجل',
            'تقييم موثق',
            'الأهلية',
            'خطة نشطة',
            'مراجعة طبية',
            'موافقة فأكثر',
            'جاهز للصرف',
            'تم التسليم',
            'متابعة مكتملة',
          ]
        : const [
            'Registered',
            'Assessed',
            'Eligible',
            'Plan active',
            'Medical review',
            'Approved or later',
            'Pharmacy ready',
            'Dispensed',
            'Follow-up',
          ];
    final captions = context.isArabic
        ? const [
            'كل المسجلين',
            'تشخيص + مختبر',
            'من المُقيّمين',
            'من المؤهلين',
            'حالة الطلب الحالية',
            'حالة الطلب الحالية',
            'طلب جاهز',
            'تسليم داخل الفترة',
            'موعد مكتمل داخل الفترة',
          ]
        : const [
            'Current roster',
            'Diagnosis + labs',
            'Of assessed',
            'Of eligible',
            'Current request state',
            'Current request state',
            'Ready request',
            'Period handover',
            'Completed visit in period',
          ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: .34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.route,
                color: AppColors.accentLight,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _text(
                    context,
                    'تغطية رحلة المريض',
                    'Patient journey coverage',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Tooltip(
                message: _text(
                  context,
                  'لقطة للحالات الحالية. بيانات التسجيل غير مؤرخة، والصرف يعرض المرضى الذين لديهم سجل تسليم سابق؛ لذلك الأعداد توضح التغطية المرحلية ولا تمثل تحويلًا سببيًا.',
                  'Current-state coverage. Registration has no timestamps; dispensing means a prior handover exists. Stage totals show record coverage, not causal conversion.',
                ),
                child: Icon(LucideIcons.info, size: 15, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 17),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              return compact
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        labels.length,
                        (index) => SizedBox(
                          width: (constraints.maxWidth - 24) / 4,
                          child: _journeyStage(
                            context,
                            labels[index],
                            captions[index],
                            counts[index],
                            index,
                            compact: true,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(labels.length, (index) {
                        return Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _journeyStage(
                                  context,
                                  labels[index],
                                  captions[index],
                                  counts[index],
                                  index,
                                ),
                              ),
                              if (index < labels.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Icon(
                                    LucideIcons.chevronLeft,
                                    size: 16,
                                    color: Colors.white30,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _journeyStage(
    BuildContext context,
    String label,
    String caption,
    int value,
    int index, {
    bool compact = false,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 6, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: Colors.white.withValues(alpha: .09)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: index == 0
                    ? AppColors.accent.withValues(alpha: .25)
                    : AppColors.primaryLight.withValues(alpha: .40),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .59),
            fontSize: 9,
          ),
        ),
      ],
    ),
  );

  Widget _buildClinicalAndDispensing(
    BuildContext context,
    ReportAnalyticsData report,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 900;
      final clinical = _clinicalPanel(context, report);
      final pharmacy = _dispensingPanel(context, report);
      if (stacked) {
        return Column(
          children: [clinical, const SizedBox(height: 14), pharmacy],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 47, child: clinical),
          const SizedBox(width: 14),
          Expanded(flex: 53, child: pharmacy),
        ],
      );
    },
  );

  Widget _clinicalPanel(BuildContext context, ReportAnalyticsData report) {
    final ar = context.isArabic;
    final bmi = report.averageBmi;
    final completed = report.appointments
        .where((item) => item.status == AppointmentStatus.completed)
        .length;
    final missedAppointments = report.appointments
        .where((item) => item.status == AppointmentStatus.missed)
        .length;
    final cards = [
      _snapshotMeasure(
        context,
        _text(context, 'متوسط مؤشر كتلة الجسم', 'Average BMI'),
        bmi?.toStringAsFixed(1) ?? '—',
        _text(
          context,
          'حالة حالية · المرضى المشمولون',
          'Current snapshot · filtered patients',
        ),
        LucideIcons.activity,
        AppColors.warning,
      ),
      _snapshotMeasure(
        context,
        _text(context, 'نتائج مختبر ضمن الفترة', 'Lab results in period'),
        '${report.labResults.length}',
        '${report.abnormalLabResults} ${_text(context, 'خارج المرجع', 'outside reference')}',
        LucideIcons.flaskConical,
        report.abnormalLabResults > 0 ? AppColors.error : AppColors.success,
      ),
      _snapshotMeasure(
        context,
        _text(context, 'الالتزام المسجل', 'Recorded adherence'),
        report.adherenceRate == null
            ? _text(context, 'غير متاح', 'Not available')
            : '${(report.adherenceRate! * 100).toStringAsFixed(1)}%',
        report.doseEvents.isEmpty
            ? _text(
                context,
                'لا توجد أحداث جرعات بالفترة',
                'No dose check-ins in period',
              )
            : '${report.doseEvents.length} ${_text(context, 'حدث جرعة', 'dose events')}',
        LucideIcons.target,
        report.adherenceRate == null
            ? AppColors.textSecondary
            : AppColors.success,
      ),
      _snapshotMeasure(
        context,
        _text(context, 'مواعيد متابعة', 'Follow-up appointments'),
        '${report.appointments.length}',
        '$completed ${_text(context, 'مكتمل', 'completed')} · $missedAppointments ${_text(context, 'فائت', 'missed')}',
        LucideIcons.calendarCheck,
        missedAppointments > 0 ? AppColors.warning : AppColors.primary,
      ),
    ];
    return _panel(
      context,
      title: _text(
        context,
        'المؤشرات السريرية والمتابعة',
        'Clinical outcomes & follow-up',
      ),
      subtitle: _text(
        context,
        'قراءة من آخر قيم وسجلات الفترة؛ لا يوجد استنتاج سببي للعلاج.',
        'Current measurements and dated events; no treatment-causality claim.',
      ),
      icon: LucideIcons.heartPulse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: cards
                .map((item) => SizedBox(width: 205, child: item))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (report.clinicalMonthlyObservations.length >= 2) ...[
            _subheading(
              context,
              _text(
                context,
                'اتجاهات الوزن الموثقة',
                'Documented weight trends',
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                SizedBox(
                  width: 205,
                  child: _clinicalTrend(context, report, bmi: false),
                ),
                SizedBox(
                  width: 205,
                  child: _clinicalTrend(context, report, bmi: true),
                ),
              ],
            ),
          ],
          const SizedBox(height: 13),
          _subheading(
            context,
            _text(
              context,
              'أحدث نتائج المختبر في النطاق',
              'Latest lab results in range',
            ),
          ),
          const SizedBox(height: 7),
          if (report.labResults.isEmpty)
            _emptyHint(
              context,
              _text(
                context,
                'لا توجد نتائج مؤرخة ضمن النطاق الحالي.',
                'No dated laboratory results in the selected range.',
              ),
            )
          else
            ...report.labResults.take(5).map((result) {
              final normal = report.isWithinReference(result);
              return _labRow(
                context,
                ar ? result.nameAr : result.nameEn,
                '${result.value.toStringAsFixed(result.value % 1 == 0 ? 0 : 1)} ${result.unit}',
                '${_text(context, 'النطاق', 'Ref.')} ${result.referenceRange} · ${result.date}',
                normal,
              );
            }),
          const SizedBox(height: 9),
          if (report.clinicalMonthlyObservations.length < 2)
            Text(
              _text(
                context,
                'اتجاه الوزن غير متاح: نحتاج قراءتين مؤرختين على الأقل. سجل الوزن العام بلا تواريخ، لذلك لا نرسمه كاتجاه.',
                'Weight trend unavailable: at least two dated readings are needed. Undated weight-history values are not plotted.',
              ),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _clinicalTrend(
    BuildContext context,
    ReportAnalyticsData report, {
    required bool bmi,
  }) {
    final observations = report.clinicalMonthlyObservations;
    final color = bmi ? AppColors.info : AppColors.primary;
    final values = observations
        .map((item) => bmi ? item.averageBmi : item.averageWeight)
        .toList();
    final spots = values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final padding = math.max((maximum - minimum) * .18, .6);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _text(
              context,
              bmi ? 'متوسط BMI' : 'متوسط الوزن (كجم)',
              bmi ? 'Average BMI' : 'Average weight (kg)',
            ),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 66,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minimum - padding,
                maxY: maximum + padding,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} · ${_monthLabel(context, observations[spot.x.toInt()].month)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: .1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            _text(
              context,
              '${observations.length} أشهر · ${report.weightObservations.length} جلسة علاج طبيعي',
              '${observations.length} months · ${report.weightObservations.length} rehab session readings',
            ),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _snapshotMeasure(
    BuildContext context,
    String title,
    String value,
    String note,
    IconData icon,
    Color color,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dispensingPanel(BuildContext context, ReportAnalyticsData report) {
    final maxValue = report.monthlyHandovers.fold<int>(
      0,
      (max, item) => math.max(max, item.handovers),
    );
    return _panel(
      context,
      title: _text(
        context,
        'نشاط الصرف والصيدلية',
        'Dispensing & pharmacy operations',
      ),
      subtitle: _text(
        context,
        'تسليمات فعلية مسجلة حسب تاريخها؛ المخزون لقطة حالية.',
        'Dated handover records; inventory is a current snapshot.',
      ),
      icon: LucideIcons.pill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _smallStat(
                context,
                _text(context, 'جاهز للصرف', 'Ready'),
                '${report.readyForDispensing}',
                AppColors.success,
              ),
              const SizedBox(width: 9),
              _smallStat(
                context,
                _text(context, 'متعذر / متوقف', 'Blocked'),
                '${report.blockedRequests}',
                report.blockedRequests > 0
                    ? AppColors.error
                    : AppColors.success,
              ),
              const SizedBox(width: 9),
              _smallStat(
                context,
                _text(context, 'وحدات متاحة الآن', 'Units available now'),
                '${report.totalAvailableUnits}',
                AppColors.info,
              ),
              const SizedBox(width: 9),
              _smallStat(
                context,
                _text(context, 'تنتهي خلال 90 يومًا', 'Expiring in 90 days'),
                '${report.unitsExpiringWithin90Days}',
                AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _subheading(
            context,
            _text(context, 'عمليات التسليم شهريًا', 'Monthly handovers'),
          ),
          const SizedBox(height: 6),
          if (report.monthlyHandovers.isEmpty || report.handovers.isEmpty)
            SizedBox(
              height: 142,
              child: _emptyHint(
                context,
                _text(
                  context,
                  'لا توجد تسليمات مؤرخة ضمن الفترة المختارة.',
                  'No dated handovers in the selected period.',
                ),
              ),
            )
          else
            SizedBox(
              height: 142,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue == 0
                      ? 1
                      : maxValue + math.max(1, maxValue * .18),
                  minX: 0,
                  maxX: math
                      .max(0, report.monthlyHandovers.length - 1)
                      .toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue < 4
                        ? 1
                        : (maxValue / 3).ceilToDouble(),
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 23,
                        interval: report.monthlyHandovers.length > 8 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= report.monthlyHandovers.length) {
                            return const SizedBox.shrink();
                          }
                          final month = report.monthlyHandovers[index].month;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _monthLabel(context, month),
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final entry = report.monthlyHandovers[spot.x.toInt()];
                        return LineTooltipItem(
                          '${_monthLabel(context, entry.month)}\n${entry.handovers} ${_text(context, 'عملية تسليم', 'handovers')}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < report.monthlyHandovers.length; i++)
                          FlSpot(
                            i.toDouble(),
                            report.monthlyHandovers[i].handovers.toDouble(),
                          ),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2.7,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: AppColors.primary,
                              strokeColor: AppColors.surface,
                              strokeWidth: 1.5,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: .08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 7),
          _subheading(
            context,
            _text(
              context,
              'طلبات الصرف داخل الفترة',
              'Dispensing requests in period',
            ),
          ),
          const SizedBox(height: 4),
          if (report.requestsInPeriod.isEmpty)
            _emptyHint(
              context,
              _text(
                context,
                'لا توجد طلبات مؤرخة داخل هذا النطاق.',
                'No dated requests in this window.',
              ),
            )
          else
            ...report.requestsInPeriod.take(4).map((request) {
              final patient = report.source.getPatientById(request.patientId);
              final center = report.source.getDispensingCenterById(
                request.assignedCenterId,
              );
              return _dataRow(
                context,
                patient?.id ?? request.patientId,
                '${request.medication} · ${request.dose} · ${center?.getLocalizedName(context) ?? request.assignedCenterId}',
                _requestStatus(context, request.status),
                _requestColor(request.status),
              );
            }),
        ],
      ),
    );
  }

  Widget _smallStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .065),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    ),
  );

  Widget _buildRegionalAndOperations(
    BuildContext context,
    ReportAnalyticsData report,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 900;
      final regions = _regionalPanel(context, report);
      final facilities = _facilityPanel(context, report);
      if (stacked) {
        return Column(
          children: [regions, const SizedBox(height: 14), facilities],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 45, child: regions),
          const SizedBox(width: 14),
          Expanded(flex: 55, child: facilities),
        ],
      );
    },
  );

  Widget _regionalPanel(BuildContext context, ReportAnalyticsData report) {
    final summaries = report.emirateSummaries;
    final maxPatients = summaries.fold<int>(
      0,
      (max, item) => math.max(max, item.patients),
    );
    return _panel(
      context,
      title: _text(context, 'التوزيع حسب الإمارة', 'Regional distribution'),
      subtitle: _text(
        context,
        'مجمّع حسب الحدود الإدارية الصحيحة؛ العين ضمن أبوظبي.',
        'Administrative emirates; Al Ain rolls up under Abu Dhabi.',
      ),
      icon: LucideIcons.map,
      child: summaries.isEmpty
          ? _emptyHint(
              context,
              _text(
                context,
                'لا توجد سجلات ضمن الفلاتر.',
                'No records match these filters.',
              ),
            )
          : Column(
              children: summaries.map((item) {
                final selected = _filters.emirate == item.emirate;
                return InkWell(
                  onTap: () => _update(
                    _filters.copyWith(
                      emirate: selected ? null : item.emirate,
                      clearEmirate: selected,
                      clearCenter: true,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 102,
                          child: Text(
                            _localizedEmirate(context, item.emirate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: maxPatients == 0
                                  ? 0
                                  : item.patients / maxPatients,
                              minHeight: 8,
                              backgroundColor: AppColors.border.withValues(
                                alpha: .65,
                              ),
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${item.patients}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        _tinyColumn(
                          context,
                          _text(context, 'أهلية', 'Eligible'),
                          '${item.eligiblePatients}',
                        ),
                        const SizedBox(width: 14),
                        _tinyColumn(
                          context,
                          _text(context, 'صرف', 'Handovers'),
                          '${item.handovers}',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _tinyColumn(BuildContext context, String label, String value) =>
      SizedBox(
        width: 48,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _facilityPanel(BuildContext context, ReportAnalyticsData report) {
    final items = report.facilitySummaries;
    return _panel(
      context,
      title: _text(context, 'المنشآت والمخزون', 'Facilities & inventory'),
      subtitle: _text(
        context,
        'المرضى المرتبطون وسجل الصرف مع الرصيد الحالي لكل منشأة.',
        'Linked patients, dated handovers and current on-hand stock.',
      ),
      icon: LucideIcons.building,
      child: items.isEmpty
          ? _emptyHint(
              context,
              _text(
                context,
                'لا توجد منشآت في النطاق المحدد.',
                'No facilities in this scope.',
              ),
            )
          : Column(
              children: items.take(7).map((item) {
                final low = item.center.totalAvailable < 10;
                return InkWell(
                  onTap: () => _update(
                    _filters.copyWith(
                      centerId: _filters.centerId == item.center.id
                          ? null
                          : item.center.id,
                      clearCenter: _filters.centerId == item.center.id,
                    ),
                  ),
                  child: _facilityRow(context, item, low),
                );
              }).toList(),
            ),
    );
  }

  Widget _facilityRow(
    BuildContext context,
    ReportFacilitySummary item,
    bool low,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            LucideIcons.building2,
            color: AppColors.primary,
            size: 15,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.center.getLocalizedName(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _localizedEmirate(context, item.center.region),
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _tinyColumn(
          context,
          _text(context, 'مرضى', 'Patients'),
          '${item.patients}',
        ),
        const SizedBox(width: 12),
        _tinyColumn(
          context,
          _text(context, 'تسليم', 'Handovers'),
          '${item.handovers}',
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 74,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.center.totalAvailable}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: low ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              Text(
                _text(context, 'وحدة متاحة', 'units on hand'),
                style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(
          context,
          low
              ? _text(context, 'منخفض', 'Low')
              : _text(context, 'متاح', 'Available'),
          low ? AppColors.error : AppColors.success,
        ),
      ],
    ),
  );

  Widget _buildProvidersAndFinance(
    BuildContext context,
    ReportAnalyticsData report,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 900;
      final providerPanel = _doctorPanel(context, report);
      final supportPanel = _supportPanel(context, report);
      if (stacked) {
        return Column(
          children: [providerPanel, const SizedBox(height: 14), supportPanel],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 56, child: providerPanel),
          const SizedBox(width: 14),
          Expanded(flex: 44, child: supportPanel),
        ],
      );
    },
  );

  Widget _doctorPanel(BuildContext context, ReportAnalyticsData report) {
    final doctors = report.doctorSummaries;
    return _panel(
      context,
      title: _text(context, 'نشاط الأطباء', 'Provider activity'),
      subtitle: _text(
        context,
        'الخطة والطبيب المرتبطان من بيانات النظام؛ لا يوجد مؤشر التزام أداء.',
        'Doctor-to-plan links from shared records; no fabricated productivity score.',
      ),
      icon: LucideIcons.stethoscope,
      child: doctors.isEmpty
          ? _emptyHint(
              context,
              _text(
                context,
                'لا يوجد أطباء ضمن الإمارة المختارة.',
                'No doctors in the selected emirate.',
              ),
            )
          : Column(
              children: [
                _tableHeader(context, [
                  _text(context, 'الطبيب', 'Doctor'),
                  _text(context, 'مرضى بخطة', 'Patients'),
                  _text(context, 'خطط نشطة', 'Active plans'),
                  _text(context, 'موافقات', 'Approved'),
                  _text(context, 'تسليمات', 'Handovers'),
                ]),
                ...doctors.map(
                  (item) => _tableRow(context, [
                    item.doctor.getLocalizedName(context),
                    '${item.patients}',
                    '${item.activePlans}',
                    '${item.approvedPlans}',
                    '${item.handovers}',
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _supportPanel(BuildContext context, ReportAnalyticsData report) {
    final counts = report.residencyCounts;
    final total = report.patients.length;
    return _panel(
      context,
      title: _text(
        context,
        'الشرائح الديموغرافية والدعم',
        'Demographics & financial support',
      ),
      subtitle: _text(
        context,
        'تقديرات ديمو منفصلة عن السجلات المالية المسوّاة فعليًا.',
        'Demo estimates are kept separate from actually settled financial records.',
      ),
      icon: LucideIcons.walletCards,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final status in ResidencyStatus.values)
            _residencyRow(context, status, counts[status] ?? 0, total),
          const SizedBox(height: 10),
          _subheading(
            context,
            _text(
              context,
              'تقدير الخطة الحالية حسب الإقامة',
              'Current-plan estimate by residency',
            ),
          ),
          const SizedBox(height: 5),
          for (final summary in report.financialSummaries)
            _tableRow(context, [
              _residencyName(context, summary.residency),
              '${summary.activePlans} ${_text(context, 'خطة', 'plans')}',
              'AED ${summary.estimatedProgramValueAed.toStringAsFixed(0)}',
              'AED ${summary.estimatedCoverageAed.toStringAsFixed(0)}',
              'AED ${summary.estimatedPatientShareAed.toStringAsFixed(0)}',
            ]),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .075),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: .23),
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _text(
                      context,
                      'افتراض محلي للديمو فقط (${DemoFinancialSupportPolicy.policyLabel}): سعر الوحدة ${DemoFinancialSupportPolicy.medicationUnitPriceAed.toStringAsFixed(0)} درهم؛ مواطن ${(DemoFinancialSupportPolicy.citizenCoverageRate * 100).round()}%، مقيم ${(DemoFinancialSupportPolicy.residentCoverageRate * 100).round()}%، زائر ${(DemoFinancialSupportPolicy.visitorCoverageRate * 100).round()}%. لا تمثل هذه السياسة قواعد الوزارة.',
                      'Local demo assumption only (${DemoFinancialSupportPolicy.policyLabel}): AED ${DemoFinancialSupportPolicy.medicationUnitPriceAed.toStringAsFixed(0)} per unit; citizen ${(DemoFinancialSupportPolicy.citizenCoverageRate * 100).round()}%, resident ${(DemoFinancialSupportPolicy.residentCoverageRate * 100).round()}%, visitor ${(DemoFinancialSupportPolicy.visitorCoverageRate * 100).round()}%. This is not ministry policy.',
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(
              context,
              'السجلات المسوّاة داخل الفترة: ${report.settledClaimCount} · إجمالي AED ${report.settledProgramValueAed.toStringAsFixed(0)} · تغطية AED ${report.settledCoverageAed.toStringAsFixed(0)}. التقييمات غير المسوّاة مستبعدة من هذا الإجمالي.',
              'Settled shared records in period: ${report.settledClaimCount} · total AED ${report.settledProgramValueAed.toStringAsFixed(0)} · covered AED ${report.settledCoverageAed.toStringAsFixed(0)}. Non-settled assessments are excluded.',
            ),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _residencyRow(
    BuildContext context,
    ResidencyStatus status,
    int count,
    int total,
  ) {
    final percent = total == 0 ? 0.0 : count / total;
    final color = switch (status) {
      ResidencyStatus.citizen => AppColors.primary,
      ResidencyStatus.resident => AppColors.info,
      ResidencyStatus.visitor => AppColors.accent,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              _residencyName(context, status),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 39,
            child: Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsAndDataBoundaries(
    BuildContext context,
    ReportAnalyticsData report,
  ) {
    final observations = <_Observation>[];
    if (report.pendingMedicalReview > 0) {
      observations.add(
        _Observation(
          LucideIcons.fileClock,
          AppColors.warning,
          _text(
            context,
            '${report.pendingMedicalReview} مريضًا لديهم طلب علاجي حالي قيد المراجعة الطبية.',
            '${report.pendingMedicalReview} patient(s) currently have a treatment request under medical review.',
          ),
          _text(
            context,
            'المصدر: أحدث حالة من سجل دورة طلب العلاج المشتركة',
            'Source: latest state in the shared treatment-request workflow',
          ),
        ),
      );
    }
    if (report.lowStockFacilities > 0) {
      observations.add(
        _Observation(
          LucideIcons.packageSearch,
          AppColors.error,
          _text(
            context,
            '${report.lowStockFacilities} منشأة أقل من حد المخزون التجريبي (10 وحدات).',
            '${report.lowStockFacilities} facility/facilities are below the stock threshold (10 units).',
          ),
          _text(
            context,
            'المصدر: الرصيد الحالي للمخازن المختارة',
            'Source: current selected facility stock',
          ),
        ),
      );
    }
    if (report.abnormalLabResults > 0) {
      observations.add(
        _Observation(
          LucideIcons.flaskConical,
          AppColors.info,
          _text(
            context,
            '${report.abnormalLabResults} نتيجة مختبر خارج النطاق المرجعي المسجل.',
            '${report.abnormalLabResults} lab result(s) fall outside their recorded reference range.',
          ),
          _text(
            context,
            'مقارنة آلية بحدود المرجع الموجودة مع النتيجة',
            'Compared with the reference range stored with each result',
          ),
        ),
      );
    }
    if (report.doseEvents.isEmpty) {
      observations.add(
        _Observation(
          LucideIcons.pill,
          AppColors.textSecondary,
          _text(
            context,
            'لا توجد أحداث جرعات مسجلة؛ معدل الالتزام غير متاح لهذه الفترة.',
            'No dose check-ins are recorded; adherence is unavailable for this period.',
          ),
          _text(
            context,
            'لا نستخدم نسبة المريض القديمة بدل سجل الجرعات',
            'No patient-level placeholder percentage is substituted',
          ),
        ),
      );
    }
    if (observations.isEmpty) {
      observations.add(
        _Observation(
          LucideIcons.circleCheck,
          AppColors.success,
          _text(
            context,
            'لا توجد تنبيهات تشغيلية مشتقة من البيانات الحالية.',
            'No operational alerts are derived from the current records.',
          ),
          _text(
            context,
            'هذا لا يعني اعتماد جودة البيانات إنتاجيًا',
            'This does not imply production data-quality certification',
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final insights = _panel(
          context,
          title: _text(context, 'ملاحظات تنفيذية', 'Executive observations'),
          subtitle: _text(
            context,
            'قواعد محلية بسيطة من سجلات فعلية — ليست مخرجات نموذج ذكاء اصطناعي.',
            'Local rule checks over application records — not AI model output.',
          ),
          icon: LucideIcons.lightbulb,
          child: Column(
            children: observations
                .map((item) => _observationRow(context, item))
                .toList(),
          ),
        );
        final boundary = _panel(
          context,
          title: _text(
            context,
            'تغطية البيانات وحدود الديمو',
            'Data coverage & limitations',
          ),
          subtitle: _text(
            context,
            'مصادر البيانات المعروضة وحالات غيابها',
            'What is, and is not, represented in this view',
          ),
          icon: LucideIcons.shieldAlert,
          child: Column(
            children: [
              _boundaryRow(
                context,
                true,
                _text(
                  context,
                  'مرضى، خطط، أهلية، طلبات صرف، تسليمات، مخزون ومواعيد',
                  'Patients, plans, eligibility, dispensing requests, handovers, inventory and appointments',
                ),
              ),
              _boundaryRow(
                context,
                true,
                _text(
                  context,
                  'نتائج مختبر مرتبطة بالمريض مع وحدة ونطاق مرجعي',
                  'Patient-linked lab results with units and reference ranges',
                ),
              ),
              _boundaryRow(
                context,
                false,
                _text(
                  context,
                  'اتجاه الوزن يُعرض فقط من قراءات جلسات العلاج الطبيعي المؤرخة؛ سجل الوزن غير المؤرخ مستبعد',
                  'Weight trends use only dated rehabilitation-session readings; undated weight history is excluded',
                ),
              ),
              _boundaryRow(
                context,
                true,
                _text(
                  context,
                  'يوجد تقدير مالي افتراضي للديمو وسجلات دعم مشتركة؛ لا تمثل افتراضات التغطية سياسة معتمدة',
                  'Demo coverage estimates and shared financial records exist; assumptions are not an approved benefit policy',
                ),
              ),
              _boundaryRow(
                context,
                false,
                _text(
                  context,
                  'لا يوجد model AI إنتاجي؛ التنبيهات هنا قواعد توضيحية فقط',
                  'Clinical observations are rule-based decision support',
                ),
              ),
              _boundaryRow(
                context,
                false,
                _text(
                  context,
                  'سجل المرضى بلا تاريخ تسجيل؛ عدد المرضى لقطة حالية وليس نموًا زمنيًا',
                  'Registry lacks registration dates; patient count is a snapshot, not growth over time',
                ),
              ),
            ],
          ),
        );
        if (stacked) {
          return Column(
            children: [insights, const SizedBox(height: 14), boundary],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 52, child: insights),
            const SizedBox(width: 14),
            Expanded(flex: 48, child: boundary),
          ],
        );
      },
    );
  }

  Widget _observationRow(BuildContext context, _Observation observation) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: observation.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(observation.icon, color: observation.color, size: 15),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation.text,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    observation.source,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _boundaryRow(BuildContext context, bool available, String text) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              available ? LucideIcons.circleCheck : LucideIcons.circleMinus,
              color: available ? AppColors.success : AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _panel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
    decoration: _surfaceDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .075),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  BoxDecoration _surfaceDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: AppColors.isDarkMode ? .08 : .025,
        ),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _subheading(BuildContext context, String label) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _labRow(
    BuildContext context,
    String name,
    String value,
    String meta,
    bool normal,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: normal ? AppColors.textPrimary : AppColors.error,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _statusBadge(
          context,
          normal
              ? _text(context, 'ضمن المرجع', 'In range')
              : _text(context, 'خارج المرجع', 'Out of range'),
          normal ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 146,
          child: Text(
            meta,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 8.5),
          ),
        ),
      ],
    ),
  );

  Widget _dataRow(
    BuildContext context,
    String title,
    String detail,
    String status,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(context, status, color),
      ],
    ),
  );

  Widget _emptyHint(BuildContext context, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(LucideIcons.inbox, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
          ),
        ),
      ],
    ),
  );

  Widget _statusBadge(BuildContext context, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _tableHeader(BuildContext context, List<String> labels) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _tableRow(BuildContext context, List<String> values) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppColors.border.withValues(alpha: .7)),
      ),
    ),
    child: Row(
      children: values
          .asMap()
          .entries
          .map(
            (entry) => Expanded(
              child: Text(
                entry.value,
                textAlign: entry.key == 0
                    ? (context.isArabic ? TextAlign.right : TextAlign.left)
                    : TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9.5,
                  fontWeight: entry.key == 0
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );

  Future<void> exportCurrentReport({String format = 'csv'}) async {
    if (!mounted || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final source = context.read<DataProvider>();
      final report = ReportAnalyticsData.derive(
        source,
        _filters,
        now: _refreshedAt,
      );
      if (format == 'print') {
        final printed = report_export.printReport(
          report.toPrintableHtml(arabic: context.isArabic),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              printed
                  ? _text(
                      context,
                      'استخدم نافذة الطباعة ثم اختر “حفظ كـ PDF”.',
                      'A report-only print view opened. Choose “Save as PDF” in the print dialog.',
                    )
                  : _text(
                      context,
                      'تعذر فتح نسخة الطباعة؛ اسمح بالنوافذ المنبثقة ثم أعد المحاولة.',
                      'The print view did not open. Allow pop-ups and try again.',
                    ),
            ),
          ),
        );
        return;
      }
      final isJson = format == 'json';
      final content = isJson ? report.toJson() : report.toCsv();
      final extension = isJson ? 'json' : 'csv';
      final mimeType = isJson
          ? 'application/json;charset=utf-8'
          : 'text/csv;charset=utf-8';
      final filename =
          'program-performance-${_dateLabel(report.periodEnd)}.$extension';
      final downloaded = report_export.downloadReportFile(
        content,
        filename,
        mimeType,
      );
      if (!downloaded) {
        await Clipboard.setData(ClipboardData(text: content));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? _text(
                    context,
                    isJson
                        ? 'تم تنزيل ملف JSON للتقرير الحالي.'
                        : 'تم تنزيل ملف CSV للتقرير الحالي.',
                    isJson
                        ? 'JSON report downloaded.'
                        : 'CSV report downloaded.',
                  )
                : _text(
                    context,
                    isJson
                        ? 'تم نسخ بيانات التقرير بصيغة JSON.'
                        : 'تم نسخ بيانات التقرير بصيغة CSV.',
                    isJson
                        ? 'Report JSON copied to clipboard.'
                        : 'Report CSV copied to clipboard.',
                  ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              context,
              'تعذر إنشاء التقرير. حاول مرة أخرى.',
              'Could not create the report. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _refresh() => setState(() => _refreshedAt = DateTime.now());

  void _update(ReportFilters filters) => setState(() => _filters = filters);

  String _dateLabel(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _timeLabel(BuildContext context, DateTime value) =>
      '${_dateLabel(value)}  ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _periodName(BuildContext context, int days) {
    if (context.isArabic) {
      return switch (days) {
        30 => 'آخر 30 يومًا',
        90 => 'آخر 90 يومًا',
        180 => 'آخر 6 أشهر',
        _ => 'آخر 12 شهرًا',
      };
    }
    return switch (days) {
      30 => 'Last 30 days',
      90 => 'Last 90 days',
      180 => 'Last 6 months',
      _ => 'Last 12 months',
    };
  }

  String _localizedEmirate(BuildContext context, String name) {
    final patient = context
        .read<DataProvider>()
        .patients
        .where((p) => p.emirate == name)
        .firstOrNull;
    if (patient != null) return patient.getLocalizedEmirate(context);
    final center = context
        .read<DataProvider>()
        .centers
        .where((item) => item.region == name)
        .firstOrNull;
    return center?.getLocalizedRegion(context) ?? name;
  }

  String _residencyName(BuildContext context, ResidencyStatus status) =>
      switch ((context.isArabic, status)) {
        (true, ResidencyStatus.citizen) => 'مواطن',
        (true, ResidencyStatus.resident) => 'مقيم',
        (true, ResidencyStatus.visitor) => 'زائر',
        (false, ResidencyStatus.citizen) => 'Citizen',
        (false, ResidencyStatus.resident) => 'Resident',
        (false, ResidencyStatus.visitor) => 'Visitor',
      };

  String _requestStatus(BuildContext context, PharmacyRequestStatus status) =>
      switch ((context.isArabic, status)) {
        (true, PharmacyRequestStatus.ready) => 'جاهز للصرف',
        (true, PharmacyRequestStatus.pendingReview) => 'بانتظار المراجعة',
        (true, PharmacyRequestStatus.notEligible) => 'غير مؤهل',
        (true, PharmacyRequestStatus.outOfStock) => 'نفاد المخزون',
        (true, PharmacyRequestStatus.expired) => 'منتهي',
        (true, PharmacyRequestStatus.cancelled) => 'ملغي',
        (true, PharmacyRequestStatus.dispensed) => 'تم الصرف',
        (false, PharmacyRequestStatus.ready) => 'Ready',
        (false, PharmacyRequestStatus.pendingReview) => 'Pending review',
        (false, PharmacyRequestStatus.notEligible) => 'Not eligible',
        (false, PharmacyRequestStatus.outOfStock) => 'Out of stock',
        (false, PharmacyRequestStatus.expired) => 'Expired',
        (false, PharmacyRequestStatus.cancelled) => 'Cancelled',
        (false, PharmacyRequestStatus.dispensed) => 'Dispensed',
      };

  String _treatmentStatus(BuildContext context, RequestStatus status) =>
      switch ((context.isArabic, status)) {
        (true, RequestStatus.draft) => 'مسودة',
        (true, RequestStatus.submitted) => 'مقدم',
        (true, RequestStatus.assessing) => 'قيد التقييم',
        (true, RequestStatus.needsInformation) => 'بيانات مطلوبة',
        (true, RequestStatus.underReview) => 'مراجعة طبية',
        (true, RequestStatus.approved) => 'معتمد',
        (true, RequestStatus.rejected) => 'مرفوض',
        (true, RequestStatus.readyToDispense) => 'جاهز للصرف',
        (true, RequestStatus.dispensed) => 'تم الصرف',
        (true, RequestStatus.monitoring) => 'متابعة',
        (true, RequestStatus.renewalDue) => 'تجديد مطلوب',
        (true, RequestStatus.completed) => 'مكتمل',
        (true, RequestStatus.expired) => 'منتهي',
        (true, RequestStatus.cancelled) => 'ملغي',
        (false, RequestStatus.draft) => 'Draft',
        (false, RequestStatus.submitted) => 'Submitted',
        (false, RequestStatus.assessing) => 'Assessing',
        (false, RequestStatus.needsInformation) => 'Needs information',
        (false, RequestStatus.underReview) => 'Medical review',
        (false, RequestStatus.approved) => 'Approved',
        (false, RequestStatus.rejected) => 'Rejected',
        (false, RequestStatus.readyToDispense) => 'Ready to dispense',
        (false, RequestStatus.dispensed) => 'Dispensed',
        (false, RequestStatus.monitoring) => 'Monitoring',
        (false, RequestStatus.renewalDue) => 'Renewal due',
        (false, RequestStatus.completed) => 'Completed',
        (false, RequestStatus.expired) => 'Expired',
        (false, RequestStatus.cancelled) => 'Cancelled',
      };

  Color _requestColor(PharmacyRequestStatus status) => switch (status) {
    PharmacyRequestStatus.ready ||
    PharmacyRequestStatus.dispensed => AppColors.success,
    PharmacyRequestStatus.pendingReview => AppColors.warning,
    PharmacyRequestStatus.notEligible ||
    PharmacyRequestStatus.outOfStock ||
    PharmacyRequestStatus.expired => AppColors.error,
    PharmacyRequestStatus.cancelled => AppColors.textSecondary,
  };

  String _monthLabel(BuildContext context, DateTime value) {
    final en = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final ar = const [
      'ينا',
      'فبر',
      'مار',
      'أبر',
      'ماي',
      'يون',
      'يول',
      'أغس',
      'سبت',
      'أكت',
      'نوف',
      'ديس',
    ];
    return '${context.isArabic ? ar[value.month - 1] : en[value.month - 1]} ${value.year.toString().substring(2)}';
  }
}

class _KpiItem {
  final String label;
  final String value;
  final String context;
  final IconData icon;
  final Color color;
  final String definition;

  const _KpiItem(
    this.label,
    this.value,
    this.context,
    this.icon,
    this.color,
    this.definition,
  );
}

class _Observation {
  final IconData icon;
  final Color color;
  final String text;
  final String source;

  const _Observation(this.icon, this.color, this.text, this.source);
}
