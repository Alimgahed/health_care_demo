import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/mock_data.dart';

class CoverageSimulatorScreen extends StatefulWidget {
  const CoverageSimulatorScreen({super.key});

  @override
  State<CoverageSimulatorScreen> createState() => _CoverageSimulatorScreenState();
}

class _CoverageSimulatorScreenState extends State<CoverageSimulatorScreen> {
  ResidencyStatus _selectedStatus = ResidencyStatus.citizen;
  double _mounjaroPrice = 1000.0;

  double get _coveragePercentage {
    switch (_selectedStatus) {
      case ResidencyStatus.citizen:
        return 1.0;
      case ResidencyStatus.resident:
        return 0.5;
      case ResidencyStatus.visitor:
        return 0.0;
    }
  }

  double get _governmentContribution => _mounjaroPrice * _coveragePercentage;
  double get _patientContribution => _mounjaroPrice - _governmentContribution;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coverage Simulator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Simulate Patient Coverage',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Calculate government subsidy and patient contribution based on residency status.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SegmentedButton<ResidencyStatus>(
                      segments: const [
                        ButtonSegment(value: ResidencyStatus.citizen, label: Text('Emirati')),
                        ButtonSegment(value: ResidencyStatus.resident, label: Text('Resident')),
                        ButtonSegment(value: ResidencyStatus.visitor, label: Text('Visitor')),
                      ],
                      selected: {_selectedStatus},
                      onSelectionChanged: (Set<ResidencyStatus> newSelection) {
                        setState(() {
                          _selectedStatus = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    Text('Mounjaro Price (AED)', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _mounjaroPrice,
                            min: 500,
                            max: 2000,
                            divisions: 15,
                            label: _mounjaroPrice.toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() {
                                _mounjaroPrice = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          '${_mounjaroPrice.toStringAsFixed(0)} AED',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Outputs
            Text('Simulation Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'Govt. Pays',
                    _governmentContribution,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultCard(
                    'Patient Pays',
                    _patientContribution,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coverage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${(_coveragePercentage * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              amount.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: color,
              ),
            ),
            Text(
              'AED',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
