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
        
        # We know that in the sidebar, AppColors.surface was used for text because in light mode surface is white.
        # But in dark mode it is dark. We should just use Colors.white
        
        # Replace TextStyle(..., color: AppColors.surface, ...)
        content = re.sub(r'(TextStyle\s*\([^)]*color:\s*)AppColors\.surface\b', r'\1Colors.white', content, flags=re.DOTALL)
        
        # Replace Icon(..., color: AppColors.surface, ...)
        content = re.sub(r'(Icon\s*\([^)]*color:\s*)AppColors\.surface\b', r'\1Colors.white', content, flags=re.DOTALL)
        
        # Replace BorderSide(color: AppColors.surface.withOpacity...
        content = re.sub(r'(BorderSide\s*\([^)]*color:\s*)AppColors\.surface\b', r'\1Colors.white', content, flags=re.DOTALL)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
