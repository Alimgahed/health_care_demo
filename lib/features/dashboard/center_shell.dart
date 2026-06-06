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
                leading: Icon(LucideIcons.building, color: AppColors.primary),
                title: Text(center.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(context.tr('region_row', {'region': center.getLocalizedRegion(context)})),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildInventoryTile(context, context.tr('mounjaro_dose_2_5'), center.inventory2_5mg, center.dispensed2_5mg),
                  _buildInventoryTile(context, context.tr('mounjaro_dose_5_0'), center.inventory5mg, center.dispensed5mg),
                  _buildInventoryTile(context, context.tr('mounjaro_dose_7_5'), center.inventory7_5mg, center.dispensed7_5mg),
                  _buildInventoryTile(context, context.tr('mounjaro_dose_10_0'), center.inventory10mg, center.dispensed10mg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTile(BuildContext context, String label, int available, int dispensed) {
    bool lowStock = available < 10;
    int total = available + dispensed;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lowStock ? AppColors.error.withValues(alpha: 0.3) : Colors.transparent),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.package, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                ),
                if (lowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(context.tr('replenishment_critical'), style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(context.tr('stock_total'), total.toString(), AppColors.navy),
                Container(width: 1, height: 30, color: AppColors.border),
                _buildStatColumn(context.tr('stock_dispensed'), dispensed.toString(), AppColors.primary),
                Container(width: 1, height: 30, color: AppColors.border),
                _buildStatColumn(context.tr('stock_available'), available.toString(), lowStock ? AppColors.error : AppColors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}