import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../dispensing/dispensing_screen.dart';
import 'web/web_center_shell.dart';
import '../../../core/constants/mock_data.dart';

class CenterShell extends StatelessWidget {
  final String? initialPatientId;

  const CenterShell({super.key, this.initialPatientId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileCenterShell(initialPatientId: initialPatientId),
      web: WebCenterShell(initialPatientId: initialPatientId),
    );
  }
}

class MobileCenterShell extends StatefulWidget {
  final String? initialPatientId;

  const MobileCenterShell({super.key, this.initialPatientId});

  @override
  State<MobileCenterShell> createState() => _MobileCenterShellState();
}

class _MobileCenterShellState extends State<MobileCenterShell> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        DispensingScreen(highlightPatientId: widget.initialPatientId),
        const MobileInventoryTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.pill),
            label: context.tr('nav_dispense'),
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.package),
            label: context.tr('nav_inventory_nav'),
          ),
        ],
      ),
    );
  }
}

class MobileInventoryTab extends StatelessWidget {
  const MobileInventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final center = provider.centers.first; // Mocked first center

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('center_inventory')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(LucideIcons.building, color: AppColors.primary),
                title: Text(center.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(context.tr('region_row', {'region': center.getLocalizedRegion(context)})),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildInventoryTile(context, context.tr('mounjaro_dose_2_5'), center.inventory2_5mg),
                  _buildInventoryTile(context, context.tr('mounjaro_dose_5_0'), center.inventory5mg),
                  _buildInventoryTile(context, context.tr('mounjaro_dose_7_5'), center.inventory7_5mg),
                  _buildInventoryTile(context, context.tr('mounjaro_dose_10_0'), center.inventory10mg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTile(BuildContext context, String label, int count) {
    bool lowStock = count < 10;
    return Card(
      child: ListTile(
        leading: const Icon(LucideIcons.package),
        title: Text(label),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: lowStock ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            context.tr('units_count', {'count': '$count'}),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: lowStock ? AppColors.error : AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}
