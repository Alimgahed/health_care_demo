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
}

class ProgramAlert {
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  final ProgramAlertKind kind;

  const ProgramAlert({
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    required this.kind,
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

  for (final log in dp.logs.where((l) => l.status == 'Flagged').take(8)) {
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
