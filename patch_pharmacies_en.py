import os
import re

file_path = '/Users/alimegahed/health_system/mounjaro_demo/lib/core/localization/translations_en.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('pharmacies', 'distribution outlets')
content = content.replace('Pharmacies', 'Distribution Outlets')
content = content.replace('pharmacy', 'distribution outlet')
content = content.replace('Pharmacy', 'Distribution Outlet')
content = content.replace('pharmacist', 'dispensing officer')
content = content.replace('Pharmacist', 'Dispensing Officer')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Replaced pharmacy terms with distribution outlet terms in English.")
