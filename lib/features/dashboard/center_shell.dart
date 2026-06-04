import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../dispensing/dispensing_screen.dart';
import 'web/web_center_shell.dart';
import '../../../core/constants/mock_data.dart';

class CenterShell extends StatelessWidget {
  const CenterShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileCenterShell(),
      web: WebCenterShell(),
    );
  }
}

class MobileCenterShell extends StatefulWidget {
  const MobileCenterShell({super.key});

  @override
  State<MobileCenterShell> createState() => _MobileCenterShellState();
}

class _MobileCenterShellState extends State<MobileCenterShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DispensingScreen(),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.pill),
            label: 'Dispense',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.package),
            label: 'Inventory',
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
        title: const Text('Center Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(LucideIcons.building, color: AppColors.primary),
                title: Text(center.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Region: ${center.getLocalizedRegion(context)}'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildInventoryTile('Mounjaro 2.5 mg', center.inventory2_5mg),
                  _buildInventoryTile('Mounjaro 5.0 mg', center.inventory5mg),
                  _buildInventoryTile('Mounjaro 7.5 mg', center.inventory7_5mg),
                  _buildInventoryTile('Mounjaro 10.0 mg', center.inventory10mg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTile(String label, int count) {
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
            '$count units',
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
