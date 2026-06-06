import os

with open('lib/features/dashboard/program_alerts.dart', 'r') as f:
    content = f.read()

# We need to add AlertCategory enum and replace ProgramAlert class
replacement = """
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

  String get kindLabel {
    switch (category) {
      case AlertCategory.fraud: return 'احتيال';
      case AlertCategory.clinical: return 'سريري';
      case AlertCategory.supply: return 'إمداد';
      case AlertCategory.info: return 'معلومات';
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
"""

old_class = """
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
"""

content = content.replace(old_class.strip(), replacement.strip())
with open('lib/features/dashboard/program_alerts.dart', 'w') as f:
    f.write(content)

print("Patched program_alerts.dart")
