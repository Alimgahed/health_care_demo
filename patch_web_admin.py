import re

with open('lib/features/dashboard/web/web_admin_shell.dart', 'r') as f:
    lines = f.readlines()

# find // ─── COLORS ───
start_idx = -1
for i, line in enumerate(lines):
    if '// ─── COLORS ───' in line:
        start_idx = i
        break

if start_idx != -1:
    # Now we need to find where _AlertOSDashboardState ends.
    # It ends before `class DashboardHeader` or some other class.
    end_idx = -1
    for i in range(start_idx, len(lines)):
        if line.startswith('class '):
            # If we find another class after _AlertOSDashboardState
            if '_AlertOSDashboardState' not in lines[i-1] and '_AlertOSDashboardState' not in line:
                # Is it a new class after the dashboard state?
                pass
    
    # Actually, it's safer to just look for the `class AlertOSApp extends StatefulWidget`
    # and find the end of `_AlertOSDashboardState`.
    # Let's read the whole file as string, use regex to remove everything from `// ─── COLORS ───` to the end of `class _AlertOSDashboardState { ... }`
    
    content = "".join(lines)
    # Match from // ─── COLORS ─── up to the end of _AlertOSDashboardState
    # The end of _AlertOSDashboardState would be the closing brace.
    # Let's find the string "class _AlertOSDashboardState extends State<AlertOSDashboard> {"
    match = re.search(r'class _AlertOSDashboardState extends State<AlertOSDashboard> \{.*?\n\}\n', content, flags=re.DOTALL)
    
    if match:
        end_pos = match.end()
        # Find where // ─── COLORS ─── starts
        start_pos = content.find('// ─── COLORS ───')
        
        new_content = content[:start_pos] + "\n" + content[end_pos:]
        
        # also add the import for alert_os_dashboard.dart
        import_stmt = "import '../admin_views/alert_os_dashboard.dart';\n"
        if import_stmt not in new_content:
            # find first import
            first_import = new_content.find("import ")
            new_content = new_content[:first_import] + import_stmt + new_content[first_import:]
        
        # Replace `return AlertOSApp();` with `return const AlertOSDashboard();`
        new_content = new_content.replace('return AlertOSApp();', 'return const AlertOSDashboard();')
        
        with open('lib/features/dashboard/web/web_admin_shell.dart', 'w') as f:
            f.write(new_content)
        print("Successfully removed old AlertOS code and updated imports/usage.")
    else:
        print("Could not find the end of _AlertOSDashboardState")
else:
    print("Could not find // ─── COLORS ───")
