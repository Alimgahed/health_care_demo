import re

with open('lib/features/dashboard/program_alerts.dart', 'r') as f:
    content = f.read()

# Add an ID counter so every alert has an ID
content = content.replace("final alerts = <ProgramAlert>[];", "final alerts = <ProgramAlert>[];\n  int _idCounter = 1;")

# Add auto-generated IDs and actions to all ProgramAlert creations
content = re.sub(r'ProgramAlert\(', r'ProgramAlert(\n        id: _idCounter++,', content)

# specific severities and actions:
# Fraud
content = content.replace("kind: ProgramAlertKind.fraudAttempt,", "kind: ProgramAlertKind.fraudAttempt,\n          severity: 3,\n          action: tr('freeze_account'),\n          actionIcon: Icons.lock_outline,")
content = content.replace("kind: ProgramAlertKind.override,", "kind: ProgramAlertKind.override,\n        severity: 2,\n        action: tr('review_plan'),\n        actionIcon: Icons.find_in_page_outlined,")
content = content.replace("kind: ProgramAlertKind.flagged,", "kind: ProgramAlertKind.flagged,\n        severity: 2,\n        action: tr('review_plan'),\n        actionIcon: Icons.find_in_page_outlined,")

# Supply
content = content.replace("kind: ProgramAlertKind.inventory,", "kind: ProgramAlertKind.inventory,\n          severity: 1,\n          action: tr('send_emergency_supply'),\n          actionIcon: Icons.local_shipping_outlined,")
content = content.replace("kind: ProgramAlertKind.criticalShortage,", "kind: ProgramAlertKind.criticalShortage,\n            severity: 3,\n            action: tr('send_emergency_supply'),\n            actionIcon: Icons.local_shipping_outlined,")

# Clinical
content = content.replace("kind: ProgramAlertKind.clinicalIneffective,", "kind: ProgramAlertKind.clinicalIneffective,\n          severity: 2,\n          action: tr('review_plan'),\n          actionIcon: Icons.find_in_page_outlined,")
content = content.replace("kind: ProgramAlertKind.nonCompliance,", "kind: ProgramAlertKind.nonCompliance,\n              severity: 1,\n              action: tr('contact_patient'),\n              actionIcon: Icons.phone_outlined,")
content = content.replace("kind: ProgramAlertKind.clinicalPending,", "kind: ProgramAlertKind.clinicalPending,\n        severity: 1,\n        action: tr('review_plan'),\n        actionIcon: Icons.check,")

# Other
content = content.replace("kind: ProgramAlertKind.readyDispense,", "kind: ProgramAlertKind.readyDispense,\n        severity: 1,\n        action: 'صرف',\n        actionIcon: Icons.check,")
content = content.replace("kind: ProgramAlertKind.allClear,", "kind: ProgramAlertKind.allClear,\n        severity: 0,\n        action: '',\n        actionIcon: Icons.check,")

with open('lib/features/dashboard/program_alerts.dart', 'w') as f:
    f.write(content)

print("Added IDs and Actions to program alerts")
