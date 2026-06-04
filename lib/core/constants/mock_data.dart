import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/locale_provider.dart';

enum ResidencyStatus { citizen, resident, visitor }

class Patient {
  final String id;
  final String emiratesId;
  final String fullName;
  final String fullNameAr;
  final String nationality;
  final String nationalityAr;
  final ResidencyStatus residencyStatus;
  final int age;
  final String gender;
  final String genderAr;
  double weight;
  final double height;
  final List<String> medicalConditions;
  final List<String> medicalConditionsAr;
  String? lastDispensingDate;
  String? nextEligibleDate;
  String currentDose;
  final double latitude;
  final double longitude;
  final String emirate;
  final String emirateAr;
  final List<double> weightHistory;
  final List<String> doseHistory;
  final double complianceRate;

  double get bmi => weight / ((height / 100) * (height / 100));

  Patient({
    required this.id,
    required this.emiratesId,
    required this.fullName,
    required this.fullNameAr,
    required this.nationality,
    required this.nationalityAr,
    required this.residencyStatus,
    required this.age,
    required this.gender,
    required this.genderAr,
    required this.weight,
    required this.height,
    required this.medicalConditions,
    required this.medicalConditionsAr,
    this.lastDispensingDate,
    this.nextEligibleDate,
    this.currentDose = '2.5 mg',
    required this.latitude,
    required this.longitude,
    required this.emirate,
    required this.emirateAr,
    required this.weightHistory,
    required this.doseHistory,
    required this.complianceRate,
  });

  bool _isAr(BuildContext context) => Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

  String getLocalizedFullName(BuildContext context) => _isAr(context) ? fullNameAr : fullName;
  String getLocalizedNationality(BuildContext context) => _isAr(context) ? nationalityAr : nationality;
  String getLocalizedGender(BuildContext context) => _isAr(context) ? genderAr : gender;
  String getLocalizedEmirate(BuildContext context) => _isAr(context) ? emirateAr : emirate;
  List<String> getLocalizedMedicalConditions(BuildContext context) => _isAr(context) ? medicalConditionsAr : medicalConditions;
  String getLocalizedResidency(BuildContext context) {
    if (_isAr(context)) {
      switch (residencyStatus) {
        case ResidencyStatus.citizen: return 'مواطن';
        case ResidencyStatus.resident: return 'مقيم';
        case ResidencyStatus.visitor: return 'زائر';
      }
    } else {
      switch (residencyStatus) {
        case ResidencyStatus.citizen: return 'Citizen';
        case ResidencyStatus.resident: return 'Resident';
        case ResidencyStatus.visitor: return 'Visitor';
      }
    }
  }

  Patient copyWith({
    double? weight,
    String? lastDispensingDate,
    String? nextEligibleDate,
    String? currentDose,
    List<double>? weightHistory,
    List<String>? doseHistory,
  }) {
    return Patient(
      id: id,
      emiratesId: emiratesId,
      fullName: fullName,
      fullNameAr: fullNameAr,
      nationality: nationality,
      nationalityAr: nationalityAr,
      residencyStatus: residencyStatus,
      age: age,
      gender: gender,
      genderAr: genderAr,
      weight: weight ?? this.weight,
      height: height,
      medicalConditions: medicalConditions,
      medicalConditionsAr: medicalConditionsAr,
      lastDispensingDate: lastDispensingDate ?? this.lastDispensingDate,
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      currentDose: currentDose ?? this.currentDose,
      latitude: latitude,
      longitude: longitude,
      emirate: emirate,
      emirateAr: emirateAr,
      weightHistory: weightHistory ?? this.weightHistory,
      doseHistory: doseHistory ?? this.doseHistory,
      complianceRate: complianceRate,
    );
  }
}

class DispensingCenter {
  final String id;
  final String name;
  final String nameAr;
  final String region; // Emirate
  final String regionAr;
  int inventory2_5mg;
  int inventory5mg;
  int inventory7_5mg;
  int inventory10mg;
  int dispensed2_5mg;
  int dispensed5mg;
  int dispensed7_5mg;
  int dispensed10mg;
  final double latitude;
  final double longitude;
  final String phone;

