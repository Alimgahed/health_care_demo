import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../dispensing/payment_screen.dart';
import '../../auth/login_screen.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/utils/dose_utils.dart';
import '../../clinical/clinical_eligibility_banner.dart';


class WebCenterShell extends StatefulWidget {
  final String? initialPatientId;
  final bool embeddedInAdmin;

  const WebCenterShell({
    super.key,
    this.initialPatientId,
    this.embeddedInAdmin = false,
  });

  @override
  State<WebCenterShell> createState() => _WebCenterShellState();
}

class _WebCenterShellState extends State<WebCenterShell> {
  int _selectedIndex = 0; // 0 = Dispense medication, 1 = Live Inventory, 2 = Dispense Logs
  Patient? _activePatient;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _centerId = 'C001'; // Mocked as Dubai Central Hospital for this shell

  Patient _livePatient(DataProvider provider, Patient fallback) {
    return provider.getPatientById(fallback.id) ?? fallback;
  }

  void _syncActivePatient(DataProvider provider) {
    if (_activePatient == null) return;
    final fresh = provider.getPatientById(_activePatient!.id);
    if (fresh != null) _activePatient = fresh;
  }

  void _afterDispenseComplete(DataProvider provider, String patientId) {
    setState(() {
      final fresh = provider.getPatientById(patientId);
      if (fresh != null && !provider.canDispensePatient(fresh)) {
        _activePatient = null;
        _searchController.clear();
        _searchQuery = '';
      } else {
        _syncActivePatient(provider);
      }
    });
  }

