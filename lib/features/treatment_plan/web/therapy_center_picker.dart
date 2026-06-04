import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/localization/app_localizations.dart';

class TherapyCenterPicker extends StatefulWidget {
  final String patientEmirate;
  
  const TherapyCenterPicker({super.key, required this.patientEmirate});

  @override
  State<TherapyCenterPicker> createState() => _TherapyCenterPickerState();
}

class _TherapyCenterPickerState extends State<TherapyCenterPicker> {
  final MapController _mapController = MapController();
  PhysicalTherapyCenter? _selectedCenter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final centers = dataProvider.therapyCenters.where((c) => c.emirate == widget.patientEmirate).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.navy,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.translate('nearest_centers'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Map
              Expanded(
                flex: 2,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centers.isNotEmpty ? LatLng(centers.first.latitude, centers.first.longitude) : const LatLng(24.4539, 54.3773),
                    initialZoom: 11.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mounjaro.ncc',
                    ),
                    MarkerLayer(
                      markers: centers.map((c) {
                        final isSelected = _selectedCenter?.id == c.id;
                        return Marker(
                          point: LatLng(c.latitude, c.longitude),
                          width: isSelected ? 50 : 40,
                          height: isSelected ? 50 : 40,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCenter = c),
                            child: Icon(
                              LucideIcons.mapPin,
                              color: isSelected ? AppColors.primary : Colors.purple,
                              size: isSelected ? 40 : 30,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                flex: 1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: centers.length,
                  itemBuilder: (context, index) {
                    final c = centers[index];
                    final isSelected = _selectedCenter?.id == c.id;
                    return Card(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() => _selectedCenter = c);
                          _mapController.move(LatLng(c.latitude, c.longitude), 13.0);
                        },
                        title: Text(c.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.workingHours),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _selectedCenter != null ? () => Navigator.pop(context, _selectedCenter) : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Select Center'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
