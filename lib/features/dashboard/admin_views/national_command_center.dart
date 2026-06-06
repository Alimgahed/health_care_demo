import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';

class NationalCommandCenter extends StatelessWidget {
  const NationalCommandCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('ncc_title')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExecutiveSummary(context),
            const SizedBox(height: 32),
            _buildObesityTrendChart(context),
            const SizedBox(height: 32),
            _buildConsumptionVsGoalChart(context),
            const SizedBox(height: 100), // Safe area bottom
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('exec_summary'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth >= 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: constraints.maxWidth >= 800 ? 1.5 : 1.2,
              children: [
                _buildKpiCard(
                  title: context.tr('total_active_patients'),
                  value: '14,289',
                  trend: '+12%',
                  isPositive: true,
                  icon: LucideIcons.users,
                ),
                _buildKpiCard(
                  title: context.tr('govt_subsidy'),
                  value: '42.5M AED',
                  trend: '+8%',
                  isPositive: false,
                  icon: LucideIcons.wallet,
                ),
                _buildKpiCard(
                  title: context.tr('national_bmi_drop'),
                  value: '-4.2 kg/m²',
                  trend: context.tr('target_met'),
                  isPositive: true,
                  icon: LucideIcons.activity,
                ),
                _buildKpiCard(
                  title: context.tr('fraud_prevented'),
                  value: context.tr('cases_count', {'count': '342'}),
                  trend: context.tr('cases_saved', {'amount': '1.2M'}),
                  isPositive: true,
                  icon: LucideIcons.shieldAlert,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPositive
                          ? Colors.green[700]
                          : Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObesityTrendChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('obesity_index_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.tr('obesity_index_subtitle'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.trendingDown, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border.withOpacity(0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final months = [
                          context.tr('month_jan'),
                          context.tr('month_mar'),
                          context.tr('month_may'),
                          context.tr('month_jul'),
                          context.tr('month_sep'),
                          context.tr('month_nov'),
                        ];
                        if (value.toInt() % 2 == 0 &&
                            value.toInt() < months.length * 2) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              months[value.toInt() ~/ 2],
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 28,
                maxY: 34,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 33.5),
                      FlSpot(1, 33.2),
                      FlSpot(2, 32.8),
                      FlSpot(3, 32.5),
                      FlSpot(4, 32.0),
                      FlSpot(5, 31.6),
                      FlSpot(6, 31.1),
                      FlSpot(7, 30.5),
                      FlSpot(8, 30.2),
                      FlSpot(9, 29.8),
                      FlSpot(10, 29.5),
                      FlSpot(11, 29.2),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionVsGoalChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('dispensing_vs_goals'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final titles = [
                          context.tr('quarter_q1'),
                          context.tr('quarter_q2'),
                          context.tr('quarter_q3'),
                          context.tr('quarter_q4'),
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            titles[value.toInt()],
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 75, 80),
                  _makeGroupData(1, 85, 90),
                  _makeGroupData(2, 95, 90),
                  _makeGroupData(3, 60, 95),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.primary, context.tr('actual_dispensed')),
              const SizedBox(width: 24),
              _buildLegend(AppColors.accent, context.tr('ministry_target')),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.primary,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: y2,
          color: AppColors.accent,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}