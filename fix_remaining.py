files = {
    'lib/features/dashboard/splash_screen.dart': [74],
    'lib/features/dashboard/web/web_admin_shell.dart': [4159],
    'lib/features/dashboard/web/web_patient_shell.dart': [1241, 1286, 1514, 2231, 2425],
    'lib/features/dispensing/payment_screen.dart': [276],
    'lib/features/treatment_plan/mobile/plan_medication_screen.dart': [1316],
    'lib/features/treatment_plan/web/web_plan_medication_view.dart': [358]
}

for file, lines in files.items():
    with open(file, 'r') as f:
        content = f.readlines()
    for l in lines:
        for i in range(l-1, max(-1, l-5), -1):
            if 'const ' in content[i]:
                content[i] = content[i].replace('const ', '')
                break
    with open(file, 'w') as f:
        f.writelines(content)
