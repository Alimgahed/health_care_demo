import os

replacements = {
    'lib/features/dashboard/web/web_admin_shell.dart': [
        ("'الخطة العلاجية الحالية'", "context.tr('current_treatment_plan')"),
        ("'تاريخ آخر صرف:'", "context.tr('last_dispense_date') + ':'"),
        ("'تاريخ الاستحقاق القادم:'", "context.tr('next_eligible_date') + ':'"),
        ("'معدل الالتزام:'", "context.tr('compliance_rate') + ':'"),
        ("'المقاييس الحيوية'", "context.tr('vital_metrics')"),
        ("'الوزن'", "context.tr('weight')"),
        ("'الطول'", "context.tr('height')"),
        ("'مؤشر الكتلة'", "context.tr('bmi')"),
        ("'تاريخ الجرعات'", "context.tr('dosing_history')"),
        ("'البيانات الشخصية'", "context.tr('personal_data')"),
        ("'الجنسية:'", "context.tr('nationality') + ':'"),
        ("'الإقامة:'", "context.tr('residency_status') + ':'"),
        ("'الإمارة:'", "context.tr('emirate') + ':'"),
        ("'الحالة الصحية المسبقة'", "context.tr('pre_existing_conditions')"),
        ("'لا يوجد أمراض مزمنة'", "context.tr('no_chronic_diseases')"),
        ("'تفاصيل التنبيه (Alert Details)'", "context.tr('alert_details')"),
        ("'البيانات المرتبطة:'", "context.tr('associated_data') + ':'"),
        ("'إغلاق'", "context.tr('close')"),
        ("Text('تم تنفيذ الإجراء بنجاح')", "Text(context.tr('action_executed_successfully'))"),
        ("const Text('تنفيذ الإجراء')", "Text(context.tr('execute_action'))"),
        ("t.translate('system_audit_log') ?? 'سجل النظام'", "t.translate('system_audit_log')"),
        ("'غرفة عمليات التنبيهات الذكية (AI Command Center)'", "context.tr('ai_command_center')"),
        ("'نظام مراقبة ذكي يعتمد على الذكاء الاصطناعي لاكتشاف التجاوزات، التنبؤ بنقص المخزون، وتحليل استجابة المرضى.'", "context.tr('ai_command_center_desc')"),
        ("'أمن واحتيال'", "context.tr('security_fraud')"),
        ("'متابعة سريرية'", "context.tr('clinical_followup')"),
        ("'أزمات الإمداد'", "context.tr('supply_crises')"),
        ("'تجميد الحساب'", "context.tr('freeze_account')"),
        ("'مراجعة الخطة'", "context.tr('review_plan')"),
        ("'إرسال إمداد طارئ'", "context.tr('send_emergency_supply')"),
        ("'التواصل مع المريض'", "context.tr('contact_patient')"),
    ],
    'lib/features/dashboard/web/web_patient_shell.dart': [
        ("'🌅 صباح الخير،'", "'🌅 ' + context.tr('good_morning_comma')"),
        ("'☀️ مساء الخير،'", "'☀️ ' + context.tr('good_afternoon_comma')"),
        ("'🌙 مساء الخير،'", "'🌙 ' + context.tr('good_evening_comma')"),
        ("'بعد 4 أيام'", "context.tr('in_4_days')"),
        ("context.tr('region') ?? 'الإمارة / النطاق الجغرافي'", "context.tr('region')"),
        ("'وزن زائد خفيف - مستقر'", "context.tr('slight_overweight_stable')"),
    ],
    'lib/features/dispensing/payment_screen.dart': [
        ("'مونجارو - جرعة ${patient!.currentDose}'", "context.tr('mounjaro_terzepatide') + ' - ' + context.tr('dose') + ' ${patient!.currentDose}'"),
    ]
}

translations_en_additions = {
    'good_morning_comma': 'Good morning,',
    'good_afternoon_comma': 'Good afternoon,',
    'good_evening_comma': 'Good evening,',
    'in_4_days': 'In 4 days',
    'slight_overweight_stable': 'Slightly overweight - Stable',
}

translations_ar_additions = {
    'good_morning_comma': 'صباح الخير،',
    'good_afternoon_comma': 'مساء الخير،',
    'good_evening_comma': 'مساء الخير،',
    'in_4_days': 'بعد 4 أيام',
    'slight_overweight_stable': 'وزن زائد خفيف - مستقر',
}

for file, items in replacements.items():
    if not os.path.exists(file):
        continue
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    for o, n in items:
        content = content.replace(o, n)
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

def append_to_translations(filepath, additions):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    idx = content.rfind('};')
    if idx != -1:
        addition_str = ''
        for k, v in additions.items():
            v_escaped = v.replace("'", "\\'")
            addition_str += f"  '{k}': '{v_escaped}',\n"
        
        new_content = content[:idx] + addition_str + content[idx:]
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

append_to_translations('lib/core/localization/translations_ar.dart', translations_ar_additions)
append_to_translations('lib/core/localization/translations_en.dart', translations_en_additions)

print('Done fixing remaining hardcoded strings.')
