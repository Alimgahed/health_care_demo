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
import '../../treatment_plan/web/patient_360_view.dart';



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
      drawer: Drawer(
        child: _buildSidebar(t),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopbar(t, localeProvider, dataProvider),
                Expanded(
                  child: _selectedIndex == 0 
                      ? _buildPatientsView(t, dataProvider)
                      : _buildAssessmentsView(t, dataProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar(AppLocalizations t, LocaleProvider localeProvider, DataProvider dataProvider) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.navy),
              onPressed: () {
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clinician Portal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              Text('Dubai Clinic #4',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: localeProvider.toggleLanguage,
            icon: const Icon(LucideIcons.globe, size: 14, color: AppColors.navy),
            label: Text(localeProvider.locale.languageCode == 'en' ? 'العربية' : 'English',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations t) {
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mounjaro NCC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Clinician Portal',
                        style: TextStyle(
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
                  _navSection('Clinical Tools'),
                  _buildSidebarItem(LucideIcons.users, 'Patients Registry', 0),
                  _buildSidebarItem(LucideIcons.clipboardList, 'Clinical Assessments', 1),
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
                  child: const Center(
                    child: Text('DM',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. Al Mandoos',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('Dubai Clinic #4',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11),
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

  Widget _buildSidebarItem(IconData icon, String title, int index) {
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
                  : Patient360View(patient: _selectedPatient!)),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
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
                              separatorBuilder: (context, index) => const Divider(color: AppColors.border),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(LucideIcons.stethoscope, color: AppColors.primary, size: 20),
                                  ),
                                  title: Text(
                                    '${log.getLocalizedPatientName(context)} (${log.patientId}) - ${log.getLocalizedAction(context)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                                  ),
                                  subtitle: Text('Recorded by: ${log.getLocalizedCenterName(context)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
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
