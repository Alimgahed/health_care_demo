import re
import os

files = [
    'lib/features/dashboard/web/web_admin_shell.dart',
    'lib/features/dashboard/web/web_center_shell.dart',
    'lib/features/dashboard/web/web_doctor_shell.dart',
    'lib/features/dashboard/web/web_patient_shell.dart',
    'lib/features/dashboard/mobile/mobile_admin_shell.dart',
    'lib/features/dashboard/patient_shell.dart'
]

for filepath in files:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace AppColors.surface.withOpacity(...) or withValues(...) with Colors.white.withOpacity(...)
        content = re.sub(r'AppColors\.surface\.(withOpacity|withValues)', r'Colors.white.\1', content)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
