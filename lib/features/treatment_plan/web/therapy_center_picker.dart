import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/localization/l10n_extension.dart';

class _RankedCenter {
  final PhysicalTherapyCenter center;
  final double distanceKm;

  const _RankedCenter({required this.center, required this.distanceKm});
}

class TherapyCenterPicker extends StatefulWidget {
  final double patientLatitude;
  final double patientLongitude;
  final String patientEmirate;

  const TherapyCenterPicker({
    super.key,
    required this.patientLatitude,
    required this.patientLongitude,
    required this.patientEmirate,
  });

  @override
  State<TherapyCenterPicker> createState() => _TherapyCenterPickerState();
}

class _TherapyCenterPickerState extends State<TherapyCenterPicker> {
  final MapController _mapController = MapController();
  static const Distance _distance = Distance();
  PhysicalTherapyCenter? _selectedCenter;
  List<_RankedCenter> _ranked = [];
  bool _mapFitted = false;
  bool _initialized = false;

  List<_RankedCenter> _rankCenters(List<PhysicalTherapyCenter> all) {
    final origin = LatLng(widget.patientLatitude, widget.patientLongitude);
    final ranked = all
        .map(
          (c) => _RankedCenter(
            center: c,
            distanceKm: _distance.as(
              LengthUnit.Kilometer,
              origin,
              LatLng(c.latitude, c.longitude),
            ),
          ),
        )
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return ranked.take(8).toList();
  }

  void _fitMapToCenters() {
    if (_ranked.isEmpty || _mapFitted) return;
    final points = [
      LatLng(widget.patientLatitude, widget.patientLongitude),
      ..._ranked.map((r) => LatLng(r.center.latitude, r.center.longitude)),
    ];
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
    _mapFitted = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final dataProvider = Provider.of<DataProvider>(context);
    _ranked = _rankCenters(dataProvider.therapyCenters);
    if (_ranked.isNotEmpty) {
      _selectedCenter = _ranked.first.center;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitMapToCenters();
    });
  }

  @override
  Widget build(BuildContext context) {

    final patientPoint = LatLng(widget.patientLatitude, widget.patientLongitude);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.navy,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('nearest_centers'),
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('nearest_centers_sub', {
                        'count': '${_ranked.length}',
                        'emirate': widget.patientEmirate,
                      }),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ranked.isEmpty
              ? Center(child: Text(context.tr('no_therapy_centers_nearby')))
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: patientPoint,
                          initialZoom: 10.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.mounjaro.ncc',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: patientPoint,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  LucideIcons.user,
                                  color: AppColors.accent,
                                  size: 36,
                                ),
                              ),
                              ..._ranked.map((r) {
                                final isSelected = _selectedCenter?.id == r.center.id;
                                return Marker(
                                  point: LatLng(r.center.latitude, r.center.longitude),
                                  width: isSelected ? 50 : 42,
                                  height: isSelected ? 50 : 42,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedCenter = r.center),
                                    child: Icon(
                                      LucideIcons.mapPin,
                                      color: isSelected ? AppColors.primary : Colors.purple,
                                      size: isSelected ? 40 : 32,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ranked.length,
                        itemBuilder: (context, index) {
                          final r = _ranked[index];
                          final c = r.center;
                          final isSelected = _selectedCenter?.id == c.id;
                          final isNearest = index == 0;
                          return Card(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() => _selectedCenter = c);
                                _mapController.move(
                                  LatLng(c.latitude, c.longitude),
                                  13.0,
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.12),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                c.getLocalizedName(context),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('center_distance_km', {
                                      'km': r.distanceKm.toStringAsFixed(1),
                                    }),
                                  ),
                                  Text(
                                    '${c.getLocalizedEmirate(context)} · ${c.workingHours}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  if (isNearest)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        context.tr('nearest_center_badge'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _selectedCenter != null
                    ? () => Navigator.pop(context, _selectedCenter)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('select_center')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
