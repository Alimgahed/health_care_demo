import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/kpi_card.dart';
import '../eligibility/coverage_simulator_screen.dart';

class MinistryDashboardScreen extends StatelessWidget {
  const MinistryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calculator),
            tooltip: 'Coverage Simulator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoverageSimulatorScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'National Mounjaro Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                KpiCard(
                  title: 'Total Patients',
                  value: '42,150',
                  icon: LucideIcons.users,
                  iconColor: AppColors.primary,
                  trend: '+12%',
                  isTrendPositive: true,
                ),
                KpiCard(
                  title: 'Eligible',
                  value: '28,400',
                  icon: LucideIcons.checkCircle,
                  iconColor: AppColors.success,
                  trend: '+5%',
                  isTrendPositive: true,
                ),
                KpiCard(
                  title: 'Govt Subsidy',
                  value: '14.2M',
                  subtitle: 'AED this month',
                  icon: LucideIcons.landmark,
                  iconColor: AppColors.accent,
                ),
                KpiCard(
                  title: 'Fraud Alerts',
                  value: '14',
                  icon: LucideIcons.shieldAlert,
                  iconColor: AppColors.error,
                  trend: '-2%',
                  isTrendPositive: true, // fewer alerts is good
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Dispensing Trends',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.barChart2, size: 48, color: AppColors.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Chart visualization will be rendered here\nusing fl_chart.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
