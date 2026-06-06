def add_keys(filepath, keys):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    last_brace = content.rfind('};')
    if last_brace != -1:
        insert = ""
        for k, v in keys.items():
            if f"'{k}'" not in content:
                insert += f"  '{k}': '{v}',\n"
        
        content = content[:last_brace] + insert + content[last_brace:]
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

en_keys = {
    'live_activity_feed': 'Live Activity Feed',
    'live_badge': 'Live'
}

ar_keys = {
    'live_activity_feed': 'سجل الأنشطة المباشر',
    'live_badge': 'مباشر'
}

add_keys('lib/core/localization/translations_en.dart', en_keys)
add_keys('lib/core/localization/translations_ar.dart', ar_keys)
