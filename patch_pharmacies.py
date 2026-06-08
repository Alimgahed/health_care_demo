import os
import re

file_path = '/Users/alimegahed/health_system/mounjaro_demo/lib/core/localization/translations_ar.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace forms of pharmacies
content = content.replace('الصيدليات', 'منافذ التوزيع')
content = content.replace('صيدليات', 'منافذ توزيع')
content = content.replace('الصيدلية', 'منفذ التوزيع')
content = content.replace('صيدلية', 'منفذ توزيع')
# Also replace pharmacist with dispensing officer or similar if it fits, but let's stick to the exact request:
content = content.replace('صيدلي', 'مسؤول صرف')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Replaced pharmacy terms with distribution outlet terms.")
