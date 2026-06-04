import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../eligibility/eligibility_card.dart';
import '../../eligibility/clinical_assessment_card.dart';
import '../../auth/login_screen.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/custom_toast.dart';



class WebDoctorShell extends StatefulWidget {
  const WebDoctorShell({super.key});

  @override
  State<WebDoctorShell> createState() => _WebDoctorShellState();
}

class _WebDoctorShellState extends State<WebDoctorShell> {
  int _selectedIndex = 0; // 0 = Patients, 1 = Assessments
  Patient? _selectedPatient;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, citizen, resident, critical, regular
  bool _isLoadingDetails = false;


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    // Initial selected patient if not set
    final filtered = _getFilteredPatients(dataProvider.patients);
    if (_selectedPatient == null && filtered.isNotEmpty) {
      _selectedPatient = filtered.first;
    } else if (_selectedPatient != null) {
      // Keep reference fresh from provider
      _selectedPatient = dataProvider.patients.firstWhere((p) => p.id == _selectedPatient!.id, orElse: () => filtered.first);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.stethoscope, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Clinician Portal',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navy),
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () => localeProvider.toggleLanguage(),
            icon: const Icon(LucideIcons.globe, color: AppColors.navy),
            label: Text(
              localeProvider.locale.languageCode == 'en' ? 'العربية' : 'English',
              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        children: [
          // Navigation Sidebar
          _buildSidebar(t),
          // Vertical divider
          Container(width: 1, color: AppColors.border),
          // Main content pane
          Expanded(
            child: _selectedIndex == 0 
                ? _buildPatientsView(t, dataProvider)
                : _buildAssessmentsView(t, dataProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations t) {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildSidebarItem(LucideIcons.users, 'Patients Registry', 0),
          _buildSidebarItem(LucideIcons.clipboardList, 'Clinical Assessments', 1),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(LucideIcons.user, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dr. Al Mandoos', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                      Text('Dubai Clinic #4', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.navy,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
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

  Widget _buildPatientsView(AppLocalizations t, DataProvider provider) {
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
                        hintText: 'Search by Name or Emirates ID',
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
                          _buildFilterChip('all', 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('citizen', 'Emiratis'),
                          const SizedBox(width: 8),
                          _buildFilterChip('resident', 'Residents'),
                          const SizedBox(width: 8),
                          _buildFilterChip('critical', 'BMI 35+'),
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
                  onPressed: () => _showRegisterPatientDialog(context, provider),
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: const Text('Register New Patient'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
              const Divider(height: 1),
              
              // Patient List
              Expanded(
                child: filtered.isEmpty 
                    ? _buildEmptyState('No patients found')
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
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('EID: ${patient.emiratesId}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: patient.bmi >= 35 ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'BMI ${patient.bmi.toStringAsFixed(1)}',
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
              ? _buildEmptyState('Select a patient to view full clinical profile')
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
                  : _buildPatientDetailsPane(context, _selectedPatient!, provider)),
        ),

      ],
    );
  }

  Widget _buildFilterChip(String filterCode, String label) {
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
      backgroundColor: Colors.white,
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
          const Icon(LucideIcons.user, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsPane(BuildContext context, Patient patient, DataProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  patient.getLocalizedFullName(context).substring(0, 2).toUpperCase(),
                  style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.getLocalizedFullName(context), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    Text('Emirates ID: ${patient.emiratesId}', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildBadgeChip('${patient.age} years', Colors.blue),
                        _buildBadgeChip(patient.getLocalizedGender(context), Colors.purple),
                        _buildBadgeChip(patient.getLocalizedNationality(context), Colors.orange),
                        _buildBadgeChip(patient.getLocalizedEmirate(context), Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons (Weight check-in & Escalation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showWeightCheckInDialog(context, patient, provider),
                    icon: const Icon(LucideIcons.scale, size: 16),
                    label: const Text('Record Weight Check-in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showEscalateDoseDialog(context, patient, provider),
                    icon: const Icon(LucideIcons.trendingUp, size: 16),
                    label: const Text('Escalate Dose'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          
          // Cards Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: EligibilityCard(patient: patient)),
              const SizedBox(width: 24),
              Expanded(child: ClinicalAssessmentCard(patient: patient)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Medical Conditions & Dosage History Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left card: Medical Conditions
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medical Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: patient.getLocalizedMedicalConditions(context).map((condition) {
                            return Chip(
                              label: Text(condition),
                              backgroundColor: AppColors.error.withOpacity(0.08),
                              labelStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text('Treatment Adherence Score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: patient.complianceRate,
                                color: patient.complianceRate >= 0.90 ? AppColors.success : AppColors.warning,
                                backgroundColor: AppColors.border,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(patient.complianceRate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: patient.complianceRate >= 0.90 ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Right card: Treatment Dose Timeline
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dose Escalation Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: patient.doseHistory.length,
                          itemBuilder: (context, idx) {
                            final revIndex = patient.doseHistory.length - 1 - idx;
                            final dose = patient.doseHistory[revIndex];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(LucideIcons.activity, color: AppColors.primary),
                              title: Text('Prescribed $dose Dose', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                              subtitle: Text('Phase check-in #${revIndex + 1}'),
                              trailing: idx == 0 
                                  ? const Chip(
                                      label: Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                      backgroundColor: AppColors.primary,
                                      side: BorderSide.none,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildAssessmentsView(AppLocalizations t, DataProvider provider) {
    // Assessments view
    final logs = provider.logs.where((l) => l.action.contains('escalated') || l.action.contains('Weight')).toList();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinical Assessments Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track system-wide clinical diagnostics, patient checks, and dose changes.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Assessments & Modifications Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: logs.isEmpty
                          ? _buildEmptyState('No assessments recorded yet')
                          : ListView.separated(
                              itemCount: logs.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(LucideIcons.stethoscope, color: Colors.white, size: 20),
                                  ),
                                  title: Text(
                                    '${log.getLocalizedPatientName(context)} (${log.patientId}) - ${log.getLocalizedAction(context)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                                  ),
                                  subtitle: Text('Recorded by: ${log.getLocalizedCenterName(context)}'),
                                  trailing: Text(
                                    '${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                );
                              },
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

  // Dialog to check in patient weight
  void _showWeightCheckInDialog(BuildContext context, Patient patient, DataProvider provider) {
    final controller = TextEditingController(text: patient.weight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Weight Check-in for ${patient.getLocalizedFullName(context)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter new patient weight (kg). BMI will be calculated automatically.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Weight (kg)',
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(controller.text);
              if (w != null && w > 30.0) {
                provider.recordWeight(patient.id, w);
                Navigator.pop(context);
                CustomToast.show(
                  context,
                  title: 'Weight Logged',
                  message: 'Weight check-in recorded! New BMI is ${(w / ((patient.height / 100) * (patient.height / 100))).toStringAsFixed(1)} kg/m².',
                  icon: LucideIcons.scale,
                  color: AppColors.success,
                );

              }
            },
            child: const Text('Record'),
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
          title: Text('Escalate Mounjaro Dose for ${patient.getLocalizedFullName(context)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current dose: ${patient.currentDose}'),
              const SizedBox(height: 16),
              const Text('Select new prescription dose:'),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateDose(patient.id, selectedDose);
                Navigator.pop(context);
                CustomToast.show(
                  context,
                  title: 'Prescription Updated',
                  message: 'Dose successfully escalated to $selectedDose.',
                  icon: LucideIcons.trendingUp,
                  color: AppColors.success,
                );

              },
              child: const Text('Confirm Prescription'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to register a brand new patient
  void _showRegisterPatientDialog(BuildContext context, DataProvider provider) {
    final nameController = TextEditingController();
    final emiratesIdController = TextEditingController(text: '784-1990-');
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    ResidencyStatus residency = ResidencyStatus.citizen;
    String gender = 'Male';
    String nationality = 'United Arab Emirates';
    String emirate = 'Dubai';
    List<String> selectedConditions = ['Obesity'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Register New Patient'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emiratesIdController,
                    decoration: const InputDecoration(labelText: 'Emirates ID'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          decoration: const InputDecoration(labelText: 'Gender'),
                          items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => gender = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight (kg)', suffixText: 'kg'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Height (cm)', suffixText: 'cm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ResidencyStatus>(
                          value: residency,
                          decoration: const InputDecoration(labelText: 'Residency Status'),
                          items: const [
                            DropdownMenuItem(value: ResidencyStatus.citizen, child: Text('Emirati')),
                            DropdownMenuItem(value: ResidencyStatus.resident, child: Text('Resident')),
                            DropdownMenuItem(value: ResidencyStatus.visitor, child: Text('Visitor')),
                          ],
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => residency = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: emirate,
                          decoration: const InputDecoration(labelText: 'Emirate'),
                          items: ['Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => emirate = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: nationality,
                    decoration: const InputDecoration(labelText: 'Nationality'),
                    items: ['United Arab Emirates', 'United Kingdom', 'United States', 'India', 'Pakistan', 'Egypt']
                        .map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => nationality = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final eid = emiratesIdController.text;
                final age = int.tryParse(ageController.text) ?? 0;
                final w = double.tryParse(weightController.text) ?? 0.0;
                final h = double.tryParse(heightController.text) ?? 0.0;

                if (name.isNotEmpty && eid.isNotEmpty && w > 0 && h > 0) {
                  final newP = Patient(
                    id: 'P${provider.patients.length + 1}',
                    emiratesId: eid,
                    fullName: name,
                    fullNameAr: name,
                    nationality: nationality,
                    nationalityAr: nationality,
                    residencyStatus: residency,
                    age: age,
                    gender: gender,
                    genderAr: gender == 'Male' ? 'ذكر' : 'أنثى',
                    weight: w,
                    height: h,
                    medicalConditions: selectedConditions,
                    medicalConditionsAr: selectedConditions,
                    lastDispensingDate: null,
                    nextEligibleDate: 'Eligible Now',
                    currentDose: '2.5 mg',
                    latitude: 24.4539,
                    longitude: 54.3773,
                    emirate: emirate,
                    emirateAr: emirate,
                    weightHistory: [w],
                    doseHistory: ['2.5 mg'],
                    complianceRate: 1.0,
                  );
                  provider.registerPatient(newP);
                  setState(() {
                    _selectedPatient = newP;
                  });
                  Navigator.pop(context);
                  CustomToast.show(
                    context,
                    title: 'Patient Registered',
                    message: '${newP.getLocalizedFullName(context)} registered successfully on Emirates Registry.',
                    icon: LucideIcons.userPlus,
                    color: AppColors.success,
                  );

                }
              },
              child: const Text('Register Patient'),
            ),
          ],
        ),
      ),
    );
  }
}