  DispensingCenter({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.region,
    required this.regionAr,
    required this.inventory2_5mg,
    required this.inventory5mg,
    required this.inventory7_5mg,
    required this.inventory10mg,
    this.dispensed2_5mg = 0,
    this.dispensed5mg = 0,
    this.dispensed7_5mg = 0,
    this.dispensed10mg = 0,
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  int get totalAvailable => inventory2_5mg + inventory5mg + inventory7_5mg + inventory10mg;
  int get totalDispensed => dispensed2_5mg + dispensed5mg + dispensed7_5mg + dispensed10mg;
  int get totalAllocated => totalAvailable + totalDispensed;

  bool _isAr(BuildContext context) => Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

  String getLocalizedName(BuildContext context) => _isAr(context) ? nameAr : name;
  String getLocalizedRegion(BuildContext context) => _isAr(context) ? regionAr : region;

  DispensingCenter copyWith({
    int? inventory2_5mg,
    int? inventory5mg,
    int? inventory7_5mg,
    int? inventory10mg,
    int? dispensed2_5mg,
    int? dispensed5mg,
    int? dispensed7_5mg,
    int? dispensed10mg,
  }) {
    return DispensingCenter(
      id: id,
      name: name,
      nameAr: nameAr,
      region: region,
      regionAr: regionAr,
      inventory2_5mg: inventory2_5mg ?? this.inventory2_5mg,
      inventory5mg: inventory5mg ?? this.inventory5mg,
      inventory7_5mg: inventory7_5mg ?? this.inventory7_5mg,
      inventory10mg: inventory10mg ?? this.inventory10mg,
      dispensed2_5mg: dispensed2_5mg ?? this.dispensed2_5mg,
      dispensed5mg: dispensed5mg ?? this.dispensed5mg,
      dispensed7_5mg: dispensed7_5mg ?? this.dispensed7_5mg,
      dispensed10mg: dispensed10mg ?? this.dispensed10mg,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
    );
  }
}

class ActivityLog {
  final String id;
  final String patientName;
  final String patientNameAr;
  final String patientId;
  final String action; // e.g. "Dispensed 5 mg", "Dose Escalation", "Created Assessment"
  final String actionAr;
  final String centerName;
  final String centerNameAr;
  final DateTime timestamp;
  final String status; // "Success", "Overridden", "Flagged"
  final String statusAr;

  ActivityLog({
    required this.id,
    required this.patientName,
    required this.patientNameAr,
    required this.patientId,
    required this.action,
    required this.actionAr,
    required this.centerName,
    required this.centerNameAr,
    required this.timestamp,
    required this.status,
    required this.statusAr,
  });

  bool _isAr(BuildContext context) => Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

  String getLocalizedPatientName(BuildContext context) => _isAr(context) ? patientNameAr : patientName;
  String getLocalizedAction(BuildContext context) => _isAr(context) ? actionAr : action;
  String getLocalizedCenterName(BuildContext context) => _isAr(context) ? centerNameAr : centerName;
  String getLocalizedStatus(BuildContext context) => _isAr(context) ? statusAr : status;
}

class PhysicalTherapyCenter {
  final String id;
  final String name;
  final String nameAr;
  final String emirate;
  final String emirateAr;
  final double latitude;
  final double longitude;
  final String phone;
  final int activePatients;
  final String chiefTherapist;
  final String chiefTherapistAr;
  final List<String> services;
  final List<String> servicesAr;
  final String workingHours;

  PhysicalTherapyCenter({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.emirate,
    required this.emirateAr,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.activePatients,
    required this.chiefTherapist,
    required this.chiefTherapistAr,
    required this.services,
    required this.servicesAr,
    required this.workingHours,
  });

  bool _isAr(BuildContext context) => Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

  String getLocalizedName(BuildContext context) => _isAr(context) ? nameAr : name;
  String getLocalizedEmirate(BuildContext context) => _isAr(context) ? emirateAr : emirate;
  String getLocalizedChiefTherapist(BuildContext context) => _isAr(context) ? chiefTherapistAr : chiefTherapist;
  List<String> getLocalizedServices(BuildContext context) => _isAr(context) ? servicesAr : services;
}

class MockData {
  // Legacy static lists to keep compatibility with parts of the code
  static final List<Patient> patients = _generateInitialPatients();
  static final List<DispensingCenter> centers = _generateInitialCenters();
  static final List<PhysicalTherapyCenter> therapyCenters = _generateInitialTherapyCenters();

  static List<PhysicalTherapyCenter> _generateInitialTherapyCenters() {
    return [
      PhysicalTherapyCenter(
        id: 'T001',
        name: 'Al Mafraq Physical Therapy & Rehab',
        nameAr: 'المفرق للعلاج الطبيعي والتأهيل',
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',

        latitude: 24.2800,
        longitude: 54.5800,
        phone: '+971 2 699 1111',
        activePatients: 45,
        
        chiefTherapist: 'Dr. Salem Al-Harthi',
        chiefTherapistAr: 'د. سالم الحارثي',
        services: ['Obesity Rehab', 'Cardio Conditioning', 'Post-Bariatric Training'],
        servicesAr: ['تأهيل السمنة', 'التكييف القلبي', 'تدريب ما بعد جراحة السمنة'],

        workingHours: '08:00 AM - 08:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T002',
        name: 'Rashid Bariatric Rehab & PT Center',
        nameAr: 'مركز راشد لتأهيل السمنة والعلاج الطبيعي',
        emirate: 'Dubai',
        emirateAr: 'دبي',

        latitude: 25.2300,
        longitude: 55.3200,
        phone: '+971 4 399 2222',
        activePatients: 72,
        
        chiefTherapist: 'Dr. Sarah Jenkins (PT)',
        chiefTherapistAr: 'د. سارة جينكينز',
        services: ['Kinesiotherapy', 'Body Contouring Rehab', 'Post-Surgical Exercise'],
        servicesAr: ['العلاج الحركي', 'تأهيل نحت الجسم', 'تمارين ما بعد الجراحة'],

        workingHours: '08:00 AM - 09:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T003',
        name: 'Al Qassimi Physical Medicine Center',
        nameAr: 'مركز القاسمي للطب الطبيعي',
        emirate: 'Sharjah',
        emirateAr: 'الشارقة',

        latitude: 25.3350,
        longitude: 55.4300,
        phone: '+971 6 544 3333',
        activePatients: 38,
        
        chiefTherapist: 'Amir Al-Hassan',
        chiefTherapistAr: 'أمير الحسن',
        services: ['Obesity Rehab', 'Mobility Therapy', 'Muscle Strength Conditioning'],
        servicesAr: ['تأهيل السمنة', 'علاج الحركة', 'تكييف قوة العضلات'],

        workingHours: '09:00 AM - 06:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T004',
        name: 'Khalifa Physiotherapy & Wellness Clinic',
        nameAr: 'عيادة خليفة للعلاج الطبيعي والصحة',
        emirate: 'Ajman',
        emirateAr: 'عجمان',

        latitude: 25.4080,
        longitude: 55.4680,
        phone: '+971 6 722 4444',
        activePatients: 29,
        
        chiefTherapist: 'Dr. Elena Rostova',
        chiefTherapistAr: 'د. إيلينا روستوفا',
        services: ['Therapeutic Exercises', 'Weight Loss Training'],
        servicesAr: ['تمارين علاجية', 'تدريب فقدان الوزن'],

        workingHours: '08:00 AM - 08:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T005',
        name: 'Ibrahim Bin Hamad PT Specialist Center',
        nameAr: 'مركز إبراهيم بن حمد التخصصي للعلاج الطبيعي',
        emirate: 'Ras Al Khaimah',
        emirateAr: 'رأس الخيمة',

        latitude: 25.7950,
        longitude: 55.9550,
        phone: '+971 7 244 5555',
        activePatients: 31,
        
        chiefTherapist: 'Dr. Marcus Evans',
        chiefTherapistAr: 'د. ماركوس إيفانز',
        services: ['Post-Bariatric Training', 'Joint Mobility Therapy', 'Hydrotherapy'],
        servicesAr: ['تدريب ما بعد جراحة السمنة', 'علاج حركة المفاصل', 'العلاج المائي'],

        workingHours: '08:00 AM - 05:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T006',
        name: 'Fujairah Medical Rehab & Sports Clinic',
        nameAr: 'عيادة الفجيرة للتأهيل الطبي والرياضي',
        emirate: 'Fujairah',
        emirateAr: 'الفجيرة',

        latitude: 25.1200,
        longitude: 56.3200,
        phone: '+971 9 222 6666',
        activePatients: 24,
        
        chiefTherapist: 'Muna Al-Suwaidi (PT)',
        chiefTherapistAr: 'منى السويدي',
        services: ['Cardiovascular Conditioning', 'Obesity Rehab'],
        servicesAr: ['التكييف القلبي الوعائي', 'تأهيل السمنة'],

        workingHours: '08:00 AM - 06:00 PM',
      ),
    ];
  }

  static List<DispensingCenter> _generateInitialCenters() {
    return [
      DispensingCenter(
        id: 'C001',
        name: 'Dubai Central Hospital',
        nameAr: 'مستشفى دبي المركزي',
        region: 'Dubai',
        regionAr: 'دبي',

        inventory2_5mg: 120,
        inventory5mg: 85,
        inventory7_5mg: 40,
        inventory10mg: 15,
        dispensed2_5mg: 230,
        dispensed5mg: 160,
        dispensed7_5mg: 45,
        dispensed10mg: 10,
        latitude: 25.2208,
        longitude: 55.2800,
        phone: '+971 4 219 5000',
      ),
      DispensingCenter(
        id: 'C002',
        name: 'Abu Dhabi Medical City',
        nameAr: 'مدينة أبوظبي الطبية',
        region: 'Abu Dhabi',
        regionAr: 'أبوظبي',

        inventory2_5mg: 200,
        inventory5mg: 140,
        inventory7_5mg: 90,
        inventory10mg: 45,
        dispensed2_5mg: 350,
        dispensed5mg: 220,
        dispensed7_5mg: 110,
        dispensed10mg: 35,
        latitude: 24.4700,
        longitude: 54.3600,
        phone: '+971 2 819 0000',
      ),
      DispensingCenter(
        id: 'C003',
        name: 'Sharjah Specialty Clinic',
        nameAr: 'عيادة الشارقة التخصصية',
        region: 'Sharjah',
        regionAr: 'الشارقة',

        inventory2_5mg: 80,
        inventory5mg: 60,
        inventory7_5mg: 30,
        inventory10mg: 10,
        dispensed2_5mg: 180,
        dispensed5mg: 140,
        dispensed7_5mg: 60,
        dispensed10mg: 20,
        latitude: 25.3500,
        longitude: 55.4000,
        phone: '+971 6 518 8888',
      ),
      DispensingCenter(
        id: 'C004',
        name: 'Al Ain Wellness Center',
        nameAr: 'مركز العين الصحي',
        region: 'Al Ain',
        regionAr: 'Al Ain',

        inventory2_5mg: 95,
        inventory5mg: 70,
        inventory7_5mg: 35,
        inventory10mg: 12,
        dispensed2_5mg: 150,
        dispensed5mg: 95,
        dispensed7_5mg: 45,
        dispensed10mg: 15,
        latitude: 24.1873,
        longitude: 55.7606,
        phone: '+971 3 707 2222',
      ),
      DispensingCenter(
        id: 'C005',
        name: 'Ajman Community Hospital',
        nameAr: 'مستشفى عجمان المجتمعي',
        region: 'Ajman',
        regionAr: 'عجمان',

        inventory2_5mg: 60,
        inventory5mg: 45,
        inventory7_5mg: 15,
        inventory10mg: 5,
        dispensed2_5mg: 110,
        dispensed5mg: 85,
        dispensed7_5mg: 25,
        dispensed10mg: 5,
        latitude: 25.4052,
        longitude: 55.4390,
        phone: '+971 6 711 7777',
      ),
      DispensingCenter(
        id: 'C006',
        name: 'Fujairah Government Clinic',
        nameAr: 'عيادة الفجيرة الحكومية',
        region: 'Fujairah',
        regionAr: 'الفجيرة',

        inventory2_5mg: 75,
        inventory5mg: 50,
        inventory7_5mg: 20,
        inventory10mg: 8,
        dispensed2_5mg: 125,
        dispensed5mg: 90,
        dispensed7_5mg: 30,
        dispensed10mg: 10,
        latitude: 25.1288,
        longitude: 56.3265,
        phone: '+971 9 224 2222',
      ),
      DispensingCenter(
        id: 'C007',
        name: 'Ras Al Khaimah Medical Center',
        nameAr: 'مركز رأس الخيمة الطبي',
        region: 'Ras Al Khaimah',
        regionAr: 'رأس الخيمة',

        inventory2_5mg: 90,
        inventory5mg: 65,
        inventory7_5mg: 25,
        inventory10mg: 10,
        dispensed2_5mg: 140,
        dispensed5mg: 110,
        dispensed7_5mg: 40,
        dispensed10mg: 12,
        latitude: 25.7895,
        longitude: 55.9432,
        phone: '+971 7 203 5555',
      ),
      DispensingCenter(
        id: 'C008',
        name: 'Umm Al Quwain Hospital',
        nameAr: 'مستشفى أم القيوين',
        region: 'Umm Al Quwain',
        regionAr: 'أم القيوين',

        inventory2_5mg: 50,
        inventory5mg: 30,
        inventory7_5mg: 10,
        inventory10mg: 2,
        dispensed2_5mg: 80,
        dispensed5mg: 65,
        dispensed7_5mg: 15,
        dispensed10mg: 5,
        latitude: 25.5647,
        longitude: 55.5551,
        phone: '+971 6 706 0000',
      ),
      DispensingCenter(
        id: 'C009',
        name: 'Sheikh Khalifa General Hospital',
        nameAr: 'مستشفى الشيخ خليفة العام',
        region: 'Umm Al Quwain',
        regionAr: 'أم القيوين',

        inventory2_5mg: 85,
        inventory5mg: 55,
        inventory7_5mg: 25,
        inventory10mg: 10,
        dispensed2_5mg: 160,
        dispensed5mg: 95,
        dispensed7_5mg: 35,
        dispensed10mg: 10,
        latitude: 25.5222,
        longitude: 55.5200,
        phone: '+971 6 767 1111',
      ),
      DispensingCenter(
        id: 'C010',
        name: 'Mussafah Primary Health',
        nameAr: 'مركز مصفح الصحي الأولي',
        region: 'Abu Dhabi',
        regionAr: 'أبوظبي',

        inventory2_5mg: 110,
        inventory5mg: 80,
        inventory7_5mg: 45,
        inventory10mg: 20,
        dispensed2_5mg: 190,
        dispensed5mg: 135,
        dispensed7_5mg: 60,
        dispensed10mg: 25,
        latitude: 24.3500,
        longitude: 54.5200,
        phone: '+971 2 506 2000',
      ),
      DispensingCenter(
        id: 'C011',
        name: 'Al Barsha Health Center',
        nameAr: 'مركز البرشاء الصحي',
        region: 'Dubai',
        regionAr: 'دبي',

        inventory2_5mg: 130,
        inventory5mg: 90,
        inventory7_5mg: 50,
        inventory10mg: 30,
        dispensed2_5mg: 240,
        dispensed5mg: 180,
        dispensed7_5mg: 75,
        dispensed10mg: 40,
        latitude: 25.1050,
        longitude: 55.1950,
        phone: '+971 4 502 3300',
      ),
      DispensingCenter(
        id: 'C012',
        name: 'Al Nahda Medical Center',
        nameAr: 'مركز النهدة الطبي',
        region: 'Sharjah',
        regionAr: 'الشارقة',

        inventory2_5mg: 90,
        inventory5mg: 60,
        inventory7_5mg: 30,
        inventory10mg: 15,
        dispensed2_5mg: 165,
        dispensed5mg: 115,
        dispensed7_5mg: 45,
        dispensed10mg: 20,
        latitude: 25.3020,
        longitude: 55.3780,
        phone: '+971 6 525 4400',
      ),
      DispensingCenter(
        id: 'C013',
        name: 'Khor Fakkan Hospital',
        nameAr: 'مستشفى خورفكان',
        region: 'Sharjah',
        regionAr: 'الشارقة',

        inventory2_5mg: 60,
        inventory5mg: 40,
        inventory7_5mg: 20,
        inventory10mg: 8,
        dispensed2_5mg: 95,
        dispensed5mg: 75,
        dispensed7_5mg: 25,
        dispensed10mg: 12,
        latitude: 25.3374,
        longitude: 56.3414,
        phone: '+971 9 238 6000',
      ),
      DispensingCenter(
        id: 'C014',
        name: 'Al Dhait Medical Center',
        nameAr: 'مركز الظيت الطبي',
        region: 'Ras Al Khaimah',
        regionAr: 'رأس الخيمة',

        inventory2_5mg: 70,
        inventory5mg: 45,
        inventory7_5mg: 20,
        inventory10mg: 6,
        dispensed2_5mg: 130,
        dispensed5mg: 85,
        dispensed7_5mg: 35,
        dispensed10mg: 8,
        latitude: 25.7580,
        longitude: 55.9320,
        phone: '+971 7 205 1111',
      ),
      DispensingCenter(
        id: 'C015',
        name: 'Dibba Al Fujairah Hospital',
        nameAr: 'مستشفى دبا الفجيرة',
        region: 'Fujairah',
        regionAr: 'الفجيرة',

        inventory2_5mg: 65,
        inventory5mg: 45,
        inventory7_5mg: 15,
        inventory10mg: 5,
        dispensed2_5mg: 105,
        dispensed5mg: 65,
        dispensed7_5mg: 25,
        dispensed10mg: 8,
        latitude: 25.6110,
        longitude: 56.2730,
        phone: '+971 9 244 9000',
      ),
    ];
  }

    static List<Patient> _generateInitialPatients() {
    final List<String> maleNames = [
      'Ahmed Al Mansoori', 'Khalid Al Hashimi', 'Zayed Al Nahyan', 'Sultan Al Qasimi',
      'Rashid Al Nuaimi', 'Faisal Al Ketbi', 'Humaid Al Shamsi', 'Mohammed Al Falasi',
      'Saeed Al Maktoum', 'Omar Al Suwaidi', 'Tariq Al Jaber', 'Hamdan Al Kaabi',
      'Yousef Al Shehhi', 'Adnan Al Mazrouei', 'Saif Al Hameli', 'Majid Al Ghurair',
      'Ali Al Naboodah', 'Marwan Al Tayer', 'Salem Al Sayegh', 'Waleed Al Gurg',
      'Michael Smith', 'David Jones', 'John Doe', 'Jean Dupont', 'Omar Farooq',
      'Priya Kumar', 'Wong Wei', 'Vikram Patel', 'Siddharth Sharma', 'Amir Khan',
      'Robert Miller', 'James Taylor', 'William Davis', 'Alexander Brown', 'Thomas Wilson'
    ];
    final List<String> maleNamesAr = [
      'أحمد المنصوري', 'خالد الهاشمي', 'زايد آل نهيان', 'سلطان القاسمي',
      'راشد النعيمي', 'فيصل الكتبي', 'حميد الشامسي', 'محمد الفلاسي',
      'سعيد آل مكتوم', 'عمر السويدي', 'طارق الجابر', 'حمدان الكعبي',
      'يوسف الشحي', 'عدنان المزروعي', 'سيف الهاملي', 'ماجد الغرير',
      'علي النابودة', 'مروان الطاير', 'سالم الصايغ', 'وليد القرق',
      'مايكل سميث', 'ديفيد جونز', 'جون دو', 'جان دوبونت', 'عمر فاروق',
      'بريا كومار', 'ونغ وي', 'فيكرام باتيل', 'سيدهارث شارما', 'أمير خان',
      'روبرت ميلر', 'جيمس تايلور', 'ويليام ديفيس', 'ألكسندر براون', 'توماس ويلسون'
    ];

    final List<String> femaleNames = [
      'Sarah Johnson', 'Fatima Al Qasimi', 'Mariam Al Kaabi', 'Shamma Al Maktoum',
      'Amna Al Shehhi', 'Reem Al Hashimi', 'Maitha Al Falasi', 'Latifa Al Maktoum',
      'Muna Al Shamsi', 'Hessa Al Suwaidi', 'Aisha Al Jaber', 'Noora Al Mansoori',
      'Salama Al Ketbi', 'Hind Al Mazrouei', 'Jawahir Al Qasimi', 'Rawda Al Hameli',
      'Shaikha Al Tayer', 'Moza Al Naboodah', 'Alia Al Sayegh', 'Budoor Al Gurg',
      'Sarah Connor', 'Emma Watson', 'Elena Petrova', 'Sophia Müller', 'Fatima Rahman',
      'Deepika Sharma', 'Mei Ling', 'Aisha Farooq', 'Yasmin Zayed', 'Layla Kanaan',
      'Olivia Martinez', 'Isabella Anderson', 'Mia Thomas', 'Charlotte White', 'Amelia Taylor'
    ];
    final List<String> femaleNamesAr = [
      'سارة جونسون', 'فاطمة القاسمي', 'مريم الكعبي', 'شمة آل مكتوم',
      'آمنة الشحي', 'ريم الهاشمي', 'ميثاء الفلاسي', 'لطيفة آل مكتوم',
      'منى الشامسي', 'حصة السويدي', 'عائشة الجابر', 'نورة المنصوري',
      'سلامة الكتبي', 'هند المزروعي', 'جواهر القاسمي', 'روضة الهاملي',
      'شيخة الطاير', 'موزة النابودة', 'عليا الصايغ', 'بدور القرق',
      'سارة كونور', 'إيما واتسون', 'إيلينا بتروفا', 'صوفيا مولر', 'فاطمة رحمن',
      'ديبيكا شارما', 'مي لينغ', 'عائشة فاروق', 'ياسمين زايد', 'ليلى كنعان',
      'أوليفيا مارتينيز', 'إيزابيلا أندرسون', 'ميا توماس', 'شارلوت وايت', 'أميليا تايلور'
    ];

    final List<String> nationalities = [
      'United Arab Emirates', 'United Kingdom', 'United States', 'India', 'Pakistan',
      'Egypt', 'Saudi Arabia', 'Jordan', 'Lebanon', 'Canada', 'France', 'Germany',
      'China', 'Philippines', 'South Africa'
    ];
    final List<String> nationalitiesAr = [
      'الإمارات العربية المتحدة', 'المملكة المتحدة', 'الولايات المتحدة', 'الهند', 'باكستان',
      'مصر', 'المملكة العربية السعودية', 'الأردن', 'لبنان', 'كندا', 'فرنسا', 'ألمانيا',
      'الصين', 'الفلبين', 'جنوب أفريقيا'
    ];

    final List<String> conditions = [
      'Obesity', 'Type 2 Diabetes', 'Hypertension', 'Dyslipidemia', 'Pre-diabetes',
      'PCOS', 'Sleep Apnea', 'Fatty Liver Disease', 'Osteoarthritis'
    ];
    final List<String> conditionsAr = [
      'السمنة', 'السكري من النوع 2', 'ارتفاع ضغط الدم', 'عسر شحميات الدم', 'مرحلة ما قبل السكري',
      'تكيس المبايض', 'توقف التنفس أثناء النوم', 'مرض الكبد الدهني', 'هشاشة العظام'
    ];

    final List<Map<String, dynamic>> emirateCoords = [
      {'name': 'Abu Dhabi', 'nameAr': 'أبوظبي', 'lat': 24.4539, 'lng': 54.3773},
      {'name': 'Dubai', 'nameAr': 'دبي', 'lat': 25.2048, 'lng': 55.2708},
      {'name': 'Sharjah', 'nameAr': 'الشارقة', 'lat': 25.3463, 'lng': 55.4209},
      {'name': 'Ajman', 'nameAr': 'عجمان', 'lat': 25.4052, 'lng': 55.4390},
      {'name': 'Umm Al Quwain', 'nameAr': 'أم القيوين', 'lat': 25.5647, 'lng': 55.5551},
      {'name': 'Ras Al Khaimah', 'nameAr': 'رأس الخيمة', 'lat': 25.7895, 'lng': 55.9432},
      {'name': 'Fujairah', 'nameAr': 'الفجيرة', 'lat': 25.1288, 'lng': 56.3265},
    ];

    final List<Patient> list = [];
    final rand = Random(42); // Seeded for consistency

    // Ensure we have some base patients at specific indices to prevent breaking existing code
    list.add(
      Patient(
        id: 'P001',
        emiratesId: '784-1980-1234567-1',
        fullName: 'Ahmed Al Mansoori',
        fullNameAr: 'أحمد المنصوري',
        nationality: 'United Arab Emirates',
        nationalityAr: 'الإمارات العربية المتحدة',
        residencyStatus: ResidencyStatus.citizen,
        age: 45,
        gender: 'Male',
        genderAr: 'ذكر',
        weight: 105.0,
        height: 175.0,
        medicalConditions: ['Type 2 Diabetes', 'Hypertension', 'Obesity'],
        medicalConditionsAr: ['السكري من النوع 2', 'ارتفاع ضغط الدم', 'السمنة'],
        lastDispensingDate: '2026-05-10',
        nextEligibleDate: '2026-06-10',
        currentDose: '5 mg',
        latitude: 24.4539,
        longitude: 54.3773,
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',
        weightHistory: [112.5, 110.0, 108.2, 106.8, 105.0],
        doseHistory: ['2.5 mg', '2.5 mg', '5 mg', '5 mg', '5 mg'],
        complianceRate: 0.96,
      ),
    );

    list.add(
      Patient(
        id: 'P002',
        emiratesId: '784-1992-7654321-2',
        fullName: 'Sarah Johnson',
        fullNameAr: 'سارة جونسون',
        nationality: 'United Kingdom',
        nationalityAr: 'المملكة المتحدة',
        residencyStatus: ResidencyStatus.resident,
        age: 34,
        gender: 'Female',
        genderAr: 'أنثى',
        weight: 92.0,
        height: 165.0,
        medicalConditions: ['Obesity', 'PCOS'],
        medicalConditionsAr: ['السمنة', 'تكيس المبايض'],
        lastDispensingDate: '2026-06-03',
        nextEligibleDate: '2026-07-03',
        currentDose: '2.5 mg',
        latitude: 25.2048,
        longitude: 55.2708,
        emirate: 'Dubai',
        emirateAr: 'دبي',
        weightHistory: [96.0, 94.5, 93.0, 92.0],
        doseHistory: ['2.5 mg', '2.5 mg', '2.5 mg', '2.5 mg'],
        complianceRate: 0.88,
      ),
    );

    list.add(
      Patient(
        id: 'P003',
        emiratesId: '784-1985-9876543-3',
        fullName: 'Michael Smith',
        fullNameAr: 'مايكل سميث',
        nationality: 'United States',
        nationalityAr: 'الولايات المتحدة',
        residencyStatus: ResidencyStatus.visitor,
        age: 41,
        gender: 'Male',
        genderAr: 'ذكر',
        weight: 115.0,
        height: 180.0,
        medicalConditions: ['Obesity'],
        medicalConditionsAr: ['السمنة'],
        lastDispensingDate: null,
        nextEligibleDate: 'Eligible Now',
        currentDose: '2.5 mg',
        latitude: 25.3463,
        longitude: 55.4209,
        emirate: 'Sharjah',
        emirateAr: 'الشارقة',
        weightHistory: [118.0, 116.5, 115.0],
        doseHistory: ['2.5 mg', '2.5 mg', '2.5 mg'],
        complianceRate: 0.75,
      ),
    );

    list.add(
      Patient(
        id: 'P004',
        emiratesId: '784-1975-1122334-4',
        fullName: 'Fatima Al Qasimi',
        fullNameAr: 'فاطمة القاسمي',
        nationality: 'United Arab Emirates',
        nationalityAr: 'الإمارات العربية المتحدة',
        residencyStatus: ResidencyStatus.citizen,
        age: 51,
        gender: 'Female',
        genderAr: 'أنثى',
        weight: 120.0,
        height: 160.0,
        medicalConditions: ['Obesity', 'Pre-diabetes'],
        medicalConditionsAr: ['السمنة', 'مرحلة ما قبل السكري'],
        lastDispensingDate: '2026-04-15',
        nextEligibleDate: '2026-05-15',
        currentDose: '7.5 mg',
        latitude: 24.1873,
        longitude: 55.7606,
        emirate: 'Al Ain',
        emirateAr: 'العين',
        weightHistory: [132.0, 129.5, 126.0, 123.5, 120.0],
        doseHistory: ['2.5 mg', '5 mg', '5 mg', '7.5 mg', '7.5 mg'],
        complianceRate: 0.98,
      ),
    );

    list.add(
      Patient(
        id: 'P005',
        emiratesId: '784-1990-5566778-5',
        fullName: 'Rashid Al Nuaimi',
        fullNameAr: 'راشد النعيمي',
        nationality: 'United Arab Emirates',
        nationalityAr: 'الإمارات العربية المتحدة',
        residencyStatus: ResidencyStatus.citizen,
        age: 36,
        gender: 'Male',
        genderAr: 'ذكر',
        weight: 98.0,
        height: 178.0,
        medicalConditions: ['Obesity'],
        medicalConditionsAr: ['السمنة'],
        lastDispensingDate: '2026-05-20',
        nextEligibleDate: '2026-06-20',
        currentDose: '5 mg',
        latitude: 25.4052,
        longitude: 55.4390,
        emirate: 'Ajman',
        emirateAr: 'عجمان',
        weightHistory: [104.0, 102.0, 100.5, 98.0],
        doseHistory: ['2.5 mg', '2.5 mg', '5 mg', '5 mg'],
        complianceRate: 0.90,
      ),
    );

    for (int i = 6; i <= 100; i++) {
      final gender = rand.nextBool() ? 'Male' : 'Female';
      final nameIdx = rand.nextInt(maleNames.length);
      final name = gender == 'Male' ? maleNames[nameIdx] : femaleNames[nameIdx];
      final nameAr = gender == 'Male' ? maleNamesAr[nameIdx] : femaleNamesAr[nameIdx];
      
      final suffixAscii = 65 + rand.nextInt(26);
      final suffixAr = String.fromCharCode(1575 + rand.nextInt(28)); // Random Arabic letter
      final uniqueName = '$name ${String.fromCharCode(suffixAscii)}.';
      final uniqueNameAr = '$nameAr ($suffixAr)';
      
      final natIdx = rand.nextInt(10) < 6 ? 0 : rand.nextInt(nationalities.length);
      final nationality = nationalities[natIdx];
      final nationalityAr = nationalitiesAr[natIdx];
      
      final residency = nationality == 'United Arab Emirates'
          ? ResidencyStatus.citizen
          : (rand.nextBool() ? ResidencyStatus.resident : ResidencyStatus.visitor);
      
      final age = 18 + rand.nextInt(65);
      final height = gender == 'Male' ? 165 + rand.nextDouble() * 25 : 150 + rand.nextDouble() * 25;
      final weight = 80.0 + rand.nextDouble() * 70.0;
      
      final distinctConditions = <String>['Obesity'];
      final distinctConditionsAr = <String>['السمنة'];
      if (rand.nextBool()) {
        final cIdx = rand.nextInt(conditions.length);
        if (!distinctConditions.contains(conditions[cIdx])) {
            distinctConditions.add(conditions[cIdx]);
            distinctConditionsAr.add(conditionsAr[cIdx]);
        }
        if (rand.nextBool()) {
          final cIdx2 = rand.nextInt(conditions.length);
          if (!distinctConditions.contains(conditions[cIdx2])) {
              distinctConditions.add(conditions[cIdx2]);
              distinctConditionsAr.add(conditionsAr[cIdx2]);
          }
        }
      }

      final emRegion = emirateCoords[rand.nextInt(emirateCoords.length)];
      
      final double latJitter = (rand.nextDouble() - 0.5) * 0.15;
      final double lngJitter = (rand.nextDouble() - 0.5) * 0.15;

      final startingWeight = weight + (3.0 + rand.nextDouble() * 12.0);
      final steps = 3 + rand.nextInt(5);
      final weightHist = <double>[];
      double currentWeightValue = startingWeight;
      for (int s = 0; s < steps; s++) {
        weightHist.add(double.parse(currentWeightValue.toStringAsFixed(1)));
        currentWeightValue -= (0.5 + rand.nextDouble() * 2.0);
      }
      weightHist.add(double.parse(weight.toStringAsFixed(1)));

      final doseHist = <String>[];
      for (int s = 0; s < weightHist.length; s++) {
        if (s < 2) doseHist.add('2.5 mg');
        else if (s < 4) doseHist.add('5 mg');
        else doseHist.add('7.5 mg');
      }

      final year = 1960 + rand.nextInt(45);
      final idNum1 = 1000 + rand.nextInt(8999);
      final idNum2 = rand.nextInt(9);
      final emiratesId = '784-$year-$idNum1-$idNum2';

      final lastDispDate = rand.nextBool() 
          ? '2026-05-${10 + rand.nextInt(20)}' 
          : (rand.nextBool() ? '2026-06-0${1 + rand.nextInt(3)}' : null);
      
      String? nextDispDate = 'Eligible Now';
      if (lastDispDate != null) {
        final day = int.parse(lastDispDate.split('-')[2]);
        final month = int.parse(lastDispDate.split('-')[1]);
        final nextMonth = month + 1;
        nextDispDate = '2026-0${nextMonth}-${day < 10 ? "0$day" : day}';
      }

      list.add(
        Patient(
          id: 'P${i.toString().padLeft(3, "0")}',
          emiratesId: emiratesId,
          fullName: uniqueName,
          fullNameAr: uniqueNameAr,
          nationality: nationality,
          nationalityAr: nationalityAr,
          residencyStatus: residency,
          age: age,
          gender: gender,
          genderAr: gender == 'Male' ? 'ذكر' : 'أنثى',
          weight: double.parse(weight.toStringAsFixed(1)),
          height: double.parse(height.toStringAsFixed(1)),
          medicalConditions: distinctConditions,
          medicalConditionsAr: distinctConditionsAr,
          lastDispensingDate: lastDispDate,
          nextEligibleDate: nextDispDate,
          currentDose: ['2.5 mg', '5 mg', '7.5 mg', '10 mg'][rand.nextInt(4)],
          latitude: emRegion['lat'] + latJitter,
          longitude: emRegion['lng'] + lngJitter,
          emirate: emRegion['name'],
          emirateAr: emRegion['nameAr'],
          weightHistory: weightHist,
          doseHistory: doseHist,
          complianceRate: double.parse((0.70 + rand.nextDouble() * 0.29).toStringAsFixed(2)),
        ),
      );
    }
    return list;
  }
}

class DataProvider extends ChangeNotifier {
  late List<Patient> _patients;
  late List<DispensingCenter> _centers;
  late List<PhysicalTherapyCenter> _therapyCenters;
  final List<ActivityLog> _logs = [];

  DataProvider() {
    _patients = List.from(MockData.patients);
    _centers = List.from(MockData.centers);
    _therapyCenters = List.from(MockData.therapyCenters);
    
    // Seed initial activity logs
    _seedActivityLogs();
  }

  List<Patient> get patients => _patients;
  List<DispensingCenter> get centers => _centers;
  List<PhysicalTherapyCenter> get therapyCenters => _therapyCenters;
  List<ActivityLog> get logs => _logs;

  void _seedActivityLogs() {
    final rand = Random(123);
    for (int i = 0; i < 25; i++) {
      final p = _patients[rand.nextInt(_patients.length)];
      final c = _centers[rand.nextInt(_centers.length)];
      final doses = ['2.5 mg', '5 mg', '7.5 mg', '10 mg'];
      final dose = doses[rand.nextInt(doses.length)];
      final statuses = ['Success', 'Success', 'Success', 'Overridden', 'Flagged'];
      final statusesAr = ['ناجح', 'ناجح', 'ناجح', 'تم التجاوز', 'مُعلّم'];
      final statusIdx = rand.nextInt(statuses.length);
      final status = statuses[statusIdx];
      final statusAr = statusesAr[statusIdx];
      
      _logs.add(
        ActivityLog(
          id: 'LOG${i.toString().padLeft(3, "0")}',
          patientName: p.fullName,
          patientNameAr: p.fullNameAr,
          patientId: p.id,
          action: 'Dispensed $dose',
          actionAr: 'صرف $dose',
          centerName: c.name,
          centerNameAr: c.nameAr,
          timestamp: DateTime.now().subtract(Duration(days: rand.nextInt(30), hours: rand.nextInt(24))),
          status: status,
          statusAr: statusAr,
        ),
      );
    }
    // Sort by most recent
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Business Operations
  
  // Dispense Mounjaro to a Patient at a specific Center
  bool dispenseMedication({
    required String patientId,
    required String centerId,
    required String dose,
    bool isOverride = false,
  }) {
    final patientIndex = _patients.indexWhere((p) => p.id == patientId);
    final centerIndex = _centers.indexWhere((c) => c.id == centerId);

    if (patientIndex == -1 || centerIndex == -1) return false;

    final p = _patients[patientIndex];
    final c = _centers[centerIndex];

    // Check inventory
    bool hasInventory = false;
    if (dose == '2.5 mg' && c.inventory2_5mg > 0) {
      c.inventory2_5mg--;
      hasInventory = true;
    } else if (dose == '5 mg' && c.inventory5mg > 0) {
      c.inventory5mg--;
      hasInventory = true;
    } else if (dose == '7.5 mg' && c.inventory7_5mg > 0) {
      c.inventory7_5mg--;
      hasInventory = true;
    } else if (dose == '10 mg' && c.inventory10mg > 0) {
      c.inventory10mg--;
      hasInventory = true;
    }

    if (!hasInventory) return false;

    // Update patient dispensing dates
    final nowStr = DateTime.now().toString().split(' ')[0]; // yyyy-MM-dd
    final nextStr = DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0];

    _patients[patientIndex] = p.copyWith(
      lastDispensingDate: nowStr,
      nextEligibleDate: nextStr,
      currentDose: dose,
    );

    // Add activity log
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: p.fullName,
        patientNameAr: p.fullNameAr,
        patientId: p.id,
        action: 'Dispensed $dose',
        actionAr: 'صرف $dose',
        centerName: c.name,
        centerNameAr: c.nameAr,
        timestamp: DateTime.now(),
        status: isOverride ? 'Overridden' : 'Success',
        statusAr: isOverride ? 'تم التجاوز' : 'ناجح',
      ),
    );

    notifyListeners();
    return true;
  }

