import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # We want to replace `color: AppColors.navy` with `color: AppColors.textPrimary`
    # if it's inside `TextStyle` or `Icon` or `Text`.
    # A safe regex approach: find `TextStyle( ... )` and replace inside it.
    # But since nested parens are hard, we can just find `color:\s*AppColors\.navy`
    # and replace it. Is it safe to just do it everywhere?
    # Let's see if we can do `color: AppColors.navy` -> `color: AppColors.textPrimary` everywhere EXCEPT inside `BoxDecoration` or `Container`?
    # To be very safe, let's just replace `AppColors.navy` with `AppColors.textPrimary` globally,
    # except when preceded by `backgroundColor:` or inside `BoxDecoration(`.
    # Actually, if the line ends with `,` and only has `color: AppColors.navy`, it's almost always text or icon if it's not a container.
    
    # Let's just use `color: AppColors.navy` -> `color: AppColors.textPrimary` everywhere
    # and manually fix any containers if they look wrong. Wait, no.
    
    # Let's do a regex that matches `color:\s*AppColors\.navy` inside `TextStyle` specifically.
    # We can match `TextStyle([^)]*color:\s*)AppColors\.navy` and replace.
    content = re.sub(r'(TextStyle\s*\([^)]*color:\s*)AppColors\.navy', r'\1AppColors.textPrimary', content, flags=re.DOTALL)
    
    # For Icon
    content = re.sub(r'(Icon\s*\([^)]*color:\s*)AppColors\.navy', r'\1AppColors.textPrimary', content, flags=re.DOTALL)

    if content != original_content:
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
