import 'package:flutter/material.dart';
import '../../core/constants/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';

class EligibilityCard extends StatelessWidget {
  final Patient patient;
  final double mounjaroPrice;

  const EligibilityCard({
    super.key,
    required this.patient,
    this.mounjaroPrice = 1000.0,
  });

  double get _coveragePercentage {
    switch (patient.residencyStatus) {
      case ResidencyStatus.citizen:
        return 1.0;
      case ResidencyStatus.resident:
        return 0.5;
      case ResidencyStatus.visitor:
        return 0.0;
    }
  }

  double get _governmentContribution => mounjaroPrice * _coveragePercentage;
  double get _patientContribution => mounjaroPrice - _governmentContribution;

  BadgeStatus get _coverageBadgeStatus {
    if (_coveragePercentage == 1.0) return BadgeStatus.success;
    if (_coveragePercentage == 0.5) return BadgeStatus.info;
    return BadgeStatus.warning;
  }

  String get _coverageText {
    if (_coveragePercentage == 1.0) return '100% Covered (Citizen)';
    if (_coveragePercentage == 0.5) return '50% Covered (Resident)';
    return '0% Covered (Visitor)';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Eligibility Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StatusBadge(
                  label: _coverageText,
                  status: _coverageBadgeStatus,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildCostColumn(
                    context,
                    'Govt. Contribution',
                    'AED ${_governmentContribution.toStringAsFixed(2)}',
                    AppColors.success,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _buildCostColumn(
                    context,
                    'Patient Contribution',
                    'AED ${_patientContribution.toStringAsFixed(2)}',
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _coveragePercentage,
              backgroundColor: AppColors.border,
              color: AppColors.success,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostColumn(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
