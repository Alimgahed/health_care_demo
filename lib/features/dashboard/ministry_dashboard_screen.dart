import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/demo_metrics.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/kpi_card.dart';
import '../eligibility/coverage_simulator_screen.dart';

class MinistryDashboardScreen extends StatelessWidget {
  const MinistryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('executive_dashboard')),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calculator),
            tooltip: context.tr('coverage_simulator'),
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
              context.tr('national_overview'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('national_registry')}: ${DemoMetrics.formatCount(DemoMetrics.nationalEnrolled)} · ${context.tr('demo_cohort')}: ${dp.totalActivePatients}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
                  title: context.tr('total_patients'),
                  value: DemoMetrics.formatCount(DemoMetrics.nationalEnrolled),
                  icon: LucideIcons.users,
                  iconColor: AppColors.primary,
                  trend: '+12%',
                  isTrendPositive: true,
                ),
                KpiCard(
                  title: context.tr('eligible'),
                  value: DemoMetrics.formatCount(DemoMetrics.nationalEligible),
                  icon: LucideIcons.checkCircle,
                  iconColor: AppColors.success,
                  trend: '+5%',
                  isTrendPositive: true,
                ),
                KpiCard(
                  title: context.tr('govt_subsidy'),
                  value: DemoMetrics.formatAed(dp.totalGovtSubsidyDisbursed),
                  subtitle: context.tr('cumulative'),
                  icon: LucideIcons.landmark,
                  iconColor: AppColors.accent,
                ),
                KpiCard(
                  title: context.tr('fraud_alerts'),
                  value: '${dp.fraudIncidentsPrevented}',
                  icon: LucideIcons.shieldAlert,
                  iconColor: AppColors.error,
                  trend: '-2%',
                  isTrendPositive: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              context.tr('dispensing_trends'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: LineChart(
                    duration: Duration.zero,
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 50,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 12),
                            FlSpot(1, 18),
                            FlSpot(2, 22),
                            FlSpot(3, 28),
                            FlSpot(4, 35),
                            FlSpot(5, 40),
                          ],
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
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
