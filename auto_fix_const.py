import re
import sys

def main():
    # Read the analyze output from a file or stdin
    with open('analyze_output.txt', 'r') as f:
        lines = f.readlines()
        
    for line in lines:
        if 'invalid_constant' in line or 'non_constant_default_value' in line:
            # error - lib/path:line:col - Message
            match = re.search(r'error - (.*?):(\d+):(\d+) -', line)
            if match:
                filepath = match.group(1).strip()
                lineno = int(match.group(2))
                
                try:
                    with open(filepath, 'r') as f:
                        file_lines = f.readlines()
                        
                    # Target line (0-indexed)
                    idx = lineno - 1
                    
                    # We look backwards up to 5 lines for 'const ' and remove it
                    found = False
                    for i in range(idx, max(-1, idx - 5), -1):
                        if 'const ' in file_lines[i]:
                            file_lines[i] = file_lines[i].replace('const ', '')
                            found = True
                            break
                            
                    if found:
                        with open(filepath, 'w') as f:
                            f.writelines(file_lines)
                except Exception as e:
                    pass

if __name__ == '__main__':
    main()
