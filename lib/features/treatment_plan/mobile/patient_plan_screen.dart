import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import 'medication_reminder_widget.dart';
import 'session_checkin_screen.dart';
import 'home_exercises_screen.dart';

class PatientPlanScreen extends StatelessWidget {
  final Patient patient;

  const PatientPlanScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final plan = dataProvider.getPlanForPatient(patient.id);

    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text('No Active Treatment Plan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Your doctor hasn\'t assigned a plan yet.', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.translate('my_plan'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 24),
          
          MedicationReminderWidget(plan: plan),
          const SizedBox(height: 32),

          Text(t.translate('therapy_plan'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 16),
          _buildTherapySection(context, plan, t),
          
          const SizedBox(height: 32),
          Text(t.translate('home_exercises'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 16),
          _buildExercisesSection(context, plan, t, isAr),
        ],
      ),
    );
  }

  Widget _buildTherapySection(BuildContext context, TreatmentPlan plan, AppLocalizations t) {
    final upcomingSession = plan.sessions.firstWhere((s) => !s.isAttended, orElse: () => plan.sessions.last);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(plan.assignedCenterId ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session ${upcomingSession.sessionNumber} / ${plan.totalSessions}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${upcomingSession.scheduledDate.day}/${upcomingSession.scheduledDate.month}/${upcomingSession.scheduledDate.year}', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              if (!upcomingSession.isAttended)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SessionCheckinScreen(plan: plan, session: upcomingSession)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: Text(t.translate('session_checkin')),
                )
              else
                const Icon(LucideIcons.checkCircle, color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection(BuildContext context, TreatmentPlan plan, AppLocalizations t, bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ...plan.homeExercises.take(2).map((e) => ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.activity, color: AppColors.primary),
            ),
            title: Text(isAr ? e.nameAr : e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${e.durationMinutes} min • ${e.sets}x${e.reps}'),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HomeExercisesScreen(plan: plan)));
            },
          )),
          if (plan.homeExercises.length > 2)
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HomeExercisesScreen(plan: plan)));
              },
              child: const Text('View All Exercises'),
            ),
        ],
      ),
    );
  }
}
