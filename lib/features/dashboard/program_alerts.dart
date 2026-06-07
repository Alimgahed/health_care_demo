import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/mock_data.dart';
import '../../core/models/activity_log.dart';
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

enum AlertCategory { fraud, clinical, supply, info }

class ProgramAlert {
  final int id;
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  final ProgramAlertKind kind;
  final Map<String, dynamic> metadata;
  final int severity;
  final String action;
  final IconData actionIcon;

  const ProgramAlert({
    this.id = 0,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    required this.kind,
    this.metadata = const {},
    this.severity = 1,
    this.action = 'Review',
    this.actionIcon = Icons.remove_red_eye,
  });

  AlertCategory get category {
    switch (kind) {
      case ProgramAlertKind.fraudAttempt:
      case ProgramAlertKind.override:
      case ProgramAlertKind.flagged:
        return AlertCategory.fraud;
      case ProgramAlertKind.clinicalPending:
      case ProgramAlertKind.clinicalIneffective:
      case ProgramAlertKind.nonCompliance:
        return AlertCategory.clinical;
      case ProgramAlertKind.inventory:
      case ProgramAlertKind.criticalShortage:
      case ProgramAlertKind.readyDispense:
        return AlertCategory.supply;
      case ProgramAlertKind.allClear:
        return AlertCategory.info;
    }
  }

  String localizedKindLabel(BuildContext context) {
    switch (category) {
      case AlertCategory.fraud:
        return context.tr('alert_category_fraud');
      case AlertCategory.clinical:
        return context.tr('alert_category_medical');
      case AlertCategory.supply:
        return context.tr('alert_category_supply');
      case AlertCategory.info:
        return context.tr('alert_category_info');
    }
  }

  IconData get kindIcon {
    switch (category) {
      case AlertCategory.fraud: return Icons.shield_outlined;
      case AlertCategory.clinical: return Icons.monitor_heart_outlined;
      case AlertCategory.supply: return Icons.inventory_2_outlined;
      case AlertCategory.info: return Icons.info_outline;
    }
  }
}

