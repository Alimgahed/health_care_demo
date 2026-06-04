import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/mock_data.dart';

class WebMapAnalyticsScreen extends StatefulWidget {
  const WebMapAnalyticsScreen({super.key});

  @override
  State<WebMapAnalyticsScreen> createState() => _WebMapAnalyticsScreenState();
}

class _WebMapAnalyticsScreenState extends State<WebMapAnalyticsScreen> {
  String _selectedCategory = 'All'; // All, Patients, Pharmacies, Physical Therapy
  String _selectedEmirate = 'All';
  String _selectedRisk = 'All';
  String _searchQuery = '';

  dynamic selectedEntity; // Can be Patient, DispensingCenter, or PhysicalTherapyCenter
  bool _isDrawerOpen = false; // Controls the side drawer visibility

  final MapController _mapController = MapController();

  final List<String> _emiratesList = [
    'All',
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah'
  ];

  final List<String> _categories = [
    'All',
    'Patients',
    'Pharmacies',
    'Physical Therapy'
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dataProvider = Provider.of<DataProvider>(context);

    // Refresh selected entity from provider to reflect live changes
    if (selectedEntity != null) {
      if (selectedEntity is Patient) {
        final matches = dataProvider.patients.where((p) => p.id == selectedEntity.id);
        selectedEntity = matches.isNotEmpty ? matches.first : null;
      } else if (selectedEntity is DispensingCenter) {
        final matches = dataProvider.centers.where((c) => c.id == selectedEntity.id);
        selectedEntity = matches.isNotEmpty ? matches.first : null;
      } else if (selectedEntity is PhysicalTherapyCenter) {
        final matches = dataProvider.therapyCenters.where((tc) => tc.id == selectedEntity.id);
        selectedEntity = matches.isNotEmpty ? matches.first : null;
      }
      if (selectedEntity == null) _isDrawerOpen = false;
    }

    // Filter Patients
    final filteredPatients = dataProvider.patients.where((p) {
      if (_selectedCategory != 'All' && _selectedCategory != 'Patients') return false;
      if (_selectedEmirate != 'All' && p.emirate != _selectedEmirate) return false;
      if (_selectedRisk == 'Critical Obesity' && p.bmi < 35.0) return false;
      if (_selectedRisk == 'Low Stock') return false;
      if (_searchQuery.isNotEmpty &&
          (!p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) && 
           !p.fullNameAr.toLowerCase().contains(_searchQuery.toLowerCase())) &&
          !p.id.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    // Filter Dispensing Centers (Pharmacies)
    final filteredCenters = dataProvider.centers.where((c) {
      if (_selectedCategory != 'All' && _selectedCategory != 'Pharmacies') return false;
      if (_selectedEmirate != 'All' && c.region != _selectedEmirate) return false;
      if (_selectedRisk == 'Critical Obesity') return false;
      if (_selectedRisk == 'Low Stock') {
        final low = c.inventory2_5mg <= 10 || c.inventory5mg <= 10 || c.inventory7_5mg <= 10 || c.inventory10mg <= 10;
        if (!low) return false;
      }
      if (_searchQuery.isNotEmpty &&
          (!c.name.toLowerCase().contains(_searchQuery.toLowerCase()) && 
           !c.nameAr.toLowerCase().contains(_searchQuery.toLowerCase())) &&
          !c.id.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    // Filter Physical Therapy Centers
    final filteredTherapyCenters = dataProvider.therapyCenters.where((tc) {
      if (_selectedCategory != 'All' && _selectedCategory != 'Physical Therapy') return false;
      if (_selectedEmirate != 'All' && tc.emirate != _selectedEmirate) return false;
      if (_selectedRisk == 'Critical Obesity') return false;
      if (_selectedRisk == 'Low Stock') return false;
      if (_searchQuery.isNotEmpty &&
          (!tc.name.toLowerCase().contains(_searchQuery.toLowerCase()) && 
           !tc.nameAr.toLowerCase().contains(_searchQuery.toLowerCase())) &&
          !tc.id.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Map Layer (Full Screen)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(24.4539, 54.3773), // Centered on UAE
              initialZoom: 7.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _isDrawerOpen = false;
                  selectedEntity = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mounjaro.ncc',
              ),
              MarkerLayer(
                markers: [
                  // Physical Therapy Center Markers
                  ...filteredTherapyCenters.map((tc) {
                    final isSelected = selectedEntity is PhysicalTherapyCenter && selectedEntity.id == tc.id;
                    return Marker(
                      point: LatLng(tc.latitude, tc.longitude),
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 50 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedEntity = tc;
                            _isDrawerOpen = true;
                          });
                          _mapController.move(LatLng(tc.latitude, tc.longitude), 12.0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                            boxShadow: [
                              BoxShadow(color: Colors.purple.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: isSelected ? 5 : 2),
                            ],
                          ),
                          child: Icon(LucideIcons.activity, color: Colors.white, size: isSelected ? 24 : 18),
                        ),
                      ),
                    );
                  }),
                  // Dispensing Center Markers
                  ...filteredCenters.map((c) {
                    final isSelected = selectedEntity is DispensingCenter && selectedEntity.id == c.id;
                    return Marker(
                      point: LatLng(c.latitude, c.longitude),
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 50 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedEntity = c;
                            _isDrawerOpen = true;
                          });
                          _mapController.move(LatLng(c.latitude, c.longitude), 12.0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                            boxShadow: [
                              BoxShadow(color: AppColors.navy.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: isSelected ? 5 : 2),
                            ],
                          ),
                          child: Icon(LucideIcons.store, color: Colors.white, size: isSelected ? 24 : 18),
                        ),
                      ),
                    );
                  }),
                  // Patient Markers
                  ...filteredPatients.map((p) {
                    final isSelected = selectedEntity is Patient && selectedEntity.id == p.id;
                    final isCritical = p.bmi >= 35.0;
                    final mColor = isCritical ? AppColors.error : AppColors.primary;
                    
                    return Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: isSelected ? 40 : 30,
                      height: isSelected ? 40 : 30,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedEntity = p;
                            _isDrawerOpen = true;
                          });
                          _mapController.move(LatLng(p.latitude, p.longitude), 14.0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: mColor.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 1),
                            boxShadow: isSelected ? [BoxShadow(color: mColor.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 4)] : [],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Floating Filters Bar (Top Left/Center)
          Positioned(
            top: 24,
            left: 24,
            right: _isDrawerOpen ? 424 : 24, // Responsive padding based on drawer
            child: _buildFloatingFilters(t),
          ),

          // 3. Sliding Drawer (Right Side)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            right: _isDrawerOpen ? 0 : -400,
            width: 400,
            child: _buildDrawer(t),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingFilters(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Icon(LucideIcons.map, color: AppColors.navy),
          const SizedBox(width: 12),
          Text(
            t.translate('geo_analytics'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(width: 24),
          
          // Search Box
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t.translate('search'),
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Category Filter
          _buildDropdownFilter(
            value: _selectedCategory,
            items: _categories,
            onChanged: (val) => setState(() => _selectedCategory = val!),
            t: t,
          ),
          const SizedBox(width: 16),

          // Emirate Filter
          _buildDropdownFilter(
            value: _selectedEmirate,
            items: _emiratesList,
            onChanged: (val) => setState(() => _selectedEmirate = val!),
            t: t,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({required String value, required List<String> items, required Function(String?) onChanged, required AppLocalizations t}) {
    // Translate the visible values
    String getDisplayValue(String v) {
      if (v == 'All') return t.translate('filter_all');
      if (v == 'Patients') return t.translate('filter_patients');
      if (v == 'Pharmacies') return t.translate('filter_pharmacies');
      if (v == 'Physical Therapy') return t.translate('filter_rehab');
      return v;
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(getDisplayValue(e)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDrawer(AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(-10, 0)),
        ],
      ),
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.navy,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedEntity != null ? (
                      selectedEntity is Patient ? t.translate('patient_details') :
                      selectedEntity is DispensingCenter ? t.translate('center_details') :
                      t.translate('rehab_center_details')
                    ) : t.translate('geo_analytics'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => setState(() => _isDrawerOpen = false),
                ),
              ],
            ),
          ),
          
          // Drawer Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: selectedEntity == null
                  ? Center(child: Text(t.translate('select_marker'), style: const TextStyle(color: AppColors.textSecondary)))
                  : (selectedEntity is Patient
                      ? _buildPatientContent(selectedEntity as Patient, t)
                      : (selectedEntity is DispensingCenter
                          ? _buildCenterContent(selectedEntity as DispensingCenter, t)
                          : _buildTherapyContent(selectedEntity as PhysicalTherapyCenter, t))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientContent(Patient p, AppLocalizations t) {
    final isCritical = p.bmi >= 35.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Profile
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: isCritical ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(LucideIcons.user, color: isCritical ? AppColors.error : AppColors.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.getLocalizedFullName(context), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCritical ? t.translate('flagged') : t.translate('success'),
                      style: TextStyle(color: isCritical ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Info Cards
        _buildInfoCard(LucideIcons.hash, t.translate('eid'), p.emiratesId),
        _buildInfoCard(LucideIcons.calendar, t.translate('age'), '${p.age} ${t.translate('age')} (${p.getLocalizedGender(context)})'),
        _buildInfoCard(LucideIcons.mapPin, t.translate('residency'), '${p.getLocalizedResidency(context)} · ${p.getLocalizedEmirate(context)}'),
        
        const SizedBox(height: 24),
        const Divider(color: AppColors.border),
        const SizedBox(height: 24),

        // Health Metrics
        Text(t.translate('health_metrics'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricBox(t.translate('weight'), '${p.weight} kg', AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricBox(t.translate('bmi'), p.bmi.toStringAsFixed(1), isCritical ? AppColors.error : AppColors.warning)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricBox(t.translate('current_dose'), p.currentDose, AppColors.accent)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricBox(t.translate('adherence'), '${(p.complianceRate * 100).toInt()}%', AppColors.success)),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(color: AppColors.border),
        const SizedBox(height: 24),

        // Medical Conditions
        Text(t.translate('medical_conditions'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.getLocalizedMedicalConditions(context).map((cond) => Chip(
            label: Text(cond),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCenterContent(DispensingCenter c, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: const Icon(LucideIcons.store, color: AppColors.navy, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.getLocalizedName(context), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text('${c.getLocalizedRegion(context)} Region', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        Text(t.translate('inventory_status'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 16),
        
        _buildInventoryRow('2.5 mg', c.inventory2_5mg, c.dispensed2_5mg, t),
        _buildInventoryRow('5.0 mg', c.inventory5mg, c.dispensed5mg, t),
        _buildInventoryRow('7.5 mg', c.inventory7_5mg, c.dispensed7_5mg, t),
        _buildInventoryRow('10.0 mg', c.inventory10mg, c.dispensed10mg, t),
      ],
    );
  }

  Widget _buildTherapyContent(PhysicalTherapyCenter tc, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              child: const Icon(LucideIcons.activity, color: Colors.purple, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tc.getLocalizedName(context), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text(tc.getLocalizedEmirate(context), style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildInfoCard(LucideIcons.userPlus, t.translate('chief_therapist'), tc.getLocalizedChiefTherapist(context)),
        _buildInfoCard(LucideIcons.users, t.translate('active_patients_rehab'), '${tc.activePatients}'),
        _buildInfoCard(LucideIcons.clock, t.translate('working_hours'), tc.workingHours),
        
        const SizedBox(height: 24),
        const Divider(color: AppColors.border),
        const SizedBox(height: 24),

        Text(t.translate('services_offered'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tc.getLocalizedServices(context).map((s) => Chip(
            label: Text(s),
            backgroundColor: Colors.purple.withValues(alpha: 0.05),
            side: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.withAlpha(200))),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(String dose, int inventory, int dispensed, AppLocalizations t) {
    bool isOutOfStock = inventory == 0;
    bool isLowStock = inventory > 0 && inventory <= 10;
    Color statusColor = isOutOfStock ? AppColors.error : (isLowStock ? AppColors.warning : AppColors.success);
    String statusText = isOutOfStock ? t.translate('out_of_stock') : (isLowStock ? t.translate('low_stock') : t.translate('available'));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dose, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.translate('available'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('$inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.translate('actual_dispensed'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('$dispensed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar showing allocated (dispensed) vs total
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (inventory + dispensed) > 0 ? (dispensed / (inventory + dispensed)) : 0,
              backgroundColor: statusColor.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
