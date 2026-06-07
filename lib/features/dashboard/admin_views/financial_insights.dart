import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';

class FinancialInsights extends StatelessWidget {
  const FinancialInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('financial_insights')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubsidyDistribution(context),
            const SizedBox(height: 32),
            _buildBudgetPredictor(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsidyDistribution(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('subsidy_financial_distribution'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('subsidy_distribution_sub'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    color: AppColors.primary,
                    value: 65,
                    title: '65%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppColors.accent,
                    value: 25,
                    title: '25%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppColors.border,
                    value: 10,
                    title: '10%',
                    radius: 40,
                    titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(context, AppColors.primary, context.tr('legend_citizens_full_coverage')),
              const SizedBox(width: 16),
              _buildLegend(context, AppColors.accent, context.tr('legend_residents_half_coverage')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBudgetPredictor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.calculator, color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ai_budget_predictor'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.tr('next_quarter_projection'),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('estimated_q3_subsidy_requirement'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('q3_subsidy_amount_aed'),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.trendingUp, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('budget_forecast_abu_dhabi_dubai'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}