/// National safety / supply alerts (shared by dashboard panel, full view, nav badge).
List<ProgramAlert> collectProgramAlerts(BuildContext context, DataProvider dp) {
  final tr = context.tr;
  final alerts = <ProgramAlert>[];
  int idCounter = 1;

  final readyCount = dp.countPatientsReadyToDispense();
  if (readyCount > 0) {
    alerts.add(
      ProgramAlert(
        id: idCounter++,
        message: tr('alert_ready_dispense', {'count': '$readyCount'}),
        icon: LucideIcons.pill,
        color: AppColors.success,
        time: tr('now'),
        kind: ProgramAlertKind.readyDispense,
        severity: 1,
        action: tr('action_dispense'),
        actionIcon: Icons.check,
      ),
    );
  }

  final pendingReviews = dp.pendingClinicalReviews.length;
  if (pendingReviews > 0) {
    alerts.add(
      ProgramAlert(
        id: idCounter++,
        message: tr('alert_pending_reviews', {'count': '$pendingReviews'}),
        icon: LucideIcons.stethoscope,
        color: AppColors.warning,
        time: tr('now'),
        kind: ProgramAlertKind.clinicalPending,
        severity: 1,
        action: tr('review_plan'),
        actionIcon: Icons.check,
      ),
    );
  }

  for (final center in dp.centers) {
    void low(String dose, int units) {
      if (units > 10) return;
      alerts.add(
        ProgramAlert(
        id: idCounter++,
          message: tr('inventory_low_msg', {
            'center': center.getLocalizedName(context),
            'dose': dose,
            'units': '$units',
          }),
          icon: Icons.warning_amber_rounded,
          color: units <= 5 ? AppColors.error : AppColors.warning,
          time: tr('now'),
          kind: ProgramAlertKind.inventory,
          severity: 1,
          action: tr('send_emergency_supply'),
          actionIcon: Icons.local_shipping_outlined,
        ),
      );
    }

    low('2.5 mg', center.inventory2_5mg);
    low('5 mg', center.inventory5mg);
    low('7.5 mg', center.inventory7_5mg);
    low('10 mg', center.inventory10mg);
  }

  for (final log in dp.misusePreventionLogs) {
    final isOverride = log.status == 'Overridden';
    alerts.add(
      ProgramAlert(
        id: idCounter++,
        message: tr('fraud_log_entry', {
          'patient': log.getLocalizedPatientName(context),
          'id': log.patientId,
          'action': log.getLocalizedAction(context),
          'center': log.getLocalizedCenterName(context),
        }),
        icon: isOverride ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
        color: isOverride ? AppColors.warning : AppColors.error,
        time: log.formatTimestamp(context),
        kind: isOverride ? ProgramAlertKind.override : ProgramAlertKind.flagged,
        severity: isOverride ? 2 : 3,
        action: isOverride ? tr('review_plan') : tr('freeze_account'),
        actionIcon: isOverride ? Icons.find_in_page_outlined : Icons.lock_outline,
        metadata: {
          'logId': log.id,
          'patientId': log.patientId,
          'center': log.getLocalizedCenterName(context),
        },
      ),
    );
  }

  // --- AI-driven supply / clinical alerts ---
  
  // 1. Supply Crisis (Critical Shortage)
  for (final center in dp.centers) {
    void checkShortage(String dose, int units) {
      if (units == 0) {
        alerts.insert(0,
          ProgramAlert(
        id: idCounter++,
            message: tr('alert_critical_shortage', {
              'center': center.getLocalizedName(context),
              'dose': dose,
              'count': '0',
            }),
            icon: LucideIcons.alertTriangle,
            color: AppColors.error,
            time: tr('now'),
            kind: ProgramAlertKind.criticalShortage,
            severity: 3,
            action: tr('send_emergency_supply'),
            actionIcon: Icons.local_shipping_outlined,
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

  // Clinical / compliance (derived from patient records)
  for (final patient in dp.patients) {
    final patientName = Localizations.localeOf(context).languageCode == 'ar' ? patient.fullNameAr : patient.fullName;

    if (patient.weightHistory.isNotEmpty &&
        (patient.weightHistory.first - patient.weight < 1.0) &&
        (patient.currentDose == '10 mg' || patient.currentDose == '10.0 mg' || patient.currentDose == '7.5 mg')) {
      alerts.add(
        ProgramAlert(
        id: idCounter++,
          message: tr('alert_clinical_ineffective', {'name': patientName}),
          icon: LucideIcons.activity,
          color: AppColors.accent,
          time: tr('time_days_ago', {'count': '2'}),
          kind: ProgramAlertKind.clinicalIneffective,
          severity: 2,
          action: tr('review_plan'),
          actionIcon: Icons.find_in_page_outlined,
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
        id: idCounter++,
              message: tr('alert_non_compliance', {
                'name': patientName,
                'days': '$diff',
              }),
              icon: LucideIcons.userX,
              color: AppColors.warning,
              time: tr('today'),
              kind: ProgramAlertKind.nonCompliance,
              severity: 1,
              action: tr('contact_patient'),
              actionIcon: Icons.phone_outlined,
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

  if (alerts.isEmpty) {
    alerts.add(
      ProgramAlert(
        id: idCounter++,
        message: tr('inventory_stable'),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        time: tr('now'),
        kind: ProgramAlertKind.allClear,
        severity: 0,
        action: '',
        actionIcon: Icons.check,
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
            a.kind == ProgramAlertKind.flagged ||
            a.kind == ProgramAlertKind.fraudAttempt,
      )
      .toList();
}

/// Maps a national activity log entry to an alert feed category.
AlertCategory alertCategoryForActivityLog(ActivityLog log) {
  if (log.status == 'Flagged' || log.status == 'Overridden') {
    return AlertCategory.fraud;
  }
  switch (log.eventType) {
    case ActivityEventType.clinicalReview:
    case ActivityEventType.carePlan:
      return AlertCategory.clinical;
    case ActivityEventType.inventoryReplenish:
    case ActivityEventType.dispense:
      return AlertCategory.supply;
    default:
      return AlertCategory.info;
  }
}

String activityFeedMessage(BuildContext context, ActivityLog log) {
  if (log.patientId == 'SYS' || log.patientId == 'ADM') {
    return log.getLocalizedAction(context);
  }
  return '${log.getLocalizedAction(context)} · ${log.getLocalizedPatientName(context)} (${log.patientId})';
}