  String _dispensingStatusLabel(BuildContext context, DispensingUiStatus status) {
    switch (status) {
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

  Color _statusColor(DispensingUiStatus status) {
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

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        final p = dataProvider.getPatientById(widget.initialPatientId!);
        if (p != null && mounted) {
          setState(() {
            _activePatient = p;
            _searchController.text = p.emiratesId;
            _searchQuery = p.emiratesId;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    // Get current center details
    final center = dataProvider.centers.firstWhere((c) => c.id == _centerId, orElse: () => dataProvider.centers.first);

    final body = _selectedIndex == 0
        ? _buildDispenseView(context, dataProvider, center)
        : (_selectedIndex == 1
            ? _buildInventoryView(context, dataProvider, center)
            : _buildLogsView(context, dataProvider));

    if (widget.embeddedInAdmin) {
      return ColoredBox(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmbeddedAdminHeader(context, center, dataProvider),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        child: _buildSidebar(context, dataProvider),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopbar(context, localeProvider, dataProvider, center),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedAdminHeader(BuildContext context, DispensingCenter center, DataProvider provider) {
    final ready = provider.countPatientsReadyToDispense();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_embed_dispensing_title'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_embed_dispensing_sub', {'center': center.getLocalizedName(context)}),
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (ready > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '$ready ${context.tr('badge_ready_dispense')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _embeddedTab(context, LucideIcons.scanLine, context.tr('dispense_mounjaro'), 0),
              _embeddedTab(context, LucideIcons.package, context.tr('live_stock_inventory'), 1),
              _embeddedTab(context, LucideIcons.history, context.tr('dispensing_activity_logs'), 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _embeddedTab(BuildContext context, IconData icon, String label, int index) {
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar(BuildContext context, LocaleProvider localeProvider, DataProvider dataProvider, DispensingCenter center) {
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('dispensing_portal'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(center.getLocalizedName(context),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (dataProvider.countPatientsReadyToDispense() > 0) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${dataProvider.countPatientsReadyToDispense()} ${context.tr('badge_ready_dispense')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
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

  Widget _buildSidebar(BuildContext context, DataProvider provider) {
    final readyCount = provider.countPatientsReadyToDispense();
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
                      color: Colors.white.withValues(alpha: 0.08), width: 1)),
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
                        context.tr('ncc_brand'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        context.tr('center_portal_subtitle'),
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
                  _navSection(context.tr('nav_operations')),
                  _buildSidebarItem(
                    LucideIcons.scanLine,
                    context.tr('dispense_mounjaro'),
                    0,
                    badge: readyCount > 0 ? '$readyCount' : null,
                  ),
                  _buildSidebarItem(LucideIcons.package, context.tr('live_stock_inventory'), 1),
                  _buildSidebarItem(LucideIcons.history, context.tr('dispensing_activity_logs'), 2),
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
                      color: Colors.white.withValues(alpha: 0.08), width: 1)),
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
                    child: Text('PA',
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
                      Text(context.tr('pharmacist_role'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(context.tr('center_depot'),
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
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index, {String? badge}) {
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
                    : Colors.white.withValues(alpha: 0.55)),
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
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: AppColors.textPrimary,
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

  Widget _buildDispenseView(BuildContext context, DataProvider provider, DispensingCenter center) {
    // Left suggestions, right action form
    final suggestions = provider.patients.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.getLocalizedFullName(context).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.emiratesId.contains(_searchQuery);
      if (!matchesSearch) return false;
      if (_searchQuery.isEmpty) return provider.canDispensePatient(p);
      return true;
    }).toList()
      ..sort((a, b) {
        int rank(DispensingUiStatus s) {
          switch (s) {
            case DispensingUiStatus.eligible:
            case DispensingUiStatus.approvedEarly:
              return 0;
            case DispensingUiStatus.pendingClinicalReview:
              return 1;
            case DispensingUiStatus.pendingCarePlan:
              return 2;
            case DispensingUiStatus.clinicalIneligible:
              return 3;
          }
        }
        return rank(provider.dispensingUiStatus(a)).compareTo(rank(provider.dispensingUiStatus(b)));
      });
    final listPatients = suggestions.take(25).toList();

    return Row(
      children: [
        // Left Column (Patient Search & Selection) - 35%
        SizedBox(
          width: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('select_patient'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(context.tr('select_patient_sub'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration:  InputDecoration(
                        hintText: context.tr('search_eid_name'),
                        prefixIcon: Icon(LucideIcons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                child: Text(
                  _searchQuery.isEmpty ? context.tr('suggested_eligible') : context.tr('search_results'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(
                child: listPatients.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _searchQuery.isEmpty
                                ? context.tr('no_ready_to_dispense')
                                : context.tr('no_matching_patients'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                  itemCount: listPatients.length,
                  itemBuilder: (context, idx) {
                    final patient = listPatients[idx];
                    final uiStatus = provider.dispensingUiStatus(patient);
                    bool isSelected = _activePatient != null && _activePatient!.id == patient.id;
                    return Container(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            patient.getLocalizedFullName(context).substring(0, 1).toUpperCase(),
                            style: TextStyle(color: isSelected ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          patient.getLocalizedFullName(context),
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.emiratesId, style: const TextStyle(fontSize: 12)),
                            Text(
                              '${context.tr('last_dispense_date')}: ${patient.lastDispensingDate ?? context.tr('never_dispensed')}',
                              style: TextStyle(fontSize: 11, color: _statusColor(uiStatus)),
                            ),
                            Text(
                              _dispensingStatusLabel(context, uiStatus),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(uiStatus)),
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.ensureEarlyDispenseReviewQueued(patient.id);
                          setState(() {
                            _activePatient = provider.getPatientById(patient.id) ?? patient;
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
        // Right Column (Medication Dispensing details & verify) - 65%
        Expanded(
          child: _activePatient == null
              ? _buildEmptyState(context.tr('empty_select_patient'))
              : _buildVerificationPane(
                  context,
                  _livePatient(provider, _activePatient!),
                  center,
                  provider,
                ),
        ),
      ],
    );
  }

  Widget _buildVerificationPane(BuildContext context, Patient patient, DispensingCenter center, DataProvider provider) {
    final plan = provider.getPlanForPatient(patient.id);
    final intervalDays = provider.dispensingIntervalDaysFor(patient.id);
    final uiStatus = provider.dispensingUiStatus(patient);
    final canDispense = provider.canDispensePatient(patient);
    final displayDose = plan != null
        ? DoseUtils.toInventoryDose(plan.medicationDose)
        : patient.currentDose;
    final double price = 1000.0;
    final double coverage = patient.residencyStatus == ResidencyStatus.citizen ? 1.0 :
                            (patient.residencyStatus == ResidencyStatus.resident ? 0.5 : 0.0);
    final double govtPays = price * coverage;
    final double patientPays = price - govtPays;

    int stock = 0;
    final doseKey = DoseUtils.toInventoryDose(displayDose);
    if (doseKey == '2.5 mg') {
      stock = center.inventory2_5mg;
    } else if (doseKey == '5 mg') {
      stock = center.inventory5mg;
    } else if (doseKey == '7.5 mg') {
      stock = center.inventory7_5mg;
    } else if (doseKey == '10 mg') {
      stock = center.inventory10mg;
    }
    
    bool outOfStock = stock <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('dispensing_checkout'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor(uiStatus).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor(uiStatus).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      canDispense ? LucideIcons.checkCircle : LucideIcons.clock,
                      color: _statusColor(uiStatus),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dispensingStatusLabel(context, uiStatus),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor(uiStatus),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          ClinicalEligibilityBanner(patient: patient),
          if (!canDispense && uiStatus != DispensingUiStatus.clinicalIneligible)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, color: AppColors.warning, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      uiStatus == DispensingUiStatus.pendingCarePlan
                          ? context.tr('care_plan_pending_approval_msg')
                          : context.tr('dispense_pending_clinical_msg', {'date': patient.nextEligibleDate ?? ''}),
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          if (plan != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clipboardList, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('active_care_plan'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        if (plan.clinicalApprovalStatus == 'pending_review')
                          Text(
                            context.tr('care_plan_status_pending'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
                          ),
                        Text(
                          '${context.tr('injection_interval')}: ${context.tr('every_n_days', {'n': '$intervalDays'})}',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${context.tr('next_dispense_eligible')}: ${patient.nextEligibleDate ?? context.tr('now')}',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Patient Profile & Prescribed Dose
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('patient_diagnostics'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 20),
                        _buildDetailRow(context.tr('full_name'), patient.getLocalizedFullName(context)),
                        const SizedBox(height: 12),
                        _buildDetailRow(context.tr('emirates_id'), patient.emiratesId),
                        const SizedBox(height: 12),
                        _buildDetailRow(context.tr('residency_status'), _residencyLabel(context, patient.residencyStatus)),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context.tr('active_prescription'),
                          context.mounjaroDoseLabel(displayDose),
                          isHighlight: true,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(context.tr('last_dispense_date'), patient.lastDispensingDate ?? context.tr('never_dispensed')),
                        if (patient.lastDispensingCenterId != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context.tr('last_dispensing_facility'),
                            provider.dispensingFacilityLabel(context, patient.lastDispensingCenterId),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildDetailRow(context.tr('next_dispense_eligible'), patient.nextEligibleDate ?? context.tr('now')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Column 2: Financial Calculator & Stock Check
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('coverage_calculation'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 20),
                        _buildDetailRow(context.tr('medication_cost'), '1,000.00 AED'),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context.tr('govt_subsidy_line', {'pct': (coverage * 100).toStringAsFixed(0)}),
                          '${govtPays.toStringAsFixed(2)} AED',
                          color: AppColors.success,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(context.tr('patient_copay_collect'), '${patientPays.toStringAsFixed(2)} AED', isHighlight: true),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(LucideIcons.package, color: outOfStock ? AppColors.error : AppColors.success, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              outOfStock ? context.tr('out_of_stock_clinic') : context.tr('stock_level_available', {'count': '$stock'}),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: outOfStock ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Action Buttons Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activePatient = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(context.tr('cancel')),
                ),
              ),
              const SizedBox(width: 16),
              
              if (!canDispense)
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(LucideIcons.clock),
                  label: Text(context.tr('awaiting_clinical_approval')),
                )
              else
                ElevatedButton.icon(
                  onPressed: outOfStock
                      ? null
                      : () => _dispenseMedicationDirectly(context, patient, center, provider, patientPays),
                  icon: const Icon(LucideIcons.check),
                  label: Text(context.tr('confirm_verify_dispense')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _residencyLabel(BuildContext context, ResidencyStatus status) {
    switch (status) {
      case ResidencyStatus.citizen:
        return context.tr('emirati');
      case ResidencyStatus.resident:
        return context.tr('resident');
      case ResidencyStatus.visitor:
        return context.tr('visitor');
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlight ? 16 : 14,
            color: color ?? AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.scanFace, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInventoryView(BuildContext context, DataProvider provider, DispensingCenter center) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('inventory_stock_dashboard'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(context.tr('inventory_stock_sub'), style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _buildStockCard(context, context.tr('mounjaro_dose_2_5'), center.inventory2_5mg, 'C001_2.5')),
              const SizedBox(width: 16),
              Expanded(child: _buildStockCard(context, context.tr('mounjaro_dose_5_0'), center.inventory5mg, 'C001_5.0')),
              const SizedBox(width: 16),
              Expanded(child: _buildStockCard(context, context.tr('mounjaro_dose_7_5'), center.inventory7_5mg, 'C001_7.5')),
              const SizedBox(width: 16),
              Expanded(child: _buildStockCard(context, context.tr('mounjaro_dose_10_0'), center.inventory10mg, 'C001_10.0')),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('request_restock'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text(context.tr('request_restock_sub'), style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          provider.updateInventory(center.id, d2_5: 20, d5: 20, d7_5: 20, d10: 20);
                          CustomToast.show(
                            context,
                            title: context.tr('stock_updated'),
                            message: context.tr('stock_restock_msg'),
                            icon: LucideIcons.package,
                            color: AppColors.success,
                          );

                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(context.tr('simulate_restock')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, String doseTitle, int stock, String code) {
    bool lowStock = stock < 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(LucideIcons.package, color: AppColors.primary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lowStock ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lowStock ? context.tr('low_stock') : context.tr('good_stock'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: lowStock ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '$stock',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: lowStock ? AppColors.error : AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(doseTitle, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(context.tr('sku_label', {'code': code}), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsView(BuildContext context, DataProvider provider) {
    final facility = provider.getDispensingCenterById(_centerId) ?? provider.centers.first;
    final centerLogs = provider.logs
        .where(
          (l) =>
              l.centerName == facility.name ||
              l.centerNameAr == facility.nameAr ||
              l.getLocalizedCenterName(context) == facility.getLocalizedName(context),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('recent_center_activity'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(context.tr('recent_center_activity_sub'), style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ListView.separated(
                  itemCount: centerLogs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = centerLogs[index];
                    bool overridden = log.status == 'Overridden';
                    return ListTile(
                      leading: Icon(
                        overridden ? LucideIcons.shieldAlert : LucideIcons.checkCircle,
                        color: overridden ? AppColors.error : AppColors.success,
                      ),
                      title: Text('${log.getLocalizedPatientName(context)} - ${log.getLocalizedAction(context)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: Text(
                        log.eventKind == 'dispense'
                            ? '${context.tr('dispensed_at_facility', {'facility': log.getLocalizedCenterName(context)})}\n${context.tr('processed_at', {'time': log.formattedTimestamp})}'
                            : context.tr('processed_at', {'time': log.formattedTimestamp}),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: overridden ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.getLocalizedStatus(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: overridden ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dispenseMedicationDirectly(
    BuildContext context,
    Patient patient,
    DispensingCenter center,
    DataProvider provider,
    double copay,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          patient: patient,
          amountToPay: copay,
          onPaymentSuccess: () {
            provider.dispenseMedication(
              patientId: patient.id,
              centerId: center.id,
              dose: patient.currentDose,
            );
            _afterDispenseComplete(provider, patient.id);
            CustomToast.show(
              context,
              title: context.tr('medication_dispensed'),
              message: context.tr('medication_dispensed_msg', {'dose': patient.currentDose, 'name': patient.getLocalizedFullName(context)}),
              icon: LucideIcons.checkCircle,
              color: AppColors.success,
            );
          },
        ),
      ),
    );
  }

}