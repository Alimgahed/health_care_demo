import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

enum ProgramAlertKind {
  readyDispense,
  clinicalPending,
  inventory,
  override,
  flagged,
  allClear,
  fraudAttempt,
  clinicalIneffective,
  criticalShortage,
  nonCompliance,
}

class ProgramAlert {
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  final ProgramAlertKind kind;
  final Map<String, dynamic> metadata;

  const ProgramAlert({
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    required this.kind,
    this.metadata = const {},
  });
}

/// National safety / supply alerts (shared by dashboard panel, full view, nav badge).
List<ProgramAlert> collectProgramAlerts(BuildContext context, DataProvider dp) {
  final tr = context.tr;
  final alerts = <ProgramAlert>[];

  final readyCount = dp.countPatientsReadyToDispense();
  if (readyCount > 0) {
    alerts.add(
      ProgramAlert(
        message: tr('alert_ready_dispense', {'count': '$readyCount'}),
        icon: LucideIcons.pill,
        color: AppColors.success,
        time: tr('now'),
        kind: ProgramAlertKind.readyDispense,
      ),
    );
  }

  final pendingReviews = dp.pendingClinicalReviews.length;
  if (pendingReviews > 0) {
    alerts.add(
      ProgramAlert(
        message: tr('alert_pending_reviews', {'count': '$pendingReviews'}),
        icon: LucideIcons.stethoscope,
        color: AppColors.warning,
        time: tr('now'),
        kind: ProgramAlertKind.clinicalPending,
      ),
    );
  }

  for (final center in dp.centers) {
    void low(String dose, int units) {
      if (units > 10) return;
      alerts.add(
        ProgramAlert(
          message: tr('inventory_low_msg', {
            'center': center.getLocalizedName(context),
            'dose': dose,
            'units': '$units',
          }),
          icon: Icons.warning_amber_rounded,
          color: units <= 5 ? AppColors.error : AppColors.warning,
          time: tr('now'),
          kind: ProgramAlertKind.inventory,
        ),
      );
    }

    low('2.5 mg', center.inventory2_5mg);
    low('5 mg', center.inventory5mg);
    low('7.5 mg', center.inventory7_5mg);
    low('10 mg', center.inventory10mg);
  }

  for (final log in dp.logs.where((l) => l.status == 'Overridden').take(8)) {
    alerts.add(
      ProgramAlert(
        message: tr('fraud_log_entry', {
          'patient': log.getLocalizedPatientName(context),
          'id': log.patientId,
          'action': log.getLocalizedAction(context),
          'center': log.getLocalizedCenterName(context),
        }),
        icon: LucideIcons.shieldCheck,
        color: AppColors.warning,
        time: tr('today'),
        kind: ProgramAlertKind.override,
      ),
    );
  }

  // --- NEW AI DRIVEN ALERTS ---
  
  // 1. Supply Crisis (Critical Shortage)
  for (final center in dp.centers) {
    void checkShortage(String dose, int units) {
      if (units == 0) {
        alerts.insert(0,
          ProgramAlert(
            message: tr('alert_critical_shortage', {
              'center': center.getLocalizedName(context),
              'dose': dose,
              'count': '0',
            }),
            icon: LucideIcons.alertTriangle,
            color: AppColors.error,
            time: tr('now'),
            kind: ProgramAlertKind.criticalShortage,
            metadata: {
              'centerName': center.getLocalizedName(context),
              'dose': dose,
              'units': units,
            },
          ),
        );
      }
    }
    checkShortage('2.5 mg', center.inventory2_5mg);
    checkShortage('5.0 mg', center.inventory5mg);
    checkShortage('7.5 mg', center.inventory7_5mg);
    checkShortage('10.0 mg', center.inventory10mg);
  }

  // 2. Fraud & Compliance & Clinical
  for (final patient in dp.patients) {
    final patientName = Localizations.localeOf(context).languageCode == 'ar' ? patient.fullNameAr : patient.fullName;
    
    // Fraud Attempt (Mock logic: if patient has override logs, assume they tried double dispense)
    if (dp.logs.any((l) => l.patientId == patient.id && l.status == 'Overridden')) {
      alerts.insert(0,
        ProgramAlert(
          message: tr('alert_fraud_attempt', {'name': patientName}),
          icon: LucideIcons.shieldAlert,
          color: AppColors.error,
          time: tr('today'),
          kind: ProgramAlertKind.fraudAttempt,
          metadata: {
            'patientName': patientName,
            'emiratesId': patient.emiratesId,
          },
        ),
      );
    }

    // Clinical Ineffective (Mock logic: if weight loss is < 1kg and they are on a high dose)
    if (patient.weightHistory.isNotEmpty && (patient.weightHistory.first - patient.weight < 1.0) && (patient.currentDose == '10 mg' || patient.currentDose == '10.0 mg' || patient.currentDose == '7.5 mg')) {
      alerts.add(
        ProgramAlert(
          message: tr('alert_clinical_ineffective', {'name': patientName}),
          icon: LucideIcons.activity,
          color: AppColors.accent,
          time: '2 days ago',
          kind: ProgramAlertKind.clinicalIneffective,
          metadata: {
            'patientName': patientName,
            'startingWeight': patient.weightHistory.first,
            'currentWeight': patient.weight,
            'currentDose': patient.currentDose,
          },
        ),
      );
    }

    // Non Compliance (Mock logic: if nextEligibleDate is more than 7 days ago)
    if (patient.nextEligibleDate != null) {
      final parts = patient.nextEligibleDate!.split('-');
      if (parts.length == 3) {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final diff = DateTime.now().difference(d).inDays;
        if (diff > 7) {
          alerts.add(
            ProgramAlert(
              message: tr('alert_non_compliance', {
                'name': patientName,
                'days': '$diff',
              }),
              icon: LucideIcons.userX,
              color: AppColors.warning,
              time: tr('today'),
              kind: ProgramAlertKind.nonCompliance,
              metadata: {
                'patientName': patientName,
                'daysOverdue': diff,
                'lastDispensingDate': patient.lastDispensingDate,
              },
            ),
          );
        }
      }
    }
  }

  for (final log in dp.logs.where((l) => l.status == 'Flagged').take(5)) {
    alerts.add(
      ProgramAlert(
        message: tr('fraud_log_entry', {
          'patient': log.getLocalizedPatientName(context),
          'id': log.patientId,
          'action': log.getLocalizedAction(context),
          'center': log.getLocalizedCenterName(context),
        }),
        icon: LucideIcons.shieldAlert,
        color: AppColors.error,
        time: tr('today'),
        kind: ProgramAlertKind.flagged,
      ),
    );
  }

  if (alerts.isEmpty) {
    alerts.add(
      ProgramAlert(
        message: tr('inventory_stable'),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        time: tr('now'),
        kind: ProgramAlertKind.allClear,
      ),
    );
  }

  return alerts;
}

int programAlertBadgeCount(BuildContext context, DataProvider dp) {
  return collectProgramAlerts(
    context,
    dp,
  ).where((a) => a.kind != ProgramAlertKind.allClear).length;
}

/// Pending physician authorization reviews (Authorization Reviews tab badge).
int pendingAuthorizationReviewCount(DataProvider dp) =>
    dp.pendingClinicalReviews.length;

List<ProgramAlert> fraudProgramAlerts(BuildContext context, DataProvider dp) {
  return collectProgramAlerts(context, dp)
      .where(
        (a) =>
            a.kind == ProgramAlertKind.override ||
            a.kind == ProgramAlertKind.flagged,
      )
      .toList();
}
