import 'package:flutter/material.dart';
import '../../core/constants/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../eligibility/eligibility_card.dart';
import '../eligibility/clinical_assessment_card.dart';

class PatientProfileScreen extends StatelessWidget {
  final Patient patient;

  const PatientProfileScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(context),
            const SizedBox(height: 24),
            EligibilityCard(patient: patient),
            const SizedBox(height: 16),
            ClinicalAssessmentCard(patient: patient),
            const SizedBox(height: 16),
            _buildMedicalConditions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary,
          child: Text(
            patient.getLocalizedFullName(context).substring(0, 2).toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.getLocalizedFullName(context),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'EID: ${patient.emiratesId}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${patient.age} yrs • ${patient.getLocalizedGender(context)} • ${patient.getLocalizedNationality(context)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalConditions(BuildContext context) {
    if (patient.getLocalizedMedicalConditions(context).isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Conditions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: patient.getLocalizedMedicalConditions(context).map((condition) {
                return Chip(
                  label: Text(condition),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
