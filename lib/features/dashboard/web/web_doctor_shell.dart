import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../eligibility/eligibility_card.dart';
import '../../eligibility/clinical_assessment_card.dart';
import '../../auth/login_screen.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../treatment_plan/web/patient_360_view.dart';
import '../../clinical/clinical_review_detail_panel.dart';
import '../../clinical/register_patient_dialog.dart';
import '../program_alerts.dart';



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
  late int _selectedIndex;
  Patient? _selectedPatient;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, citizen, resident, critical, regular
  bool _isLoadingDetails = false;
  int _selectedPendingReviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 1);
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
      _selectedPatient = demoPatient ?? (filtered.isNotEmpty ? filtered.first : null);
    } else if (_selectedPatient != null) {
      final idx = dataProvider.patients.indexWhere((p) => p.id == _selectedPatient!.id);
      _selectedPatient = idx >= 0
          ? dataProvider.patients[idx]
          : (filtered.isNotEmpty ? filtered.first : null);
    }

    final pendingAuthCount = pendingAuthorizationReviewCount(dataProvider);
    final pendingAuthBadge =
        pendingAuthCount > 0 ? '$pendingAuthCount' : null;

    final body = _selectedIndex == 0
        ? _buildPatientsView(context, dataProvider)
        : _buildAssessmentsView(context, dataProvider);

    if (widget.embeddedInAdmin) {
      return ColoredBox(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmbeddedAdminHeader(context, pendingAuthBadge: pendingAuthBadge),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        child: _buildSidebar(context, pendingAuthBadge: pendingAuthBadge),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopbar(context, localeProvider, dataProvider),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
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
          Text(
            context.tr('admin_embed_clinical_title'),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('admin_embed_clinical_sub'),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _embeddedTab(context, LucideIcons.users, context.tr('patients_registry'), 0),
              const SizedBox(width: 10),
              _embeddedTab(
                context,
                LucideIcons.clipboardList,
                context.tr('clinical_assessments'),
                1,
                badge: pendingAuthBadge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _embeddedTab(
    BuildContext context,
    IconData icon,
    String label,
    int index, {
    String? badge,
  }) {
    final selected = _selectedIndex == index;
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar(BuildContext context, LocaleProvider localeProvider, DataProvider dataProvider) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
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
              Text(context.tr('clinical_portal'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(context.tr('doc_clinic'),
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: localeProvider.toggleLanguage,
            icon: Icon(LucideIcons.globe, size: 14, color: AppColors.textPrimary),
            label: Text(localeProvider.locale.languageCode == 'en' ? context.tr('arabic') : context.tr('english'),
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(LucideIcons.logOut, size: 18, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: IconButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      color: Colors.white.withOpacity(0.08), width: 1)),
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
                  child: Icon(Icons.health_and_safety,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('clinical_brand'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        context.tr('clinical_portal'),
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
                  _navSection(context.tr('clinical_tools')),
                  _buildSidebarItem(context, LucideIcons.users, context.tr('patients_registry'), 0),
                  _buildSidebarItem(
                    context,
                    LucideIcons.clipboardList,
                    context.tr('clinical_assessments'),
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
                      color: Colors.white.withOpacity(0.08), width: 1)),
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
                    child: Text('DM',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('doc_name'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(context.tr('doc_clinic'),
                          style: TextStyle(
                              color: AppColors.surface54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
          color: Colors.white.withOpacity(0.35),
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
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
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
      final matchesSearch = p.getLocalizedFullName(context).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.emiratesId.contains(_searchQuery) ||
          p.id.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;

      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'citizen') return p.residencyStatus == ResidencyStatus.citizen;
      if (_selectedFilter == 'resident') return p.residencyStatus == ResidencyStatus.resident;
      if (_selectedFilter == 'critical') return p.bmi >= 35.0;
      if (_selectedFilter == 'regular') return p.bmi < 35.0;
      return true;
    }).toList();
  }

  Widget _buildPatientsView(BuildContext context, DataProvider provider) {
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                          _buildFilterChip(context, 'citizen', context.tr('citizens')),
                          const SizedBox(width: 8),
                          _buildFilterChip(context, 'resident', context.tr('residents')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Register Patient Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newP = await RegisterPatientDialog.show(context);
                    if (newP != null && mounted) {
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
                    ? _buildEmptyState(context.tr('no_matching_patients'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final patient = filtered[index];
                          bool isSelected = _selectedPatient != null && _selectedPatient!.id == patient.id;
                          return Container(
                            color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  patient.getLocalizedFullName(context).substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient.getLocalizedFullName(context),
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(context.tr('eid_label', {'id': patient.emiratesId})),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: patient.bmi >= 35 ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  context.tr('bmi_label', {'value': patient.bmi.toStringAsFixed(1)}),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: patient.bmi >= 35 ? AppColors.error : AppColors.success,
                                  ),
                                ),
                              ),
                              onTap: () {
                                if (_selectedPatient?.id == patient.id) return;
                                setState(() {
                                  _isLoadingDetails = true;
                                  _selectedPatient = patient;
                                });
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    setState(() {
                                      _isLoadingDetails = false;
                                    });
                                  }
                                });
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

  Widget _buildFilterChip(BuildContext context, String filterCode, String label) {
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
      selectedColor: AppColors.primary.withOpacity(0.15),
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.user, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

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
            context.tr('clinical_assessments_dashboard'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                                        color: AppColors.warning.withValues(alpha: 0.15),
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
                                    final selected = index == _selectedPendingReviewIndex;
                                    final reason = item.reviewType == 'care_plan'
                                        ? context.tr('review_type_care_plan')
                                        : context.tr('review_type_early_dispense');
                                    return Material(
                                      color: selected
                                          ? AppColors.primary.withValues(alpha: 0.06)
                                          : Colors.transparent,
                                      child: ListTile(
                                        selected: selected,
                                        onTap: () => setState(() => _selectedPendingReviewIndex = index),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                                          child: Text(
                                            p.getLocalizedFullName(context).substring(0, 1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          p.getLocalizedFullName(context),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(reason, style: const TextStyle(fontSize: 12)),
                                        trailing: Text(p.id, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                            patient: pending[_selectedPendingReviewIndex].patient,
                            reviewType: pending[_selectedPendingReviewIndex].reviewType,
                            onApprove: () {
                              final item = pending[_selectedPendingReviewIndex];
                              provider.approveClinicalReview(item.patient.id);
                              CustomToast.show(
                                context,
                                title: context.tr('clinical_review_approved_title'),
                                message: context.tr('clinical_review_approved_msg', {
                                  'name': item.patient.getLocalizedFullName(context),
                                }),
                                icon: LucideIcons.checkCircle,
                                color: AppColors.success,
                              );
                              setState(() {
                                if (_selectedPendingReviewIndex >= provider.pendingClinicalReviews.length) {
                                  _selectedPendingReviewIndex = 0;
                                }
                              });
                            },
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

  // Dialog to check in patient weight
  void _showWeightCheckInDialog(BuildContext context, Patient patient, DataProvider provider) {
    final controller = TextEditingController(text: patient.weight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('record_weight_checkin', {'name': patient.getLocalizedFullName(context)})),
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
                final bmi = (w / ((patient.height / 100) * (patient.height / 100))).toStringAsFixed(1);
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
  void _showEscalateDoseDialog(BuildContext context, Patient patient, DataProvider provider) {
    String selectedDose = patient.currentDose;
    final doses = ['2.5 mg', '5 mg', '7.5 mg', '10 mg', '12.5 mg', '15 mg'];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(context.tr('escalate_dose_title', {'name': patient.getLocalizedFullName(context)})),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('current_dose_label', {'dose': patient.currentDose})),
              const SizedBox(height: 16),
              Text(context.tr('select_new_dose')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: doses.contains(selectedDose) ? selectedDose : doses.first,
                items: doses.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedDose = val;
                    });
                  }
                },
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  message: context.tr('dose_escalated_to', {'dose': selectedDose}),
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