import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/auth/access_control.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/platform_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../journey/journey_models.dart';
import 'payment_screen.dart';
import '../../features/treatment_plan/models/treatment_plan.dart';

class WebPharmacyDispensingView extends StatefulWidget {
  final DispensingCenter center;
  final String? initialPatientId;

  const WebPharmacyDispensingView({
    super.key,
    required this.center,
    this.initialPatientId,
  });

  @override
  State<WebPharmacyDispensingView> createState() =>
      _WebPharmacyDispensingViewState();
}

enum QueueFilter { all, ready, needsReview, blocked }

class _WebPharmacyDispensingViewState extends State<WebPharmacyDispensingView> {
  Patient? _activePatient;
  PharmacyDispensingRequest? _activeRequest;
  String _searchQuery = '';
  QueueFilter _selectedFilter = QueueFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectPatient(widget.initialPatientId!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectPatient(String patientId) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final p = provider.getPatientById(patientId);
    if (p != null) {
      setState(() {
        _activePatient = p;
        _activeRequest = provider.pharmacyRequestForPatient(p.id);
      });
    }
  }

  void _afterDispenseComplete() {
    setState(() {
      _activePatient = null;
      _activeRequest = null;
    });
  }

  // Determine request status
  QueueFilter _getRequestStatus(
    PharmacyDispensingRequest request,
    Patient patient,
    DataProvider dp,
  ) {
    final validation = dp.validateDispensing(
      patientId: patient.id,
      centerId: widget.center.id,
      hasPermission: true,
    );
    if (validation.canDispense) return QueueFilter.ready;

    final plan = dp.getPlanForPatient(patient.id);
    if (plan != null && plan.clinicalApprovalStatus == 'pending_review') {
      return QueueFilter.needsReview;
    }
    return QueueFilter.blocked;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the request queue beside the detail on ordinary desktop widths.
        final sideBySide = constraints.maxWidth >= 1500;
        final queue = Container(
          width: sideBySide ? 320 : null,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              left: BorderSide(
                color: context.isArabic ? AppColors.border : Colors.transparent,
              ),
              right: BorderSide(
                color: context.isArabic ? Colors.transparent : AppColors.border,
              ),
            ),
          ),
          child: _buildQueuePanel(context),
        );
        final detail = _activePatient == null
            ? _buildEmptyState()
            : _buildMainContent(context);
        return sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  queue,
                  Expanded(child: detail),
                ],
              )
            : (_activePatient == null ? queue : detail);
      },
    );
  }

  String _getAvatarForPatient(Patient p) {
    if (p.gender.toLowerCase() == 'female') {
      return 'assets/images/emirati_female_avatar.jpg';
    }
    if (p.age < 30) {
      return 'assets/images/emirati_young_male_avatar.jpg';
    }
    return 'assets/images/emirati_avatar.jpg';
  }

  Widget _buildEmptyState() {
    return ColoredBox(
      color: AppColors.background,
      child: PlatformStateView(
        kind: PlatformStateKind.empty,
        title: context.isArabic ? 'لم يتم تحديد طلب' : 'Select a request',
        message: context.isArabic
            ? 'اختر طلباً من قائمة الصرف لعرض التحقق والمخزون.'
            : 'Choose a request to review verification, stock, and dispensing details.',
      ),
    );
  }

  Widget _buildQueuePanel(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);

    // Base queue for this center
    final allRequests = provider.pharmacyRequests
        .where(
          (r) =>
              r.assignedCenterId == widget.center.id &&
              r.status != PharmacyRequestStatus.dispensed &&
              r.status != PharmacyRequestStatus.cancelled &&
              provider.treatmentRequestById(r.treatmentRequestId)?.status ==
                  RequestStatus.readyToDispense,
        )
        .toList();

    // Map to extended info
    final extendedList = allRequests
        .map((r) {
          final p = provider.getPatientById(r.patientId);
          final status = p != null
              ? _getRequestStatus(r, p, provider)
              : QueueFilter.blocked;
          return {'request': r, 'patient': p, 'status': status};
        })
        .where((item) => item['patient'] != null)
        .toList();

    // Search filter
    var filteredList = extendedList.where((item) {
      if (_searchQuery.isEmpty) return true;
      final p = item['patient'] as Patient;
      final r = item['request'] as PharmacyDispensingRequest;
      final q = _searchQuery.toLowerCase();
      return p.getLocalizedFullName(context).toLowerCase().contains(q) ||
          p.emiratesId.contains(q) ||
          r.id.toLowerCase().contains(q);
    }).toList();

    // Status filter
    if (_selectedFilter != QueueFilter.all) {
      filteredList = filteredList
          .where((item) => item['status'] == _selectedFilter)
          .toList();
    }

    filteredList.sort(
      (a, b) => (b['request'] as PharmacyDispensingRequest).requestedAt
          .compareTo((a['request'] as PharmacyDispensingRequest).requestedAt),
    );

    // Count for chips
    int readyCount = extendedList
        .where((e) => e['status'] == QueueFilter.ready)
        .length;
    int reviewCount = extendedList
        .where((e) => e['status'] == QueueFilter.needsReview)
        .length;
    int blockedCount = extendedList
        .where((e) => e['status'] == QueueFilter.blocked)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.isArabic
                    ? 'الطلبات الواردة للصرف'
                    : 'Incoming Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: context.isArabic
                      ? 'ابحث برقم الهوية أو الاسم أو الطلب'
                      : 'Search by ID, Name or Request',
                  prefixIcon: Icon(LucideIcons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final filters = <Widget>[
                    _buildFilterChip(
                      context.isArabic ? 'الكل' : 'All',
                      QueueFilter.all,
                      null,
                    ),
                    _buildFilterChip(
                      context.isArabic ? 'جاهز للصرف' : 'Ready',
                      QueueFilter.ready,
                      readyCount,
                    ),
                    _buildFilterChip(
                      context.isArabic ? 'يحتاج مراجعة' : 'Review',
                      QueueFilter.needsReview,
                      reviewCount,
                    ),
                    _buildFilterChip(
                      context.isArabic ? 'محظور' : 'Blocked',
                      QueueFilter.blocked,
                      blockedCount,
                    ),
                  ];
                  if (constraints.maxWidth < 600) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < filters.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            filters[i],
                          ],
                        ],
                      ),
                    );
                  }
                  return Wrap(spacing: 8, runSpacing: 8, children: filters);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredList.isEmpty
              ? PlatformStateView(
                  kind: allRequests.isEmpty
                      ? PlatformStateKind.empty
                      : PlatformStateKind.noResults,
                  title: context.isArabic
                      ? (allRequests.isEmpty
                            ? 'لا توجد طلبات صرف'
                            : 'لا توجد نتائج')
                      : (allRequests.isEmpty
                            ? 'No dispensing requests'
                            : 'No matching requests'),
                  message: context.isArabic
                      ? (allRequests.isEmpty
                            ? 'ستظهر الطلبات المعتمدة والموجهة إلى هذا المركز هنا.'
                            : 'غيّر البحث أو عامل التصفية.')
                      : (allRequests.isEmpty
                            ? 'Approved requests assigned to this center will appear here.'
                            : 'Try another search or status filter.'),
                  actionLabel: allRequests.isEmpty
                      ? null
                      : (context.isArabic
                            ? 'مسح عوامل التصفية'
                            : 'Clear filters'),
                  onAction: allRequests.isEmpty
                      ? null
                      : () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedFilter = QueueFilter.all;
                        }),
                )
              : ListView.separated(
                  itemCount: filteredList.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final p = item['patient'] as Patient;
                    final r = item['request'] as PharmacyDispensingRequest;
                    final status = item['status'] as QueueFilter;
                    final isSelected = _activePatient?.id == p.id;

                    return InkWell(
                      onTap: () => _selectPatient(p.id),
                      child: Container(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.surface,
                              backgroundImage: AssetImage(
                                _getAvatarForPatient(p),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.getLocalizedFullName(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.dose} • ${r.id}',
                                    textDirection: TextDirection.ltr,
                                    textAlign: context.isArabic
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.requestedAt.toIso8601String().substring(
                                      0,
                                      10,
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, QueueFilter filter, int? count) {
    final isSelected = _selectedFilter == filter;
    Color getFilterColor() {
      if (filter == QueueFilter.ready) return AppColors.successText;
      if (filter == QueueFilter.needsReview) return AppColors.warningText;
      if (filter == QueueFilter.blocked) return AppColors.errorText;
      return AppColors.textPrimary;
    }

    final selectedFill = switch (filter) {
      QueueFilter.ready => AppColors.success,
      QueueFilter.needsReview => AppColors.warning,
      QueueFilter.blocked => AppColors.error,
      QueueFilter.all => AppColors.primary,
    };

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : getFilterColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : getFilterColor(),
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      backgroundColor: AppColors.surface,
      selectedColor: selectedFill,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(QueueFilter status) {
    String text;
    BadgeStatus badgeStatus;
    switch (status) {
      case QueueFilter.ready:
        text = context.isArabic ? 'جاهز للصرف' : 'Ready';
        badgeStatus = BadgeStatus.success;
        break;
      case QueueFilter.needsReview:
        text = context.isArabic ? 'يحتاج مراجعة' : 'Review';
        badgeStatus = BadgeStatus.warning;
        break;
      case QueueFilter.blocked:
      default:
        text = context.isArabic ? 'غير مؤهل' : 'Blocked';
        badgeStatus = BadgeStatus.error;
        break;
    }

    return StatusBadge(label: text, status: badgeStatus);
  }

  // --- MAIN CONTENT ---

  Widget _buildMainContent(BuildContext context) {
    final dp = Provider.of<DataProvider>(context);
    final p = _activePatient!;
    final req = _activeRequest;
    final plan = dp.getPlanForPatient(p.id);
    final center = dp.centers.firstWhere(
      (item) => item.id == widget.center.id,
      orElse: () => widget.center,
    );

    final validation = dp.validateDispensing(
      patientId: p.id,
      centerId: widget.center.id,
      hasPermission: true,
    );
    final canDispense = validation.canDispense;

    // Check conditions explicitly for the checklist
    final hasActivePlan =
        plan != null && plan.prescriptionValidUntil.isAfter(DateTime.now());
    final doctorApproved =
        plan != null && plan.clinicalApprovalStatus == 'approved';
    final patientEligible = p.programEligibility.eligible;
    final refillOk = !dp.isPatientInDispensingCooldown(p);
    final hasApprovedRequest =
        req != null && req.status == PharmacyRequestStatus.ready;

    final doseToDispense = req?.dose ?? plan?.medicationDose ?? '';

    int qty = req?.quantity ?? plan?.medicationQuantity ?? 1;
    final available = validation.availableStock;
    final hasInventory = available >= qty;

    final checklist = [
      {
        'label': context.isArabic ? 'خطة علاج معتمدة' : 'Active treatment plan',
        'ok': hasActivePlan,
      },
      {
        'label': context.isArabic
            ? 'موافقة المراجع الطبي'
            : 'Medical reviewer approval',
        'ok': doctorApproved,
      },
      {
        'label': context.isArabic ? 'المريض مؤهل للبرنامج' : 'Patient eligible',
        'ok': patientEligible,
      },
      {
        'label': context.isArabic
            ? 'فترة إعادة الصرف مستوفاة'
            : 'Refill interval satisfied',
        'ok': refillOk,
      },
      {
        'label': context.isArabic
            ? 'الوصفة سارية المفعول'
            : 'Prescription valid',
        'ok': hasActivePlan,
      },
      {
        'label': context.isArabic
            ? 'طلب صرف معتمد في القائمة'
            : 'Approved request in queue',
        'ok': hasApprovedRequest,
      },
      {
        'label': context.isArabic ? 'المخزون متوفر' : 'Medication available',
        'ok': hasInventory,
      },
      {
        'label': context.isArabic
            ? 'اكتملت فحوصات السلامة والصلاحيات'
            : 'Safety and access checks complete',
        'ok': validation.issues.isEmpty,
      },
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final patient = _buildHeader(context, p, req);
                    final prescription = _buildPrescriptionBlock(plan, req);
                    final checks = _buildChecklistPanel(checklist, validation);
                    if (constraints.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: patient),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: prescription),
                          const SizedBox(width: 12),
                          Expanded(flex: 5, child: checks),
                        ],
                      );
                    }
                    if (constraints.maxWidth < 740) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          checks,
                          const SizedBox(height: 16),
                          patient,
                          const SizedBox(height: 16),
                          prescription,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        checks,
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: patient),
                            const SizedBox(width: 16),
                            Expanded(child: prescription),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = <Widget>[
                      _buildPreviousDispensingBlock(p),
                      _buildInventoryBlock(
                        center,
                        available,
                        doseToDispense,
                        qty,
                      ),
                      _buildFinancialBlock(p),
                    ];
                    if (constraints.maxWidth < 820) {
                      return Column(
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(height: 16),
                            cards[i],
                          ],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[2]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _buildActionBar(canDispense, validation),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Patient p,
    PharmacyDispensingRequest? req,
  ) {
    String residencyStr = '';
    if (p.residencyStatus == ResidencyStatus.citizen) {
      residencyStr = context.isArabic ? 'مواطن' : 'Citizen';
    } else if (p.residencyStatus == ResidencyStatus.resident) {
      residencyStr = context.isArabic ? 'مقيم' : 'Resident';
    } else {
      residencyStr = context.isArabic ? 'زائر' : 'Visitor';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceMuted,
                backgroundImage: AssetImage(_getAvatarForPatient(p)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.getLocalizedFullName(context),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.isArabic ? "رقم الهوية" : "Patient ID"}: ${p.emiratesId} • $residencyStr',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildHeaderInfo(
                context.isArabic ? 'تاريخ الطلب' : 'Request Date',
                req?.requestedAt.toIso8601String().substring(0, 10) ?? '-',
              ),
              _buildHeaderInfo(
                context.isArabic ? 'رقم الوصفة' : 'Prescription',
                req?.id ?? '-',
              ),
              _buildHeaderInfo(
                context.isArabic ? 'الطبيب المعالج' : 'Prescribing physician',
                context
                        .read<DataProvider>()
                        .getPlanForPatient(p.id)
                        ?.doctorName ??
                    '-',
                icon: LucideIcons.stethoscope,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value, {IconData? icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildChecklistPanel(
    List<Map<String, dynamic>> checklist,
    DispensingValidationResult validation,
  ) {
    bool allOk = checklist.every((item) => item['ok'] == true);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: allOk
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(
                  allOk ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                  color: allOk ? AppColors.successText : AppColors.errorText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allOk
                        ? (context.isArabic
                              ? 'جاهز للصرف'
                              : 'Ready for Dispensing')
                        : (context.isArabic
                              ? 'غير جاهز للصرف'
                              : 'Not Ready for Dispensing'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: allOk
                          ? AppColors.successText
                          : AppColors.errorText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.isArabic
                      ? 'حالة الأهلية والصرف'
                      : 'Eligibility Check',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 4
                        : constraints.maxWidth >= 760
                        ? 3
                        : constraints.maxWidth >= 400
                        ? 2
                        : 1;
                    const gap = 12.0;
                    final tileWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: 10,
                      children: [
                        for (final item in checklist)
                          SizedBox(
                            width: tileWidth,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: item['ok']
                                        ? AppColors.success
                                        : AppColors.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['ok']
                                        ? LucideIcons.check
                                        : LucideIcons.x,
                                    size: 12,
                                    color: item['ok']
                                        ? Colors.white
                                        : AppColors.errorText,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['label'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: item['ok']
                                          ? AppColors.textPrimary
                                          : AppColors.errorText,
                                      fontWeight: item['ok']
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (validation.issues.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    context.isArabic ? 'أسباب المنع' : 'Blocking reasons',
                    style: TextStyle(
                      color: AppColors.errorText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final issue in validation.issues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $issue',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
                if (validation.warnings.isNotEmpty) ...[
                  const Divider(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900 ? 2 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 6,
                        children: [
                          for (final warning in validation.warnings)
                            SizedBox(
                              width: width,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.triangleAlert,
                                    size: 16,
                                    color: AppColors.warningText,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      warning,
                                      style: TextStyle(
                                        color: AppColors.warningText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionBlock(
    TreatmentPlan? plan,
    PharmacyDispensingRequest? req,
  ) {
    final dose = req?.dose ?? plan?.medicationDose ?? '-';
    final qty = req?.quantity ?? plan?.medicationQuantity ?? 1;
    final validUntil = plan?.prescriptionValidUntil != null
        ? plan!.prescriptionValidUntil.toIso8601String().substring(0, 10)
        : '-';
    final freq = plan?.medicationFrequencyDays ?? 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.isArabic ? 'تفاصيل الوصفة' : 'Prescription details',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.syringe,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mounjaro (Tirzepatide)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dose,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _infoPair(
                LucideIcons.package,
                context.isArabic ? 'الكمية المطلوبة' : 'Quantity',
                '$qty ${context.isArabic ? "عبوة" : "box"}',
              ),
              _infoPair(
                LucideIcons.calendar,
                context.isArabic ? 'الاستخدام' : 'Frequency',
                context.isArabic ? 'مرة كل $freq أيام' : 'Every $freq days',
              ),
              _infoPair(
                LucideIcons.clock,
                context.isArabic ? 'تاريخ صلاحية الوصفة' : 'Valid Until',
                validUntil,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPair(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousDispensingBlock(Patient p) {
    return _buildCardBlock(
      context.isArabic ? 'آخر عملية صرف' : 'Previous Dispensing',
      [
        _row(
          context.isArabic ? 'تاريخ آخر صرف' : 'Last Dispense',
          p.lastDispensingDate ?? '-',
        ),
        _row(
          context.isArabic ? 'الجرعة السابقة' : 'Prev Dose',
          p.doseHistory.isNotEmpty ? p.doseHistory.last : '-',
        ),
        const Divider(),
        _row(
          context.isArabic ? 'تاريخ الصرف التالي' : 'Next Eligible',
          p.nextEligibleDate ?? '-',
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildInventoryBlock(
    DispensingCenter center,
    int available,
    String dose,
    int qty,
  ) {
    final matchingBatches =
        center.batches
            .where(
              (batch) =>
                  batch.dose == dose &&
                  batch.quantity > 0 &&
                  batch.expiryDate.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final nextBatch = matchingBatches.isEmpty ? null : matchingBatches.first;
    return _buildCardBlock(
      context.isArabic ? 'المخزون والدفعات' : 'Inventory & Batches',
      [
        _row(
          context.isArabic ? 'الكمية المتاحة' : 'Available',
          '$available ${context.isArabic ? "عبوة" : "box"}',
          color: available >= qty ? AppColors.successText : AppColors.errorText,
        ),
        _row(
          context.isArabic ? 'الكمية المطلوبة' : 'Required',
          '$qty ${context.isArabic ? "عبوة" : "box"}',
        ),
        _row(
          context.isArabic ? 'رقم الدفعة' : 'Batch No',
          nextBatch?.id ?? '—',
        ),
        _row(
          context.isArabic ? 'تاريخ الانتهاء' : 'Expiry Date',
          nextBatch?.expiryDate.toIso8601String().substring(0, 10) ?? '—',
        ),
        const Divider(),
        _row(
          context.isArabic ? 'الدفعة صالحة' : 'Status',
          nextBatch == null
              ? (context.isArabic ? 'لا توجد دفعة صالحة' : 'No valid batch')
              : (context.isArabic ? 'دفعة صالحة' : 'Valid batch'),
          color: nextBatch == null
              ? AppColors.errorText
              : AppColors.successText,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildFinancialBlock(Patient p) {
    final estimate = context.read<DataProvider>().coverageEstimateForPatient(
      p.id,
    );
    final type = switch (p.residencyStatus) {
      ResidencyStatus.citizen => context.isArabic ? 'مواطن' : 'Citizen',
      ResidencyStatus.resident => context.isArabic ? 'مقيم' : 'Resident',
      ResidencyStatus.visitor => context.isArabic ? 'زائر' : 'Visitor',
    };
    final pct =
        DemoFinancialSupportPolicy.coverageRateFor(p.residencyStatus) * 100;
    String aed(double? value) =>
        value == null ? '—' : 'AED ${value.toStringAsFixed(2)}';

    return _buildCardBlock(
      context.isArabic ? 'التغطية المالية' : 'Financial Coverage',
      [
        _row(context.isArabic ? 'نوع المريض' : 'Category', type),
        _row(context.isArabic ? 'نسبة التغطية' : 'Coverage %', '$pct%'),
        _row(
          context.isArabic ? 'التكلفة المقدرة' : 'Estimated cost',
          aed(estimate?.totalAed),
        ),
        _row(
          context.isArabic ? 'مساهمة الحكومة' : 'Gov Subsidy',
          aed(estimate?.coveredAed),
        ),
        const Divider(),
        _row(
          context.isArabic ? 'مساهمة المريض' : 'Patient Pays',
          aed(estimate?.copayAed),
          isBold: true,
          color: estimate?.copayAed == 0
              ? AppColors.successText
              : AppColors.primary,
        ),
        Text(
          context.isArabic
              ? 'تقدير توضيحي؛ ليس سياسة تغطية معتمدة'
              : 'Illustrative estimate; not an approved benefit policy',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCardBlock(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...children.map(
            (w) => Padding(padding: const EdgeInsets.only(bottom: 6), child: w),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 14 : 13,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(
    bool canDispense,
    DispensingValidationResult validation,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final back = OutlinedButton(
            onPressed: _afterDispenseComplete,
            child: Text(
              context.isArabic ? 'العودة إلى قائمة الطلبات' : 'Back to queue',
            ),
          );
          final confirm = ElevatedButton.icon(
            onPressed: canDispense
                ? _processDispensing
                : () {
                    CustomToast.showMessage(
                      context,
                      validation.issues.isEmpty
                          ? (context.isArabic
                                ? 'الطلب غير جاهز للصرف'
                                : 'Request is not ready to dispense')
                          : validation.issues.first,
                      isError: true,
                    );
                  },
            icon: const Icon(LucideIcons.check),
            label: Text(
              context.isArabic
                  ? 'مراجعة وتسليم الدواء'
                  : 'Review medication handover',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canDispense
                  ? AppColors.primary
                  : AppColors.disabled,
              foregroundColor: Colors.white,
            ),
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [confirm, const SizedBox(height: 8), back],
            );
          }
          return Row(children: [back, const Spacer(), confirm]);
        },
      ),
    );
  }

  void _processDispensing() {
    final dp = Provider.of<DataProvider>(context, listen: false);
    final p = _activePatient!;

    final patientToPay = dp.coverageEstimateForPatient(p.id)?.copayAed ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          patient: p,
          amountToPay: patientToPay,
          onPaymentSuccess: () async {
            final access = Provider.of<AccessControlProvider>(
              context,
              listen: false,
            );
            final req = dp.pharmacyRequestForPatient(p.id);
            final plan = dp.getPlanForPatient(p.id);
            if (plan == null || req == null) return false;

            final ok = dp.dispenseMedication(
              patientId: p.id,
              centerId: widget.center.id,
              dose: plan.medicationDose,
              authorized: access.can(AppPermission.dispenseMedication),
              requestId: req.id,
            );
            if (!ok && context.mounted) {
              CustomToast.showMessage(
                context,
                context.tr('insufficient_inventory'),
                isError: true,
              );
            }
            if (ok) {
              _afterDispenseComplete();
            }
            return ok;
          },
        ),
      ),
    );
  }
}
