import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/auth/access_control.dart';
import '../../auth/login_screen.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/widgets/platform_state_view.dart';
import '../../treatment_plan/web/patient_360_view.dart';
import '../../clinical/clinical_review_detail_panel.dart';
import '../../clinical/register_patient_dialog.dart';
import '../program_alerts.dart';
import '../../journey/journey_provider.dart';
import '../../journey/journey_models.dart';
import '../../patients/patient_registry_view.dart';

class WebDoctorShell extends StatefulWidget {
  final String? initialPatientId;
  final int initialTabIndex;

  /// When true, renders only clinical tools (no portal chrome) for Ministry admin embed.
  final bool embeddedInAdmin;

  const WebDoctorShell({
    super.key,
    this.initialPatientId,
    this.initialTabIndex = 0,
    this.embeddedInAdmin = false,
  });

  @override
  State<WebDoctorShell> createState() => _WebDoctorShellState();
}

class _WebDoctorShellState extends State<WebDoctorShell> {
  bool _isReviewer(BuildContext context) =>
      context.watch<AccessControlProvider>().role == AppRole.medicalReviewer;

  String _portalLabel(BuildContext context) => _isReviewer(context)
      ? (context.isArabic ? 'بوابة المراجع الطبي' : 'Medical Reviewer Portal')
      : context.tr('clinical_portal');

  String _reviewLabel(BuildContext context) => _isReviewer(context)
      ? (context.isArabic ? 'طلبات المراجعة' : 'Review queue')
      : context.tr('clinical_assessments');

