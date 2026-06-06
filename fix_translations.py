import re

def update_file(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # insert before the last closing brace
    last_brace_idx = content.rfind('};')
    if last_brace_idx != -1:
        insert_text = ""
        for key, val in new_keys.items():
            if f"'{key}'" not in content:
                insert_text += f"  '{key}': '{val}',\n"
        
        if insert_text:
            content = content[:last_brace_idx] + insert_text + content[last_brace_idx:]
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

en_keys = {
    'live_activity_feed': 'Live Activity Feed',
    'live_badge': 'Live'
}

ar_keys = {
    'live_activity_feed': 'سجل الأنشطة المباشر',
    'live_badge': 'مباشر'
}

update_file('lib/core/localization/translations_en.dart', en_keys)
update_file('lib/core/localization/translations_ar.dart', ar_keys)
