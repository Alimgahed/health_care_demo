import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Safely replace backgroundColor: Colors.white
    content = re.sub(r'backgroundColor:\s*Colors\.white\b', 'backgroundColor: AppColors.background', content)

    # Re-split to process lines for Colors.white inside BoxDecoration, etc.
    lines = content.split('\n')
    for i, line in enumerate(lines):
        # Skip if it involves TextStyle or Icon
        if 'TextStyle' in line or 'Icon' in line or 'Text(' in line:
            continue
            
        if 'color: Colors.white' in line:
            lines[i] = line.replace('color: Colors.white', 'color: AppColors.surface')
            
        if 'Colors.white.withOpacity' in line:
            lines[i] = line.replace('Colors.white.withOpacity', 'AppColors.surface.withOpacity')
            
        if 'Colors.white.withValues' in line:
            lines[i] = line.replace('Colors.white.withValues', 'AppColors.surface.withValues')

    content = '\n'.join(lines)
    
    if content != original_content:
        # Add import if missing
        if 'AppColors' not in content:
            import_idx = content.find('import ')
            if import_idx != -1:
                content = content[:import_idx] + "import 'package:mounjaro_demo/core/theme/app_colors.dart';\n" + content[import_idx:]
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

def main():
    lib_dir = 'lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
