import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    Map<String, Map<String, String>> translations = {
      'en': {
        // --- Login & Generic ---
        'login_title': 'Mounjaro Platform',
        'login_subtitle': 'MINISTRY OF HEALTH',
        'select_role': 'Select Your Role',
        'choose_portal': 'Choose your portal access level to continue',
        'ministry_executive': 'Ministry\nExecutive',
        'doctor_physician': 'Doctor /\nPhysician',
        'dispensing_center': 'Dispensing\nCenter',
        'patient_portal': 'Patient\nPortal',
        'access_portal': 'Access Portal',
        'cancel': 'Cancel',
        'confirm': 'Confirm',
        'save': 'Save',
        'record': 'Record',
        'search': 'Search...',
        'all': 'All',
        
        // --- Navigation ---
        'nav_overview': 'Overview',
        'nav_regions': 'Regions',
        'nav_analytics': 'Analytics',
        'nav_simulator': 'Simulator',
        
        // --- Admin Dashboard ---
        'ncc_title': 'National Command Center',
        'exec_summary': 'Executive Summary',
        'total_active_patients': 'Total Active Patients',
        'govt_subsidy': 'Govt. Subsidy Disbursed',
        'national_bmi_drop': 'National Avg. BMI Drop',
        'fraud_prevented': 'Fraud Incidents Prevented',
        'obesity_index_title': 'National Obesity Index',
        'obesity_index_subtitle': 'Average BMI trend across all Emirates (12 Months)',
        'dispensing_vs_goals': 'Dispensing Volume vs Strategic Goals',
        'actual_dispensed': 'Actual Dispensed',
        'ministry_target': 'Ministry Target',
        'demographics_title': 'Demographics Distribution',
        'citizens': 'Citizens',
        'residents': 'Residents',
        'alerts': 'Alerts',
        'fraud_alert': 'Anomalous dispensing rate detected in Clinic X.',
        'budget_alert': 'Projected 12% budget deficit for Q3.',
        'supply_alert': 'Mounjaro 5mg shortage predicted in Dubai by next week.',
        'quick_actions': 'Quick Actions',
        'view_fraud_alerts': 'View Fraud Alerts',
        'approve_subsidies': 'Approve Subsidies',
        'generate_report': 'Generate Report',
        'contact_centers': 'Contact Centers',
        'greeting': 'Good Morning, Executive',
        'map_view': 'Live Geographic Mapping',
        
        // --- Map Analytics ---
        'geo_analytics': 'Geographic Analytics',
        'select_marker': 'Select a marker on the map to view details',
        'patient_details': 'Patient Details',
        'center_details': 'Dispensing Center Details',
        'inventory_status': 'Live Inventory Status',
        'out_of_stock': 'Out of Stock',
        'low_stock': 'Low Stock',
        'available': 'Available',
        'allocated': 'Allocated',
        'units': 'units',
        'rehab_center_details': 'Physical Therapy Center Details',
        'chief_therapist': 'Chief Therapist',
        'active_patients_rehab': 'Active Rehab Patients',
        'working_hours': 'Working Hours',
        'services_offered': 'Services Offered',
        'filter_all': 'All',
        'filter_patients': 'Patients',
        'filter_pharmacies': 'Pharmacies',
        'filter_rehab': 'Physical Therapy',
        'filter_emirate': 'Emirate',
        'filter_risk': 'Risk/Status',
        
        // --- Doctor Dashboard ---
        'doc_greeting': 'Welcome back, Dr. Al Mandoos',
        'doc_clinic': 'Dubai Clinic #4',
        'search_patient': 'Search patients by name or EID...',
        'register_patient': 'Register New Patient',
        'patient_profile': 'Patient Profile',
        'eid': 'Emirates ID',
        'age': 'Age',
        'bmi': 'BMI',
        'gender': 'Gender',
        'weight': 'Weight',
        'height': 'Height',
        'residency': 'Residency',
        'medical_conditions': 'Medical Conditions',
        'current_dose': 'Current Dose',
        'record_weight': 'Record Weight Check-in',
        'escalate_dose': 'Escalate Dose',
        'treatment_adherence': 'Treatment Adherence Score',
        'dose_escalation_timeline': 'Dose Escalation Timeline',
        'recent_logs': 'Recent Assessments & Modifications Log',
        'recorded_by': 'Recorded by',
        'enter_weight': 'Enter new patient weight (kg). BMI will be calculated automatically.',
        'prescribe_dose': 'Escalate Mounjaro Dose',
        'select_dose': 'Select new prescription dose:',
        'confirm_prescription': 'Confirm Prescription',
        
        // --- Center Dashboard ---
        'center_greeting': 'Welcome, Pharmacist',
        'center_name': 'Central Depot Pharmacy',
        'dispense_mounjaro': 'Dispense Mounjaro',
        'verify_eligibility': 'Verify Eligibility',
        'restock_inventory': 'Restock Inventory',
        'stock_levels': 'Current Stock Levels',
        'dispensing_history': 'Recent Dispensing History',
        
        // --- Patient Dashboard ---
        'patient_greeting': 'Patient Portal - Welcome back',
        'my_prescription': 'My Prescription',
        'next_refill': 'Next Eligible Refill',
        'health_metrics': 'Health Metrics',
        'weight_trend': 'Weight Trend',
        'bmi_trend': 'BMI Trend',
        'adherence': 'Adherence',
        'upcoming_appointments': 'Upcoming Appointments',
        
        // --- Common ---
        'status': 'Status',
        'success': 'Success',
        'flagged': 'Flagged',
        'overridden': 'Overridden',
        'male': 'Male',
        'female': 'Female',
        'emirati': 'Emirati',
        'visitor': 'Visitor',
        'resident': 'Resident',
      
        // --- New Treatment Plan Keys ---
        'treatment_plan': 'Treatment Plan',
        'create_treatment_plan': 'Create Treatment Plan',
        'medication_plan': 'Medication Plan',
        'therapy_plan': 'Physical Therapy Plan',
        'home_exercises': 'Home Exercises',
        'select_dose': 'Select Dose',
        'injection_frequency': 'Injection Frequency',
        'reminder_times': 'Reminder Times',
        'save_plan': 'Save Plan',
        'session_checkin': 'Session Check-in',
        'mark_attendance': 'Mark Attendance',
        'post_session_log': 'Post-Session Log',
        'weight_after_session': 'Weight After Session',
        'height_after_session': 'Height After Session',
        'my_plan': 'My Plan',
        'progress': 'Progress',
        'compliance_score': 'Compliance Score',
        'weekly_report': 'Weekly Report',
        'target_weight': 'Target Weight',
        'current_weight': 'Current Weight',
        'therapy_center': 'Therapy Center',
        'assign_center': 'Assign Center',
        'sessions': 'Sessions',
        'completed': 'Completed',
        'upcoming': 'Upcoming',
        'exercises': 'Exercises',
        'duration': 'Duration',
        'sets': 'Sets',
        'reps': 'Reps',
        'mark_complete': 'Mark Complete',
        'medication_reminder': 'Medication Reminder',
        'i_took_my_medication': 'I Took My Medication',
        'next_injection_due': 'Next Injection Due',
        'patient_360_view': 'Patient 360 View',
        'overview': 'Overview',
        'medical_history': 'Medical History',
        'activity_log': 'Activity Log',
        'edit_plan': 'Edit Plan',
        'nearest_centers': 'Nearest Centers',
        'distance': 'Distance',
        'available_slots': 'Available Slots',
        'category': 'Category',
        'cardio': 'Cardio',
        'strength': 'Strength',
        'flexibility': 'Flexibility',
      },
      'ar': {
        // --- Login & Generic ---
        'login_title': 'منصة مونجارو',
        'login_subtitle': 'وزارة الصحة',
        'select_role': 'اختر صلاحيتك',
        'choose_portal': 'اختر مستوى الوصول للبوابة للمتابعة',
        'ministry_executive': 'المسؤول\nالتنفيذي',
        'doctor_physician': 'الطبيب\nالمختص',
        'dispensing_center': 'مركز\nالصرف',
        'patient_portal': 'بوابة\nالمرضى',
        'access_portal': 'تسجيل الدخول',
        'cancel': 'إلغاء',
        'confirm': 'تأكيد',
        'save': 'حفظ',
        'record': 'تسجيل',
        'search': 'بحث...',
        'all': 'الكل',
        
        // --- Navigation ---
        'nav_overview': 'المركز الوطني',
        'nav_regions': 'التحليل الجغرافي',
        'nav_analytics': 'التحليل المالي',
        'nav_simulator': 'المحاكي',
        
        // --- Admin Dashboard ---
        'ncc_title': 'غرفة العمليات الوطنية',
        'exec_summary': 'الملخص التنفيذي',
        'total_active_patients': 'إجمالي المرضى المستفيدين',
        'govt_subsidy': 'إجمالي الدعم الحكومي المصروف',
        'national_bmi_drop': 'متوسط انخفاض الوزن الوطني',
        'fraud_prevented': 'حالات التلاعب المكتشفة',
        'obesity_index_title': 'المؤشر الوطني للسمنة',
        'obesity_index_subtitle': 'متوسط انخفاض الوزن في كافة الإمارات (12 شهراً)',
        'dispensing_vs_goals': 'حجم الصرف مقابل الأهداف الاستراتيجية',
        'actual_dispensed': 'حجم الصرف الفعلي',
        'ministry_target': 'مستهدفات الوزارة',
        'demographics_title': 'التوزيع الديموغرافي',
        'citizens': 'المواطنين',
        'residents': 'المقيمين',
        'alerts': 'تنبيهات',
        'fraud_alert': 'تم رصد معدل صرف غير طبيعي في العيادة X.',
        'budget_alert': 'توقع عجز بنسبة 12% في ميزانية الربع الثالث.',
        'supply_alert': 'توقع نقص في مخزون مونجارو 5mg في دبي الأسبوع القادم.',
        'quick_actions': 'إجراءات سريعة',
        'view_fraud_alerts': 'استعراض التلاعب',
        'approve_subsidies': 'اعتماد الدعم',
        'generate_report': 'إصدار تقرير',
        'contact_centers': 'مراسلة المراكز',
        'greeting': 'صباح الخير، معالي الوزير',
        'map_view': 'الخريطة الجغرافية المباشرة',
        
        // --- Map Analytics ---
        'geo_analytics': 'التحليلات الجغرافية',
        'select_marker': 'اختر نقطة على الخريطة لعرض التفاصيل',
        'patient_details': 'بيانات المريض',
        'center_details': 'بيانات مركز الصرف',
        'inventory_status': 'المخزون المباشر',
        'out_of_stock': 'نفد من المخزون',
        'low_stock': 'مخزون منخفض',
        'available': 'متاح',
        'allocated': 'مخصص',
        'units': 'وحدة',
        'rehab_center_details': 'تفاصيل مركز العلاج الطبيعي',
        'chief_therapist': 'كبير المعالجين',
        'active_patients_rehab': 'المرضى النشطين بالعلاج',
        'working_hours': 'ساعات العمل',
        'services_offered': 'الخدمات المقدمة',
        'filter_all': 'الكل',
        'filter_patients': 'المرضى',
        'filter_pharmacies': 'مراكز الصرف',
        'filter_rehab': 'العلاج الطبيعي',
        'filter_emirate': 'الإمارة',
        'filter_risk': 'الحالة/الخطورة',
        
        // --- Doctor Dashboard ---
        'doc_greeting': 'مرحباً بعودتك، د. المندوس',
        'doc_clinic': 'عيادة دبي رقم 4',
        'search_patient': 'ابحث عن المرضى بالاسم أو الهوية...',
        'register_patient': 'تسجيل مريض جديد',
        'patient_profile': 'الملف الطبي للمريض',
        'eid': 'رقم الهوية',
        'age': 'العمر',
        'bmi': 'مؤشر كتلة الجسم',
        'gender': 'الجنس',
        'weight': 'الوزن',
        'height': 'الطول',
        'residency': 'الإقامة',
        'medical_conditions': 'الحالات الطبية',
        'current_dose': 'الجرعة الحالية',
        'record_weight': 'تسجيل الوزن الجديد',
        'escalate_dose': 'زيادة الجرعة',
        'treatment_adherence': 'درجة الالتزام بالعلاج',
        'dose_escalation_timeline': 'الجدول الزمني لزيادة الجرعات',
        'recent_logs': 'سجل التقييمات والتعديلات الحديثة',
        'recorded_by': 'تم التسجيل بواسطة',
        'enter_weight': 'أدخل وزن المريض الجديد (كجم). سيتم حساب مؤشر كتلة الجسم تلقائياً.',
        'prescribe_dose': 'زيادة جرعة مونجارو',
        'select_dose': 'اختر جرعة الوصفة الطبية الجديدة:',
        'confirm_prescription': 'تأكيد الوصفة الطبية',
        
        // --- Center Dashboard ---
        'center_greeting': 'مرحباً بك، الصيدلي',
        'center_name': 'صيدلية المستودع المركزي',
        'dispense_mounjaro': 'صرف مونجارو',
        'verify_eligibility': 'التحقق من الأهلية',
        'restock_inventory': 'تحديث المخزون',
        'stock_levels': 'مستويات المخزون الحالية',
        'dispensing_history': 'سجل الصرف الحديث',
        
        // --- Patient Dashboard ---
        'patient_greeting': 'بوابة المريض - مرحباً بعودتك',
        'my_prescription': 'وصفتي الطبية',
        'next_refill': 'موعد الصرف القادم',
        'health_metrics': 'المؤشرات الصحية',
        'weight_trend': 'تطور الوزن',
        'bmi_trend': 'تطور مؤشر كتلة الجسم',
        'adherence': 'الالتزام بالعلاج',
        'upcoming_appointments': 'المواعيد القادمة',
        
        // --- Common ---
        'status': 'الحالة',
        'success': 'ناجح',
        'flagged': 'مُعلّم',
        'overridden': 'تجاوز',
        'male': 'ذكر',
        'female': 'أنثى',
        'emirati': 'مواطن',
        'visitor': 'زائر',
        'resident': 'مقيم',
      
        // --- New Treatment Plan Keys ---
        'treatment_plan': 'خطة العلاج',
        'create_treatment_plan': 'إنشاء خطة علاج',
        'medication_plan': 'خطة الدواء',
        'therapy_plan': 'خطة العلاج الطبيعي',
        'home_exercises': 'التمارين المنزلية',
        'select_dose': 'اختر الجرعة',
        'injection_frequency': 'تكرار الحقن',
        'reminder_times': 'أوقات التذكير',
        'save_plan': 'حفظ الخطة',
        'session_checkin': 'تسجيل حضور الجلسة',
        'mark_attendance': 'تسجيل الحضور',
        'post_session_log': 'سجل ما بعد الجلسة',
        'weight_after_session': 'الوزن بعد الجلسة',
        'height_after_session': 'الطول بعد الجلسة',
        'my_plan': 'خطتي',
        'progress': 'التقدم',
        'compliance_score': 'نسبة الالتزام',
        'weekly_report': 'التقرير الأسبوعي',
        'target_weight': 'الوزن المستهدف',
        'current_weight': 'الوزن الحالي',
        'therapy_center': 'مركز العلاج الطبيعي',
        'assign_center': 'تعيين مركز',
        'sessions': 'الجلسات',
        'completed': 'مكتملة',
        'upcoming': 'قادمة',
        'exercises': 'التمارين',
        'duration': 'المدة',
        'sets': 'المجموعات',
        'reps': 'التكرارات',
        'mark_complete': 'تحديد كمكتمل',
        'medication_reminder': 'تذكير الدواء',
        'i_took_my_medication': 'أخذت الدواء',
        'next_injection_due': 'موعد الحقنة القادمة',
        'patient_360_view': 'رؤية 360 للمريض',
        'overview': 'نظرة عامة',
        'medical_history': 'التاريخ الطبي',
        'activity_log': 'سجل النشاط',
        'edit_plan': 'تعديل الخطة',
        'nearest_centers': 'أقرب المراكز',
        'distance': 'المسافة',
        'available_slots': 'المواعيد المتاحة',
        'category': 'الفئة',
        'cardio': 'تمارين قلبية',
        'strength': 'تمارين قوة',
        'flexibility': 'مرونة',
      }
    };

    _localizedStrings = translations[locale.languageCode] ?? translations['en']!;
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}