  // Record a Patient weight check-in (Doctor or Patient portal)
  void recordWeight(String patientId, double newWeight) {

    final patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex == -1) return;

    final p = _patients[patientIndex];
    final updatedHistory = List<double>.from(p.weightHistory)..add(newWeight);
    
    _patients[patientIndex] = p.copyWith(
      weight: newWeight,
      weightHistory: updatedHistory,
    );

    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG\${_logs.length + 1}',
        patientName: p.fullName,
        patientNameAr: p.fullNameAr,
        patientId: p.id,
        action: 'Weight updated to \${newWeight.toStringAsFixed(1)} kg',
        actionAr: 'تم تحديث الوزن',
        centerName: 'Clinical Portal',
        centerNameAr: 'البوابة السريرية',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );

    notifyListeners();
  }

  // Escalating or changing dosage
  void updateDose(String patientId, String newDose) {
    final patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex == -1) return;

    final p = _patients[patientIndex];
    final updatedDoseHistory = List<String>.from(p.doseHistory)..add(newDose);

    _patients[patientIndex] = p.copyWith(
      currentDose: newDose,
      doseHistory: updatedDoseHistory,
    );

    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG\${_logs.length + 1}',
        patientName: p.fullName,
        patientNameAr: p.fullNameAr,
        patientId: p.id,
        action: 'Dose escalated to \$newDose',
        actionAr: 'تمت زيادة الجرعة',
        centerName: 'Clinical Portal',
        centerNameAr: 'البوابة السريرية',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );

    notifyListeners();
  }

  // Add new Patient
  void registerPatient(Patient newPatient) {
    _patients.add(newPatient);
    
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG\${_logs.length + 1}',
        patientName: newPatient.fullName,
        patientNameAr: newPatient.fullNameAr,
        patientId: newPatient.id,
        action: 'Patient registered',
        actionAr: 'تم تسجيل المريض',
        centerName: 'Ministry System',
        centerNameAr: 'نظام الوزارة',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );

    notifyListeners();
  }

  // Update Inventory directly (Ministry or Dispensing Center)
  void updateInventory(String centerId, {int? d2_5, int? d5, int? d7_5, int? d10}) {
    final idx = _centers.indexWhere((c) => c.id == centerId);
    if (idx == -1) return;

    final c = _centers[idx];
    _centers[idx] = c.copyWith(
      inventory2_5mg: d2_5 != null ? c.inventory2_5mg + d2_5 : null,
      inventory5mg: d5 != null ? c.inventory5mg + d5 : null,
      inventory7_5mg: d7_5 != null ? c.inventory7_5mg + d7_5 : null,
      inventory10mg: d10 != null ? c.inventory10mg + d10 : null,
    );

    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG\${_logs.length + 1}',
        patientName: 'System Inventory',
        patientNameAr: 'جرد النظام',
        patientId: 'INV',
        action: 'Restocked at \${c.name}',
        actionAr: 'تم إعادة التخزين',
        centerName: 'Central Depot',
        centerNameAr: 'المستودع المركزي',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );

    notifyListeners();
  }

  // Statistics (Calculated dynamically)
  int get totalActivePatients => _patients.length;
  
  double get averageBmi {
    if (_patients.isEmpty) return 0.0;
    return _patients.map((p) => p.bmi).reduce((a, b) => a + b) / _patients.length;
  }

  double get averageCompliance {
    if (_patients.isEmpty) return 0.0;
    return _patients.map((p) => p.complianceRate).reduce((a, b) => a + b) / _patients.length;
  }

  int get criticalBmiCount {
    return _patients.where((p) => p.bmi >= 35.0).length;
  }

  double get totalGovtSubsidyDisbursed {
    // Let's sum government contribution for all success logs
    // Mocking 1000 AED per dispensation * coverage rate
    double total = 0.0;
    for (var log in _logs) {
      if (log.action.startsWith('Dispense') && log.status != 'Flagged') {
        final p = _patients.firstWhere((pat) => pat.id == log.patientId, orElse: () => _patients.first);
        double rate = p.residencyStatus == ResidencyStatus.citizen ? 1.0 : (p.residencyStatus == ResidencyStatus.resident ? 0.5 : 0.0);
        total += 1000.0 * rate;
      }
    }
    // Add legacy count for realistic data
    return 42.5 * 1000000 + total;
  }

  int get fraudIncidentsPrevented {
    return _logs.where((l) => l.status == 'Flagged').length + 342; // Add base to match original kpi
  }
}
