/// Central bilingual terminology reference for the MoH Mounjaro program.
/// Keys match [AppLocalizations] dictionary entries.
class HealthcareTerminology {
  HealthcareTerminology._();

  static const Map<String, Map<String, String>> glossary = {
    'mounjaro': {'en': 'Mounjaro', 'ar': 'مونجارو'},
    'bmi': {'en': 'Body Mass Index (BMI)', 'ar': 'مؤشر كتلة الجسم'},
    'registered_patients': {
      'en': 'Registered Beneficiaries',
      'ar': 'المستفيدون المسجلون',
    },
    'eligibility': {'en': 'Program Eligibility', 'ar': 'أهلية الاستحقاق'},
    'gov_coverage': {
      'en': 'Government Coverage',
      'ar': 'التغطية الحكومية',
    },
    'gov_contribution': {
      'en': 'Government Contribution',
      'ar': 'مساهمة الحكومة',
    },
    'patient_contribution': {
      'en': 'Beneficiary Co-payment',
      'ar': 'مساهمة المستفيد',
    },
    'subsidy': {
      'en': 'Government Subsidy',
      'ar': 'الدعم الحكومي',
    },
    'dispensing': {'en': 'Medication Dispensing', 'ar': 'صرف العلاج'},
    'dispensing_history': {
      'en': 'Dispensing Record',
      'ar': 'سجل صرف العلاج',
    },
    'duplicate_dispensing': {
      'en': 'Duplicate Dispensing Attempt',
      'ar': 'محاولة صرف مكرر',
    },
    'fraud_alert': {
      'en': 'Suspected Misuse Alert',
      'ar': 'تنبيه اشتباه إساءة استخدام',
    },
    'weight_journey': {
      'en': 'Weight Management Journey',
      'ar': 'مسار إنقاص الوزن',
    },
    'injection_schedule': {
      'en': 'Injection Schedule',
      'ar': 'جدول الحقن',
    },
    'approval_workflow': {
      'en': 'Physician Authorization Workflow',
      'ar': 'مسار اعتماد الطبيب المعالج',
    },
  };
}
