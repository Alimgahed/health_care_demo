import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

class AppointmentsScreen extends StatelessWidget {
  final Patient patient;

  const AppointmentsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final items =
        context.watch<DataProvider>().appointmentsFor(patient.id).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final now = DateTime.now();
    final upcoming = items
        .where(
          (item) =>
              item.dateTime.isAfter(now) &&
              item.status != AppointmentStatus.cancelled,
        )
        .toList();
    final history = items.where((item) => !upcoming.contains(item)).toList();
    final ar = context.isArabic;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          ar ? 'مواعيد الرعاية' : 'Care appointments',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ar
              ? 'مواعيدك وجلسات المتابعة المسجلة'
              : 'Your scheduled visits and follow-ups',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _AppointmentSection(
          title: ar ? 'القادمة' : 'Upcoming',
          appointments: upcoming,
          emptyText: ar ? 'لا توجد مواعيد قادمة.' : 'No upcoming appointments.',
        ),
        const SizedBox(height: 20),
        _AppointmentSection(
          title: ar ? 'السابقة' : 'Past appointments',
          appointments: history.reversed.toList(),
          emptyText: ar ? 'لا توجد مواعيد سابقة.' : 'No past appointments.',
        ),
      ],
    );
  }
}

class _AppointmentSection extends StatelessWidget {
  final String title;
  final List<PatientAppointment> appointments;
  final String emptyText;

  const _AppointmentSection({
    required this.title,
    required this.appointments,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final ar = context.isArabic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (appointments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(LucideIcons.calendarX2, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      emptyText,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...appointments.map((appointment) {
            final date = appointment.dateTime;
            final completed = appointment.status == AppointmentStatus.completed;
            final cancelled = appointment.status == AppointmentStatus.cancelled;
            final status = completed
                ? (ar ? 'مكتمل' : 'Completed')
                : cancelled
                ? (ar ? 'ملغي' : 'Cancelled')
                : (ar ? 'مجدول' : 'Scheduled');
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                minVerticalPadding: 14,
                leading: CircleAvatar(
                  backgroundColor: AppColors.paleSurface,
                  foregroundColor: AppColors.primaryDark,
                  child: const Icon(LucideIcons.calendarDays, size: 20),
                ),
                title: Text(
                  appointment.purpose,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '${appointment.doctor}\n${date.toLocal().toString().substring(0, 16)}',
                  ),
                ),
                isThreeLine: true,
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: Text(
                    status,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: cancelled
                          ? AppColors.errorText
                          : completed
                          ? AppColors.successText
                          : AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