  late int _selectedIndex;
  Patient? _selectedPatient;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, citizen, resident, critical, regular
  final bool _isLoadingDetails = false;
  int _selectedPendingReviewIndex = 0;
  Patient? _detailsPatient;
  int _detailsTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = context.read<DataProvider>();
      final patient = widget.initialPatientId == null
          ? (data.patients.isEmpty ? null : data.patients.first)
          : data.getPatientById(widget.initialPatientId!);
      if (patient != null) {
        context.read<JourneyProvider>().bindExistingPatient(patient);
      }
    });
  }

  Patient? _patientFromId(DataProvider dataProvider, String? id) {
    if (id == null) return null;
    return dataProvider.getPatientById(id);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    final filtered = _getFilteredPatients(dataProvider.patients);
    final demoPatient = _patientFromId(dataProvider, widget.initialPatientId);
    if (_selectedPatient == null) {
      _selectedPatient =
          demoPatient ?? (filtered.isNotEmpty ? filtered.first : null);
    } else if (_selectedPatient != null) {
      final idx = dataProvider.patients.indexWhere(
        (p) => p.id == _selectedPatient!.id,
      );
      _selectedPatient = idx >= 0
          ? dataProvider.patients[idx]
          : (filtered.isNotEmpty ? filtered.first : null);
    }

    final pendingAuthCount = pendingAuthorizationReviewCount(dataProvider);
    final pendingAuthBadge = pendingAuthCount > 0 ? '$pendingAuthCount' : null;

    final body = _selectedIndex == 0
        ? (_detailsPatient == null
              ? _buildPatientsView(context, dataProvider)
              : Patient360View(
                  patient: _detailsPatient!,
                  initialTabIndex: _detailsTab,
                  onBack: () => setState(() => _detailsPatient = null),
                ))
        : _buildAssessmentsView(context, dataProvider);

    if (widget.embeddedInAdmin) {
      return ColoredBox(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmbeddedAdminHeader(
              context,
              pendingAuthBadge: pendingAuthBadge,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= AppLayout.desktopBreakpoint;
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: showSidebar
              ? null
              : Drawer(
                  child: _buildSidebar(
                    context,
                    pendingAuthBadge: pendingAuthBadge,
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar)
                SizedBox(
                  width: AppLayout.desktopSidebar,
                  child: _buildSidebar(
                    context,
                    pendingAuthBadge: pendingAuthBadge,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopbar(
                      context,
                      localeProvider,
                      dataProvider,
                      showMenuButton: !showSidebar,
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmbeddedAdminHeader(
    BuildContext context, {
    String? pendingAuthBadge,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('admin_embed_clinical_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _previewBadge(
                context,
                context.isArabic ? 'عرض كبوابة الطبيب' : 'Viewing as Doctor',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('admin_embed_clinical_sub'),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _embeddedTab(
                context,
                LucideIcons.users,
                context.tr('patients_registry'),
                0,
              ),
              const SizedBox(width: 10),
              _embeddedTab(
                context,
                LucideIcons.clipboardList,
                _reviewLabel(context),
                1,
                badge: pendingAuthBadge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewBadge(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .1),
      border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.eye, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _embeddedTab(
    BuildContext context,
    IconData icon,
    String label,
    int index, {
    String? badge,
  }) {
    final selected = _selectedIndex == index;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar(
    BuildContext context,
    LocaleProvider localeProvider,
    DataProvider dataProvider, {
    required bool showMenuButton,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () {
                  Scaffold.of(ctx).openDrawer();
                },
              ),
            ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _portalLabel(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _isReviewer(context)
                    ? (context.isArabic
                          ? 'مراجعة واعتماد الطلبات'
                          : 'Clinical authorization')
                    : context.tr('doc_clinic'),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: localeProvider.toggleLanguage,
            icon: Icon(
              LucideIcons.globe,
              size: 14,
              color: AppColors.textPrimary,
            ),
            label: Text(
              localeProvider.locale.languageCode == 'en'
                  ? context.tr('arabic')
                  : context.tr('english'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LucideIcons.logOut,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: IconButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {String? pendingAuthBadge}) {
    return Container(
      width: 240,
      color: AppColors.navy,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isReviewer(context)
                            ? (context.isArabic
                                  ? 'الرعاية الصحية — المراجعة الطبية'
                                  : 'Health Care — Medical Review')
                            : context.tr('clinical_brand'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        _portalLabel(context),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navSection(
                    _isReviewer(context)
                        ? (context.isArabic
                              ? 'أدوات المراجعة الطبية'
                              : 'Review tools')
                        : context.tr('clinical_tools'),
                  ),
                  _buildSidebarItem(
                    context,
                    LucideIcons.users,
                    context.tr('patients_registry'),
                    0,
                  ),
                  _buildSidebarItem(
                    context,
                    LucideIcons.clipboardList,
                    _reviewLabel(context),
                    1,
                    badge: pendingAuthBadge,
                  ),
                ],
              ),
            ),
          ),
          // User
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      _isReviewer(context) ? 'MR' : 'DM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isReviewer(context)
                            ? (context.isArabic
                                  ? 'المراجع الطبي'
                                  : 'Medical reviewer')
                            : context.tr('doc_name'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isReviewer(context)
                            ? (context.isArabic
                                  ? 'مراجعة واعتماد الطلبات'
                                  : 'Clinical authorization')
                            : context.tr('doc_clinic'),
                        style: TextStyle(
                          color: AppColors.surface54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    int index, {
    String? badge,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Patient> _getFilteredPatients(List<Patient> allPatients) {
    return allPatients.where((p) {
      final matchesSearch =
          p
              .getLocalizedFullName(context)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          p.emiratesId.contains(_searchQuery) ||
          p.id.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'citizen') {
        return p.residencyStatus == ResidencyStatus.citizen;
      }
      if (_selectedFilter == 'resident') {
        return p.residencyStatus == ResidencyStatus.resident;
      }
      if (_selectedFilter == 'critical') return p.bmi >= 35.0;
      if (_selectedFilter == 'regular') return p.bmi < 35.0;
      return true;
    }).toList();
  }

  void _openPatientWorkspace(Patient patient, {int tabIndex = 0}) {
    setState(() => _selectedPatient = patient);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Patient360View(patient: patient, initialTabIndex: tabIndex),
          ),
        ),
      ),
    );
  }

  Future<void> _registerPatient(BuildContext context) async {
    final patient = await RegisterPatientDialog.show(context);
    if (patient == null || !context.mounted) return;
    setState(() => _selectedPatient = patient);
    CustomToast.show(
      context,
      title: context.tr('patient_registered_title'),
      message: context.tr('patient_registered_msg', {
        'name': patient.getLocalizedFullName(context),
      }),
      icon: LucideIcons.userPlus,
      color: AppColors.success,
    );
  }

  Widget _registryKpi(String label, String value, IconData icon, Color color) {
    return Container(
      width: 255,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bmiBadge(BuildContext context, double bmi) {
    final (color, label) = bmi < 18.5
        ? (Colors.blue, context.tr('underweight'))
        : bmi < 25
        ? (AppColors.success, context.tr('normal_weight'))
        : bmi < 30
        ? (AppColors.warning, context.tr('overweight'))
        : (AppColors.error, context.tr('obesity'));
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          bmi.toStringAsFixed(1),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPatientsView(BuildContext context, DataProvider provider) {
    final _ = _buildPatientsViewLegacyNew;
    return PatientRegistryView(
      onOpenPatient: (patient, tabIndex) => setState(() {
        _detailsPatient = patient;
        _detailsTab = tabIndex;
      }),
    );
  }

  Widget _buildPatientsViewLegacyNew(
    BuildContext context,
    DataProvider provider,
  ) {
    // Keep the former split-view builder available while this demo migrates;
    // the active experience is the registry table below.
    final _ = _buildLegacyPatientsView;
    final filtered = _getFilteredPatients(provider.patients);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.users, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('patient_registry'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.tr('patient_registry_sub'),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _registerPatient(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                ),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: Text(context.tr('register_patient')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _registryKpi(
                  context.tr('total_patients'),
                  '${provider.patients.length}',
                  LucideIcons.users,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _registryKpi(
                  context.tr('status_active'),
                  '${provider.patients.where((p) => p.programEligibility.eligible).length}',
                  LucideIcons.circleCheck,
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                _registryKpi(
                  context.tr('filter_flagged'),
                  '${provider.patients.where((p) => !p.programEligibility.eligible).length}',
                  LucideIcons.triangleAlert,
                  AppColors.error,
                ),
                const SizedBox(width: 12),
                _registryKpi(
                  context.tr('requires_review'),
                  '${provider.pendingClinicalReviews.length}',
                  LucideIcons.calendarClock,
                  AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: (MediaQuery.sizeOf(context).width - 48).clamp(
                  200.0,
                  420.0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: context.tr('search_patient'),
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              _buildFilterChip(context, 'all', context.tr('all')),
              _buildFilterChip(context, 'citizen', context.tr('citizens')),
              _buildFilterChip(context, 'resident', context.tr('residents')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(
                    context.tr('no_matching_patients'),
                    kind: PlatformStateKind.noResults,
                    onClear: () => setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedFilter = 'all';
                    }),
                  )
                : Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStatePropertyAll(
                                AppColors.background,
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(context.tr('col_patient')),
                                ),
                                DataColumn(label: Text(context.tr('col_id'))),
                                DataColumn(label: Text(context.tr('col_dose'))),
                                DataColumn(label: Text(context.tr('col_bmi'))),
                                DataColumn(
                                  label: Text(context.tr('col_residency')),
                                ),
                                DataColumn(
                                  label: Text(context.tr('col_status')),
                                ),
                                DataColumn(
                                  label: Text(context.tr('last_visit')),
                                ),
                                DataColumn(label: Text(context.tr('actions'))),
                              ],
                              rows: filtered.map((patient) {
                                final eligible =
                                    patient.programEligibility.eligible;
                                return DataRow(
                                  selected: _selectedPatient?.id == patient.id,
                                  onSelectChanged: (_) => setState(
                                    () => _selectedPatient = patient,
                                  ),
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            child: Text(
                                              patient
                                                  .getLocalizedFullName(context)
                                                  .substring(0, 1),
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            patient.getLocalizedFullName(
                                              context,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        patient.id,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        context.mounjaroDoseLabel(
                                          patient.currentDose,
                                        ),
                                      ),
                                    ),
                                    DataCell(_bmiBadge(context, patient.bmi)),
                                    DataCell(
                                      Text(
                                        patient.getLocalizedResidency(context),
                                      ),
                                    ),
                                    DataCell(
                                      Chip(
                                        label: Text(
                                          eligible
                                              ? context.tr(
                                                  'eligible_dispensation',
                                                )
                                              : context.tr(
                                                  'status_program_ineligible',
                                                ),
                                        ),
                                        backgroundColor:
                                            (eligible
                                                    ? AppColors.success
                                                    : AppColors.warning)
                                                .withValues(alpha: 0.12),
                                        labelStyle: TextStyle(
                                          color: eligible
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        patient.lastDispensingDate ?? '—',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: context.tr('view_details'),
                                            onPressed: () =>
                                                _openPatientWorkspace(patient),
                                            icon: const Icon(LucideIcons.eye),
                                          ),
                                          IconButton(
                                            tooltip: context.tr(
                                              'treatment_plan',
                                            ),
                                            onPressed: () =>
                                                _openPatientWorkspace(
                                                  patient,
                                                  tabIndex: 2,
                                                ),
                                            icon: const Icon(
                                              LucideIcons.clipboardList,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: context.tr(
                                              'treatment_journey',
                                            ),
                                            onPressed: () =>
                                                _openPatientWorkspace(
                                                  patient,
                                                  tabIndex: 3,
                                                ),
                                            icon: const Icon(
                                              LucideIcons.chartNoAxesCombined,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: context.tr('appointments'),
                                            onPressed: () =>
                                                _openPatientWorkspace(
                                                  patient,
                                                  tabIndex: 9,
                                                ),
                                            icon: const Icon(
                                              LucideIcons.calendarDays,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyPatientsView(BuildContext context, DataProvider provider) {
    final filtered = _getFilteredPatients(provider.patients);

    return Row(
      children: [
        // Left Column (List) - 35%
        SizedBox(
          width: 380,
          child: Column(
            children: [
              // Search & Filter Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: context.tr('search_patient'),
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(context, 'all', context.tr('all')),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'citizen',
                            context.tr('citizens'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'resident',
                            context.tr('residents'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Register Patient Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12,
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newP = await RegisterPatientDialog.show(context);
                    if (newP != null) {
                      if (!context.mounted) return;
                      setState(() => _selectedPatient = newP);
                      CustomToast.show(
                        context,
                        title: context.tr('patient_registered_title'),
                        message: context.tr('patient_registered_msg', {
                          'name': newP.getLocalizedFullName(context),
                        }),
                        icon: LucideIcons.userPlus,
                        color: AppColors.success,
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: Text(context.tr('register_patient')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
              const Divider(height: 1),

              // Patient List
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(
                        context.tr('no_matching_patients'),
                        kind: PlatformStateKind.noResults,
                        onClear: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedFilter = 'all';
                        }),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final patient = filtered[index];
                          bool isSelected =
                              _selectedPatient != null &&
                              _selectedPatient!.id == patient.id;
                          return Container(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.04)
                                : Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  patient
                                      .getLocalizedFullName(context)
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient.getLocalizedFullName(context),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                context.tr('eid_label', {
                                  'id': patient.emiratesId,
                                }),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: patient.bmi >= 35
                                      ? AppColors.error.withValues(alpha: 0.1)
                                      : AppColors.success.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  context.tr('bmi_label', {
                                    'value': patient.bmi.toStringAsFixed(1),
                                  }),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: patient.bmi >= 35
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() => _selectedPatient = patient);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                      backgroundColor: AppColors.background,
                                      body: SafeArea(
                                        child: Patient360View(patient: patient),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppColors.border),
        // Right Column (Details) - 65%
        Expanded(
          child: _selectedPatient == null
              ? _buildEmptyState(context.tr('select_patient_clinical_profile'))
              : (_isLoadingDetails
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerContainer(width: 250, height: 32),
                            SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(child: SkeletonCard()),
                                SizedBox(width: 24),
                                Expanded(child: SkeletonCard()),
                              ],
                            ),
                            SizedBox(height: 32),
                            SkeletonList(count: 2),
                          ],
                        ),
                      )
                    : Patient360View(patient: _selectedPatient!)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String filterCode,
    String label,
  ) {
    bool isSelected = _selectedFilter == filterCode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = filterCode;
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(
    String text, {
    PlatformStateKind kind = PlatformStateKind.empty,
    VoidCallback? onClear,
  }) => PlatformStateView(
    kind: kind,
    title: text,
    message: kind == PlatformStateKind.noResults
        ? (context.isArabic
              ? 'غيّر البحث أو عامل التصفية لعرض المرضى.'
              : 'Try another name, identifier, or filter.')
        : (context.isArabic
              ? 'ستظهر التفاصيل هنا عندما تصبح متاحة.'
              : 'Details will appear here when available.'),
    actionLabel: onClear == null
        ? null
        : (context.isArabic ? 'مسح البحث' : 'Clear search'),
    onAction: onClear,
  );

  Widget _buildAssessmentsView(BuildContext context, DataProvider provider) {
    final pending = provider.pendingClinicalReviews;
    if (pending.isNotEmpty && _selectedPendingReviewIndex >= pending.length) {
      _selectedPendingReviewIndex = 0;
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isReviewer(context)
                ? (context.isArabic
                      ? 'طلبات المراجعة الطبية'
                      : 'Medical review queue')
                : context.tr('clinical_assessments_dashboard'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('clinical_assessments_dashboard_sub'),
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: pending.isEmpty
                ? _buildEmptyState(context.tr('no_pending_reviews'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 360,
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        context.tr('pending_reviews_queue'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${pending.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: pending.length,
                                  itemBuilder: (context, index) {
                                    final item = pending[index];
                                    final p = item.patient;
                                    final selected =
                                        index == _selectedPendingReviewIndex;
                                    final reason =
                                        item.reviewType == 'care_plan'
                                        ? context.tr('review_type_care_plan')
                                        : context.tr(
                                            'review_type_early_dispense',
                                          );
                                    return Material(
                                      color: selected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.06,
                                            )
                                          : Colors.transparent,
                                      child: ListTile(
                                        selected: selected,
                                        onTap: () => setState(
                                          () => _selectedPendingReviewIndex =
                                              index,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.warning
                                              .withValues(alpha: 0.15),
                                          child: Text(
                                            p
                                                .getLocalizedFullName(context)
                                                .substring(0, 1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.warningText,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          p.getLocalizedFullName(context),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          reason,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Text(
                                          p.id,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ClinicalReviewDetailPanel(
                            patient:
                                pending[_selectedPendingReviewIndex].patient,
                            reviewType:
                                pending[_selectedPendingReviewIndex].reviewType,
                            onApprove:
                                context.read<AccessControlProvider>().can(
                                  AppPermission.approveTreatment,
                                )
                                ? () {
                                    final item =
                                        pending[_selectedPendingReviewIndex];
                                    final approved = provider
                                        .approveClinicalReview(
                                          item.patient.id,
                                          actorRole: context
                                              .read<AccessControlProvider>()
                                              .role,
                                        );
                                    CustomToast.show(
                                      context,
                                      title: approved
                                          ? context.tr(
                                              'clinical_review_approved_title',
                                            )
                                          : (context.isArabic
                                                ? 'تعذرت الموافقة'
                                                : 'Approval blocked'),
                                      message: approved
                                          ? context.tr(
                                              'clinical_review_approved_msg',
                                              {
                                                'name': item.patient
                                                    .getLocalizedFullName(
                                                      context,
                                                    ),
                                              },
                                            )
                                          : (context.isArabic
                                                ? 'تحقق من الأهلية والتحاليل وحالة الطلب.'
                                                : 'Check eligibility, recent labs, and request status.'),
                                      icon: approved
                                          ? LucideIcons.checkCircle
                                          : LucideIcons.alertCircle,
                                      color: approved
                                          ? AppColors.success
                                          : AppColors.error,
                                    );
                                    setState(() {
                                      if (_selectedPendingReviewIndex >=
                                          provider
                                              .pendingClinicalReviews
                                              .length) {
                                        _selectedPendingReviewIndex = 0;
                                      }
                                    });
                                  }
                                : null,
                            onReject:
                                pending[_selectedPendingReviewIndex]
                                            .reviewType ==
                                        'care_plan' &&
                                    context.read<AccessControlProvider>().can(
                                      AppPermission.rejectTreatment,
                                    )
                                ? (reason) => _decideReview(
                                    context,
                                    pending[_selectedPendingReviewIndex]
                                        .patient,
                                    ReviewDecision.reject,
                                    reason,
                                  )
                                : null,
                            onRequestInformation:
                                pending[_selectedPendingReviewIndex]
                                            .reviewType ==
                                        'care_plan' &&
                                    context.read<AccessControlProvider>().can(
                                      AppPermission.approveTreatment,
                                    )
                                ? (reason) => _decideReview(
                                    context,
                                    pending[_selectedPendingReviewIndex]
                                        .patient,
                                    ReviewDecision.moreInformation,
                                    reason,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _decideReview(
    BuildContext context,
    Patient patient,
    ReviewDecision decision,
    String reason,
  ) {
    final journey = context.read<JourneyProvider>();
    journey.bindExistingPatient(patient);
    final result = journey.review(decision, reason: reason);
    if (!mounted) return;
    CustomToast.show(
      context,
      title: result.success
          ? (decision == ReviewDecision.reject
                ? (context.isArabic ? 'تم رفض الطلب' : 'Request rejected')
                : (context.isArabic
                      ? 'تم طلب معلومات إضافية'
                      : 'Information requested'))
          : (context.isArabic ? 'تعذر حفظ القرار' : 'Decision was not saved'),
      message: result.success
          ? (context.isArabic
                ? 'حُفظ السبب في سجل الطلب وتحدّثت حالته.'
                : 'The reason was recorded and the request state updated.')
          : result.message,
      icon: result.success ? LucideIcons.checkCircle : LucideIcons.alertCircle,
      color: result.success ? AppColors.success : AppColors.error,
    );
    if (result.success) setState(() => _selectedPendingReviewIndex = 0);
  }

  // Dialog to check in patient weight
  // ignore: unused_element
  void _showWeightCheckInDialog(
    BuildContext context,
    Patient patient,
    DataProvider provider,
  ) {
    final controller = TextEditingController(text: patient.weight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr('record_weight_checkin', {
            'name': patient.getLocalizedFullName(context),
          }),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('enter_weight')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('weight_kg'),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(controller.text);
              if (w != null && w > 30.0) {
                provider.recordWeight(patient.id, w);
                Navigator.pop(context);
                final bmi =
                    (w / ((patient.height / 100) * (patient.height / 100)))
                        .toStringAsFixed(1);
                CustomToast.show(
                  context,
                  title: context.tr('weight_logged'),
                  message: context.tr('weight_logged_bmi', {'bmi': bmi}),
                  icon: LucideIcons.scale,
                  color: AppColors.success,
                );
              }
            },
            child: Text(context.tr('record')),
          ),
        ],
      ),
    );
  }

  // Dialog to escalate/change dose
  // ignore: unused_element
  void _showEscalateDoseDialog(
    BuildContext context,
    Patient patient,
    DataProvider provider,
  ) {
    String selectedDose = patient.currentDose;
    final doses = ['2.5 mg', '5 mg', '7.5 mg', '10 mg', '12.5 mg', '15 mg'];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            context.tr('escalate_dose_title', {
              'name': patient.getLocalizedFullName(context),
            }),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('current_dose_label', {'dose': patient.currentDose}),
              ),
              const SizedBox(height: 16),
              Text(context.tr('select_new_dose')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: doses.contains(selectedDose)
                    ? selectedDose
                    : doses.first,
                items: doses
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedDose = val;
                    });
                  }
                },
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateDose(patient.id, selectedDose);
                Navigator.pop(context);
                CustomToast.show(
                  context,
                  title: context.tr('prescription_updated'),
                  message: context.tr('dose_escalated_to', {
                    'dose': selectedDose,
                  }),
                  icon: LucideIcons.trendingUp,
                  color: AppColors.success,
                );
              },
              child: Text(context.tr('confirm_prescription')),
            ),
          ],
        ),
      ),
    );
  }
}
