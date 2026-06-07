import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'demo_metrics.dart';
import '../localization/locale_provider.dart';
import '../utils/dose_utils.dart';
import '../../features/treatment_plan/models/treatment_plan.dart';
import '../../features/clinical/patient_clinical_models.dart';
import '../clinical/clinical_eligibility_rules.dart' show ClinicalEligibilityRules, ProgramEligibilityResult;
import '../models/activity_log.dart';

enum ResidencyStatus { citizen, resident, visitor }

enum DispensingUiStatus {
  eligible,
  pendingCarePlan,
  pendingClinicalReview,
  approvedEarly,
  clinicalIneligible,
}

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
  /// Authorized dispensing facility that performed the latest handover ([DispensingCenter.id]).
  String? lastDispensingCenterId;
  final List<PatientDispenseRecord> dispenseRecords;
  String? nextEligibleDate;
  String currentDose;
  final double latitude;
  final double longitude;
  final String emirate;
  final String emirateAr;
  final List<double> weightHistory;
  final List<String> doseHistory;
  final double complianceRate;
  final bool hasChronicDisease;
  final List<PatientAttachment> clinicalAttachments;
  /// HbA1c % on file (e.g. 7.2). Used by rule engine — edit thresholds in [ClinicalEligibilityConfig].
  final double? hba1cPercent;
  /// Fasting glucose mg/dL on file.
  final double? fastingGlucoseMgDl;

  double get bmi => weight / ((height / 100) * (height / 100));

  ProgramEligibilityResult get programEligibility => ClinicalEligibilityRules.evaluateFields(
        bmi: bmi,
        hasChronicDisease: hasChronicDisease,
        medicalConditions: medicalConditions,
        hba1cPercent: hba1cPercent,
        fastingGlucoseMgDl: fastingGlucoseMgDl,
      );

  /// True if last dispense was within [cooldownDays] (plan refill interval).
  bool isWithinDispensingCooldown({int cooldownDays = 28}) {
    if (lastDispensingDate == null) return false;
    final parts = lastDispensingDate!.split('-');
    if (parts.length != 3) return false;
    final last = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final daysSince = today.difference(lastDay).inDays;
    return daysSince < cooldownDays;
  }

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
    this.lastDispensingCenterId,
    this.dispenseRecords = const [],
    this.nextEligibleDate,
    this.currentDose = '2.5 mg',
    required this.latitude,
    required this.longitude,
    required this.emirate,
    required this.emirateAr,
    required this.weightHistory,
    required this.doseHistory,
    required this.complianceRate,
    this.hasChronicDisease = false,
    this.clinicalAttachments = const [],
    this.hba1cPercent,
    this.fastingGlucoseMgDl,
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
    String? lastDispensingCenterId,
    List<PatientDispenseRecord>? dispenseRecords,
    bool resetDispensingFacility = false,
    String? nextEligibleDate,
    String? currentDose,
    List<double>? weightHistory,
    List<String>? doseHistory,
    bool? hasChronicDisease,
    List<PatientAttachment>? clinicalAttachments,
    double? hba1cPercent,
    double? fastingGlucoseMgDl,
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
      lastDispensingCenterId: resetDispensingFacility
          ? null
          : (lastDispensingCenterId ?? this.lastDispensingCenterId),
      dispenseRecords:
          resetDispensingFacility ? const [] : (dispenseRecords ?? this.dispenseRecords),
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      currentDose: currentDose ?? this.currentDose,
      latitude: latitude,
      longitude: longitude,
      emirate: emirate,
      emirateAr: emirateAr,
      weightHistory: weightHistory ?? this.weightHistory,
      doseHistory: doseHistory ?? this.doseHistory,
      complianceRate: complianceRate,
      hasChronicDisease: hasChronicDisease ?? this.hasChronicDisease,
      clinicalAttachments: clinicalAttachments ?? this.clinicalAttachments,
      hba1cPercent: hba1cPercent ?? this.hba1cPercent,
      fastingGlucoseMgDl: fastingGlucoseMgDl ?? this.fastingGlucoseMgDl,
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String nameAr;
  final String emirate;
  final String emirateAr;
  final String specialty;
  final String specialtyAr;
  final String hospital;
  final String hospitalAr;
  final String email;

  Doctor({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.emirate,
    required this.emirateAr,
    required this.specialty,
    required this.specialtyAr,
    required this.hospital,
    required this.hospitalAr,
    required this.email,
  });

  bool _isAr(BuildContext context) => Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

  String getLocalizedName(BuildContext context) => _isAr(context) ? nameAr : name;
  String getLocalizedEmirate(BuildContext context) => _isAr(context) ? emirateAr : emirate;
  String getLocalizedSpecialty(BuildContext context) => _isAr(context) ? specialtyAr : specialty;
  String getLocalizedHospital(BuildContext context) => _isAr(context) ? hospitalAr : hospital;
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
  static final List<Doctor> doctors = _generateInitialDoctors();
  static final List<Patient> patients = _generateInitialPatients();
  static final List<DispensingCenter> centers = _generateInitialCenters();
  static final List<PhysicalTherapyCenter> therapyCenters = _generateInitialTherapyCenters();

  static final List<TreatmentPlan> treatmentPlans = _generateInitialPlans();

  static List<Doctor> _generateInitialDoctors() {
    return [
      Doctor(
        id: 'D001',
        name: 'Dr. Sarah Jenkins',
        nameAr: 'د. سارة جينكينز',
        emirate: 'Dubai',
        emirateAr: 'دبي',
        specialty: 'Endocrinology',
        specialtyAr: 'الغدد الصماء',
        hospital: 'Dubai Central Hospital',
        hospitalAr: 'مستشفى دبي المركزي',
        email: 'sarah.j@moh.gov.ae',
      ),
      Doctor(
        id: 'D002',
        name: 'Dr. Ahmed Al Mansoori',
        nameAr: 'د. أحمد المنصوري',
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',
        specialty: 'Bariatric Medicine',
        specialtyAr: 'طب السمنة',
        hospital: 'Abu Dhabi Medical City',
        hospitalAr: 'مدينة أبوظبي الطبية',
        email: 'ahmed.m@moh.gov.ae',
      ),
      Doctor(
        id: 'D003',
        name: 'Dr. Priya Sharma',
        nameAr: 'د. بريا شارما',
        emirate: 'Sharjah',
        emirateAr: 'الشارقة',
        specialty: 'Internal Medicine',
        specialtyAr: 'الطب الباطني',
        hospital: 'Sharjah Specialty Clinic',
        hospitalAr: 'عيادة الشارقة التخصصية',
        email: 'priya.s@moh.gov.ae',
      ),
    ];
  }

  static List<TreatmentPlan> _generateInitialPlans() {
    return [
      TreatmentPlan(
        id: 'TP-001',
        patientId: 'P001',
        doctorName: 'Dr. Sarah',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        medicationDose: '5.0 mg',
        medicationFrequencyDays: 7,
        reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
        assignedCenterId: 'T001',
        totalSessions: 12,
        sessions: [
          TherapySession(id: 'S1', sessionNumber: 1, scheduledDate: DateTime.now().subtract(const Duration(days: 7)), isAttended: true, weightAfter: 104.5),
          TherapySession(id: 'S2', sessionNumber: 2, scheduledDate: DateTime.now(), isAttended: false),
          TherapySession(id: 'S3', sessionNumber: 3, scheduledDate: DateTime.now().add(const Duration(days: 7))),
        ],
        homeExercises: [
          HomeExercise(
            id: 'E1',
            name: 'Brisk Walking',
            nameAr: 'مشي سريع',
            description: 'Walk at a brisk pace.',
            descriptionAr: 'امش بخطوة سريعة.',
            category: 'Cardio',
            durationMinutes: 30,
            sets: 1,
            reps: 1,
            iconPath: 'activity',
            completedDates: [DateTime.now().subtract(const Duration(days: 1))],
          ),
        ],
        targetWeight: 85.0,
      ),
      TreatmentPlan(
        id: 'TP-002',
        patientId: 'P002',
        doctorName: 'Dr. Sarah',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        medicationDose: '7.5 mg',
        medicationFrequencyDays: 7,
        reminderTimes: const [TimeOfDay(hour: 8, minute: 0)],
        assignedCenterId: 'T002',
        totalSessions: 8,
        sessions: [
          TherapySession(id: 'S1', sessionNumber: 1, scheduledDate: DateTime.now().subtract(const Duration(days: 14)), isAttended: true, weightAfter: 88.0),
          TherapySession(id: 'S2', sessionNumber: 2, scheduledDate: DateTime.now().subtract(const Duration(days: 7)), isAttended: true, weightAfter: 87.5),
          TherapySession(id: 'S3', sessionNumber: 3, scheduledDate: DateTime.now(), isAttended: false),
        ],
        homeExercises: [
          HomeExercise(
            id: 'E2',
            name: 'Core Strengthening',
            nameAr: 'تقوية العضلات الأساسية',
            description: 'Basic core exercises like planks and crunches.',
            descriptionAr: 'تمارين أساسية مثل البلانك.',
            category: 'Strength',
            durationMinutes: 15,
            sets: 3,
            reps: 10,
            iconPath: 'activity',
            completedDates: [DateTime.now().subtract(const Duration(days: 2))],
          ),
        ],
        targetWeight: 75.0,
      ),
      TreatmentPlan(
        id: 'TP-003',
        patientId: 'P003',
        doctorName: 'Dr. Ahmed',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        medicationDose: '2.5 mg',
        medicationFrequencyDays: 7,
        reminderTimes: const [TimeOfDay(hour: 10, minute: 0)],
        assignedCenterId: 'T001',
        totalSessions: 16,
        sessions: [
          TherapySession(id: 'S1', sessionNumber: 1, scheduledDate: DateTime.now().add(const Duration(days: 2)), isAttended: false),
        ],
        homeExercises: [
          HomeExercise(
            id: 'E3',
            name: 'Light Yoga',
            nameAr: 'يوجا خفيفة',
            description: 'Basic stretching and yoga poses.',
            descriptionAr: 'تمارين تمدد ويوجا بسيطة.',
            category: 'Flexibility',
            durationMinutes: 20,
            sets: 1,
            reps: 1,
            iconPath: 'activity',
            completedDates: [],
          ),
        ],
        targetWeight: 90.0,
      ),
    ];
  }


  static List<PhysicalTherapyCenter> _generateInitialTherapyCenters() {
    return [
      PhysicalTherapyCenter(
        id: 'T001',
        name: 'Al Mafraq Physical Therapy & Rehab',
        nameAr: 'المفرق للعلاج الطبيعي والتأهيل',
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',

        latitude: 24.3330,
        longitude: 54.5390,
        phone: '+971 2 699 1111',
        activePatients: 45,
        
        chiefTherapist: 'Dr. Salem Al-Harthi',
        chiefTherapistAr: 'د. سالم الحارثي',
        services: ['Obesity Rehab', 'Cardio Conditioning', 'Post-Bariatric Training'],
        servicesAr: ['تأهيل السمنة', 'التكييف القلبي', 'تدريب ما بعد جراحة السمنة'],

        workingHours: '08:00 AM - 08:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T007',
        name: 'Sheikh Shakhbout Medical City Rehab',
        nameAr: 'مدينة الشيخ شخبوط الطبية — التأهيل',
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',
        latitude: 24.4520,
        longitude: 54.3650,
        phone: '+971 2 819 2000',
        activePatients: 52,
        chiefTherapist: 'Dr. Noura Al Ketbi',
        chiefTherapistAr: 'د. نورة الكتبي',
        services: ['Obesity Rehab', 'Hydrotherapy', 'Mobility Therapy'],
        servicesAr: ['تأهيل السمنة', 'العلاج المائي', 'علاج الحركة'],
        workingHours: '07:00 AM - 09:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T008',
        name: 'Burjeel Hospital PT & Wellness',
        nameAr: 'مستشفى برجيل — العلاج الطبيعي',
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',
        latitude: 24.4860,
        longitude: 54.3720,
        phone: '+971 2 508 5555',
        activePatients: 41,
        chiefTherapist: 'Dr. James Okonkwo',
        chiefTherapistAr: 'د. جيمس أوكونكو',
        services: ['Post-Bariatric Training', 'Cardio Conditioning'],
        servicesAr: ['تدريب ما بعد جراحة السمنة', 'التكييف القلبي'],
        workingHours: '08:00 AM - 08:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T009',
        name: 'Reem Island Rehabilitation Hub',
        nameAr: 'مركز تأهيل جزيرة الريم',
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',
        latitude: 24.4950,
        longitude: 54.3950,
        phone: '+971 2 491 3300',
        activePatients: 36,
        chiefTherapist: 'Dr. Layla Al Mansoori',
        chiefTherapistAr: 'د. ليلى المنصوري',
        services: ['Therapeutic Exercises', 'Weight Loss Training'],
        servicesAr: ['تمارين علاجية', 'تدريب فقدان الوزن'],
        workingHours: '09:00 AM - 07:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T002',
        name: 'Rashid Bariatric Rehab & PT Center',
        nameAr: 'مركز راشد لتأهيل السمنة والعلاج الطبيعي',
        emirate: 'Dubai',
        emirateAr: 'دبي',

        latitude: 25.2048,
        longitude: 55.2708,
        phone: '+971 4 399 2222',
        activePatients: 72,
        
        chiefTherapist: 'Dr. Sarah Jenkins (PT)',
        chiefTherapistAr: 'د. سارة جينكينز',
        services: ['Kinesiotherapy', 'Body Contouring Rehab', 'Post-Surgical Exercise'],
        servicesAr: ['العلاج الحركي', 'تأهيل نحت الجسم', 'تمارين ما بعد الجراحة'],

        workingHours: '08:00 AM - 09:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T010',
        name: 'Dubai Healthcare City Rehab Unit',
        nameAr: 'مدينة دبي الطبية — وحدة التأهيل',
        emirate: 'Dubai',
        emirateAr: 'دبي',
        latitude: 25.2340,
        longitude: 55.3040,
        phone: '+971 4 375 1900',
        activePatients: 58,
        chiefTherapist: 'Dr. Priya Sharma',
        chiefTherapistAr: 'د. بريا شارما',
        services: ['Kinesiotherapy', 'Obesity Rehab'],
        servicesAr: ['العلاج الحركي', 'تأهيل السمنة'],
        workingHours: '08:00 AM - 08:00 PM',
      ),
      PhysicalTherapyCenter(
        id: 'T011',
        name: 'Al Barsha Medical Fitness Center',
        nameAr: 'مركز البرشاء الطبي لللياقة',
        emirate: 'Dubai',
        emirateAr: 'دبي',
        latitude: 25.1120,
        longitude: 55.1950,
        phone: '+971 4 295 8800',
        activePatients: 44,
        chiefTherapist: 'Dr. Omar Al Suwaidi',
        chiefTherapistAr: 'د. عمر السويدي',
        services: ['Body Contouring Rehab', 'Muscle Strength Conditioning'],
        servicesAr: ['تأهيل نحت الجسم', 'تكييف قوة العضلات'],
        workingHours: '07:30 AM - 09:30 PM',
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
      'Hassan Ibrahim', 'Mahmoud Ali', 'Yasser Saeed', 'Kareem Abdelrahman', 'Tariq Hussein',
      'Ziad Khoury', 'Marwan Haddad', 'Wael Nasser', 'Fares Mansour', 'Ramy Abboud',
      'Assi El Zein', 'Melhem Karam', 'Saber Rebai', 'George Saliba', 'Kazem Al Ali',
      'Majid Al Mohandis', 'Rashed Al Majed', 'Abdul Majeed', 'Hussein Al Jasmi', 'Fahad Al Kubaisi',
      'Nabeel Shuail', 'Abdullah Al Ruwaished', 'Mohammed Abdu', 'Talal Maddah', 'Ayman Zidan',
      'Bassam Kousa', 'Jamal Suliman', 'Tim Hassan', 'Samer Al Masri', 'Qusai Khouli'
    ];
    final List<String> maleNamesAr = [
      'أحمد المنصوري', 'خالد الهاشمي', 'زايد آل نهيان', 'سلطان القاسمي',
      'راشد النعيمي', 'فيصل الكتبي', 'حميد الشامسي', 'محمد الفلاسي',
      'سعيد آل مكتوم', 'عمر السويدي', 'طارق الجابر', 'حمدان الكعبي',
      'يوسف الشحي', 'عدنان المزروعي', 'سيف الهاملي', 'ماجد الغرير',
      'علي النابودة', 'مروان الطاير', 'سالم الصايغ', 'وليد القرق',
      'حسن إبراهيم', 'محمود علي', 'ياسر سعيد', 'كريم عبدالرحمن', 'طارق حسين',
      'زياد خوري', 'مروان حداد', 'وائل ناصر', 'فارس منصور', 'رامي عبود',
      'عاصي الزين', 'ملحم كرم', 'صابر الرباعي', 'جورج صليبا', 'كاظم العلي',
      'ماجد المهندس', 'راشد الماجد', 'عبدالمجيد', 'حسين الجسمي', 'فهد الكبيسي',
      'نبيل شعيل', 'عبدالله الرويشد', 'محمد عبده', 'طلال مداح', 'أيمن زيدان',
      'بسام كوسا', 'جمال سليمان', 'تيم حسن', 'سامر المصري', 'قصي خولي'
    ];

    final List<String> femaleNames = [
      'Sarah Yousef', 'Fatima Al Qasimi', 'Mariam Al Kaabi', 'Shamma Al Maktoum',
      'Amna Al Shehhi', 'Reem Al Hashimi', 'Maitha Al Falasi', 'Latifa Al Maktoum',
      'Muna Al Shamsi', 'Hessa Al Suwaidi', 'Aisha Al Jaber', 'Noora Al Mansoori',
      'Salama Al Ketbi', 'Hind Al Mazrouei', 'Jawahir Al Qasimi', 'Rawda Al Hameli',
      'Shaikha Al Tayer', 'Moza Al Naboodah', 'Alia Al Sayegh', 'Budoor Al Gurg',
      'Laila Ali', 'Mona Zaki', 'Hend Rostom', 'Faten Hamama', 'Soad Hosny',
      'Nadia Lutfi', 'Shadia', 'Sabah', 'Fayrouz', 'Umm Kulthum',
      'Nancy Ajram', 'Elissa', 'Haifa Wehbe', 'Najwa Karam', 'Nawal El Zoghbi',
      'Diana Haddad', 'Carole Samaha', 'Myriam Fares', 'Yara', 'Maya Diab',
      'Assala Nasri', 'Sherine Abdel Wahab', 'Angham', 'Samira Said', 'Latifa',
      'Ahlam', 'Nawal Al Kuwaitia', 'Balqees', 'Dalia', 'Youssra'
    ];
    final List<String> femaleNamesAr = [
      'سارة يوسف', 'فاطمة القاسمي', 'مريم الكعبي', 'شمة آل مكتوم',
      'آمنة الشحي', 'ريم الهاشمي', 'ميثاء الفلاسي', 'لطيفة آل مكتوم',
      'منى الشامسي', 'حصة السويدي', 'عائشة الجابر', 'نورة المنصوري',
      'سلامة الكتبي', 'هند المزروعي', 'جواهر القاسمي', 'روضة الهاملي',
      'شيخة الطاير', 'موزة النابودة', 'عليا الصايغ', 'بدور القرق',
      'ليلى علي', 'منى زكي', 'هند رستم', 'فاتن حمامة', 'سعاد حسني',
      'نادية لطفي', 'شادية', 'صباح', 'فيروز', 'أم كلثوم',
      'نانسي عجرم', 'إليسا', 'هيفاء وهبي', 'نجوى كرم', 'نوال الزغبي',
      'ديانا حداد', 'كارول سماحة', 'ميريام فارس', 'يارا', 'مايا دياب',
      'أصالة نصري', 'شيرين عبدالوهاب', 'أنغام', 'سميرة سعيد', 'لطيفة',
      'أحلام', 'نوال الكويتية', 'بلقيس', 'داليا', 'يسرا'
    ];

    final List<String> nationalities = [
      'United Arab Emirates', 'Egypt', 'Saudi Arabia', 'Jordan', 'Lebanon',
      'Syria', 'Palestine', 'Oman', 'Kuwait', 'Bahrain', 'Qatar',
      'Morocco', 'Algeria', 'Tunisia', 'Sudan'
    ];
    final List<String> nationalitiesAr = [
      'الإمارات العربية المتحدة', 'مصر', 'المملكة العربية السعودية', 'الأردن', 'لبنان',
      'سوريا', 'فلسطين', 'عمان', 'الكويت', 'البحرين', 'قطر',
      'المغرب', 'الجزائر', 'تونس', 'السودان'
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
        hasChronicDisease: true,
        hba1cPercent: 6.8,
        fastingGlucoseMgDl: 118,
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
        fullName: 'Sarah Yousef',
        fullNameAr: 'سارة يوسف',
        nationality: 'Egypt',
        nationalityAr: 'مصر',
        residencyStatus: ResidencyStatus.resident,
        age: 34,
        gender: 'Female',
        genderAr: 'أنثى',
        weight: 92.0,
        height: 165.0,
        medicalConditions: ['Obesity', 'PCOS'],
        medicalConditionsAr: ['السمنة', 'تكيس المبايض'],
        hasChronicDisease: true,
        hba1cPercent: 9.4,
        fastingGlucoseMgDl: 212,
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
        fullName: 'Mahmoud Ibrahim',
        fullNameAr: 'محمود إبراهيم',
        nationality: 'Jordan',
        nationalityAr: 'الأردن',
        residencyStatus: ResidencyStatus.resident,
        age: 41,
        gender: 'Male',
        genderAr: 'ذكر',
        weight: 115.0,
        height: 180.0,
        medicalConditions: ['Obesity'],
        medicalConditionsAr: ['السمنة'],
        hasChronicDisease: false,
        hba1cPercent: 5.6,
        fastingGlucoseMgDl: 95,
        lastDispensingDate: null,
        nextEligibleDate: 'Eligible Now',
        currentDose: '2.5 mg',
        latitude: 25.3463,
        longitude: 55.4209,
        emirate: 'Sharjah',
        emirateAr: 'الشارقة',
        weightHistory: [118.0, 116.5, 115.0],
        doseHistory: [],
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

    int maleIndex = 0;
    int femaleIndex = 0;

    for (int i = 6; i <= 50; i++) {
      final gender = rand.nextBool() ? 'Male' : 'Female';
      String name, nameAr;
      
      if (gender == 'Male') {
        name = maleNames[maleIndex % maleNames.length];
        nameAr = maleNamesAr[maleIndex % maleNamesAr.length];
        maleIndex++;
      } else {
        name = femaleNames[femaleIndex % femaleNames.length];
        nameAr = femaleNamesAr[femaleIndex % femaleNamesAr.length];
        femaleIndex++;
      }
      
      final uniqueName = name;
      final uniqueNameAr = nameAr;
      
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
        nextDispDate = '2026-0$nextMonth-${day < 10 ? "0$day" : day}';
      }

      final currentDose = ['2.5 mg', '5 mg', '7.5 mg', '10 mg'][rand.nextInt(4)];
      final doseHist = <String>[];
      if (lastDispDate != null) {
        final dispenseCount = 1 + rand.nextInt(3);
        for (int d = 0; d < dispenseCount; d++) {
          if (d < 2) {
            doseHist.add('2.5 mg');
          } else if (d < 3) {
            doseHist.add('5 mg');
          } else {
            doseHist.add(currentDose);
          }
        }
        if (doseHist.isEmpty) {
          doseHist.add(currentDose);
        } else {
          doseHist[doseHist.length - 1] = currentDose;
        }
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
          currentDose: currentDose,
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
  late List<Doctor> _doctors;
  late List<Patient> _patients;
  late List<DispensingCenter> _centers;
  late List<PhysicalTherapyCenter> _therapyCenters;
  final List<ActivityLog> _logs = [];

  DataProvider() {
    _doctors = List.from(MockData.doctors);
    _patients = List.from(MockData.patients);
    
    // Inject a hardcoded "Clinical Ineffective" patient for demo purposes
    _patients.insert(0, Patient(
      id: 'P999',
      emiratesId: '784-1990-1234567-1',
      fullName: 'Ahmed Al Mansoori',
      fullNameAr: 'أحمد المنصوري',
      nationality: 'Emirati',
      nationalityAr: 'إماراتي',
      residencyStatus: ResidencyStatus.citizen,
      age: 45,
      gender: 'Male',
      genderAr: 'ذكر',
      weight: 120.0,
      height: 175.0,
      medicalConditions: ['Type 2 Diabetes'],
      medicalConditionsAr: ['النوع الثاني من السكري'],
      lastDispensingDate: '2026-05-15',
      nextEligibleDate: '2026-06-15',
      currentDose: '10 mg',
      latitude: 25.2048,
      longitude: 55.2708,
      emirate: 'Dubai',
      emirateAr: 'دبي',
      weightHistory: [120.5, 120.2, 120.0],
      doseHistory: ['5 mg', '7.5 mg', '10 mg'],
      complianceRate: 0.95,
      hasChronicDisease: true,
      clinicalAttachments: [],
      hba1cPercent: 8.5,
      fastingGlucoseMgDl: 160.0,
    ));
    _centers = List.from(MockData.centers);
    _therapyCenters = List.from(MockData.therapyCenters);
    
    _reconcilePatientDispenseRecords();
    _assignDispenseFacilities();
    _seedActivityLogs();
  }

  /// Keeps lastDispensingDate, doseHistory, facility, and activity logs aligned.
  void _reconcilePatientDispenseRecords() {
    for (var i = 0; i < _patients.length; i++) {
      final p = _patients[i];
      if (p.lastDispensingDate == null) {
        if (p.doseHistory.isNotEmpty ||
            p.dispenseRecords.isNotEmpty ||
            p.lastDispensingCenterId != null) {
          _patients[i] = p.copyWith(
            doseHistory: [],
            resetDispensingFacility: true,
          );
        }
      } else if (p.doseHistory.isEmpty) {
        _patients[i] = p.copyWith(doseHistory: [p.currentDose]);
      }
    }
  }

  void _assignDispenseFacilities() {
    if (_centers.isEmpty) return;
    for (var i = 0; i < _patients.length; i++) {
      final p = _patients[i];
      if (p.lastDispensingDate == null) continue;
      final center = _centers[i % _centers.length];
      _patients[i] = p.copyWith(
        lastDispensingCenterId: center.id,
        dispenseRecords: _buildDispenseRecordsFromHistory(p, center.id),
      );
    }
  }

  List<PatientDispenseRecord> _buildDispenseRecordsFromHistory(Patient p, String centerId) {
    if (p.lastDispensingDate == null) return const [];
    final doses = p.doseHistory.isNotEmpty ? p.doseHistory : [p.currentDose];
    final last = _parseDateString(p.lastDispensingDate!);
    if (last == null) {
      return [
        PatientDispenseRecord(
          date: p.lastDispensingDate!,
          dose: doses.last,
          centerId: centerId,
        ),
      ];
    }
    final records = <PatientDispenseRecord>[];
    for (var i = 0; i < doses.length; i++) {
      final doseIdx = doses.length - 1 - i;
      final day = last.subtract(Duration(days: 28 * i));
      records.insert(
        0,
        PatientDispenseRecord(
          date: _formatDate(day),
          dose: doses[doseIdx],
          centerId: centerId,
        ),
      );
    }
    return records;
  }

  List<Doctor> get doctors => _doctors;
  List<Patient> get patients => _patients;
  List<DispensingCenter> get centers => _centers;
  List<PhysicalTherapyCenter> get therapyCenters => _therapyCenters;

  final List<TreatmentPlan> _treatmentPlans = MockData.treatmentPlans;
  List<TreatmentPlan> get treatmentPlans => _treatmentPlans;
  List<ActivityLog> get logs => List.unmodifiable(_logs);

  /// Flagged / overridden events for misuse prevention log and fraud alerts.
  List<ActivityLog> get misusePreventionLogs =>
      List.unmodifiable(_logs.where((l) => l.status == 'Flagged' || l.status == 'Overridden'));

  /// Doctor-approved early dispensing before the refill interval ends.
  final Set<String> _dispenseAuthorizations = {};
  final Set<String> _earlyDispenseReviewQueue = {};

  static DateTime? _parseDateString(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d, 10, 30);
  }

  void _seedActivityLogs() {
    int logIdx = 1;

    // One dispensing log per beneficiary — timestamp matches lastDispensingDate on file.
    for (final p in _patients) {
      if (p.lastDispensingDate == null) continue;
      final ts = _parseDateString(p.lastDispensingDate!);
      if (ts == null) continue;
      final dose = p.doseHistory.isNotEmpty ? p.doseHistory.last : p.currentDose;
      final center = getDispensingCenterById(p.lastDispensingCenterId) ?? _centers.first;
      _logs.add(
        ActivityLog.dispense(
          id: 'LOG${logIdx.toString().padLeft(3, '0')}',
          patient: PatientRef(id: p.id, name: p.fullName, nameAr: p.fullNameAr),
          dose: dose,
          center: CenterRef(name: center.name, nameAr: center.nameAr),
          timestamp: ts,
        ),
      );
      logIdx++;
    }

    // Care-plan events (non-dispensing) for demo narrative.
    for (final plan in _treatmentPlans) {
      final p = getPatientById(plan.patientId);
      if (p == null) continue;
      _logs.add(
        ActivityLog.carePlan(
          id: 'LOG${logIdx.toString().padLeft(3, '0')}',
          patient: PatientRef(id: p.id, name: p.fullName, nameAr: p.fullNameAr),
          dose: plan.medicationDose,
          intervalDays: plan.medicationFrequencyDays,
          timestamp: plan.createdAt,
          pendingReview: plan.clinicalApprovalStatus == 'pending_review',
        ),
      );
      logIdx++;
    }

    _seedMisusePreventionLogs(logIdx);

    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _seedMisusePreventionLogs(int startIdx) {
    var logIdx = startIdx;
    final anchor = DateTime(2026, 6, 6, 11, 0);

    void add({
      required Patient p,
      required DispensingCenter c,
      required String reason,
      required String reasonAr,
      required bool overridden,
      required int hoursAgo,
    }) {
      _logs.add(
        ActivityLog.misusePrevented(
          id: 'LOG${logIdx.toString().padLeft(3, '0')}',
          patient: PatientRef(id: p.id, name: p.fullName, nameAr: p.fullNameAr),
          center: CenterRef(name: c.name, nameAr: c.nameAr),
          reason: reason,
          reasonAr: reasonAr,
          timestamp: anchor.subtract(Duration(hours: hoursAgo)),
          overridden: overridden,
        ),
      );
      logIdx++;
    }

    Patient? p(String id) => getPatientById(id);
    DispensingCenter? c(String id) {
      for (final center in _centers) {
        if (center.id == id) return center;
      }
      return _centers.isNotEmpty ? _centers.first : null;
    }

    final ahmed = p('P001');
    final sarah = p('P002');
    final fatima = p('P004');
    final rashid = p('P005');
    final dubai = c('C001');
    final abuDhabi = c('C002');
    final sharjah = c('C003');

    if (sarah != null && dubai != null) {
      add(
        p: sarah,
        c: dubai,
        reason: 'Duplicate dispense within 28-day refill window',
        reasonAr: 'محاولة صرف مكررة خلال فترة الاستحقاق 28 يوماً',
        overridden: false,
        hoursAgo: 2,
      );
    }
    if (ahmed != null && abuDhabi != null) {
      add(
        p: ahmed,
        c: abuDhabi,
        reason: 'Emirates ID mismatch at dispensing terminal',
        reasonAr: 'عدم تطابق الهوية الإماراتية عند نقطة الصرف',
        overridden: false,
        hoursAgo: 5,
      );
    }
    if (fatima != null && abuDhabi != null) {
      add(
        p: fatima,
        c: abuDhabi,
        reason: 'Early refill without physician authorization',
        reasonAr: 'صرف مبكر بدون اعتماد الطبيب',
        overridden: true,
        hoursAgo: 8,
      );
    }
    if (rashid != null && sharjah != null) {
      add(
        p: rashid,
        c: sharjah,
        reason: 'Second facility dispense attempt same day',
        reasonAr: 'محاولة صرف من منشأة ثانية في نفس اليوم',
        overridden: false,
        hoursAgo: 14,
      );
    }
    if (sarah != null && dubai != null) {
      add(
        p: sarah,
        c: dubai,
        reason: 'Prescription dose escalation without care plan update',
        reasonAr: 'رفع الجرعة بدون تحديث خطة الرعاية',
        overridden: false,
        hoursAgo: 20,
      );
    }
    if (ahmed != null && dubai != null) {
      add(
        p: ahmed,
        c: dubai,
        reason: 'Supervisor override after verified missed appointment',
        reasonAr: 'تجاوز مشرف بعد تأكيد موعد فائت موثّق',
        overridden: true,
        hoursAgo: 26,
      );
    }
    if (fatima != null && sharjah != null) {
      add(
        p: fatima,
        c: sharjah,
        reason: 'Biometric verification failed twice',
        reasonAr: 'فشل التحقق البيومتري مرتين',
        overridden: false,
        hoursAgo: 32,
      );
    }
    if (rashid != null && dubai != null) {
      add(
        p: rashid,
        c: dubai,
        reason: 'Pharmacist account flagged for unusual override pattern',
        reasonAr: 'حساب صيدلي مُبلّغ عن نمط تجاوز غير اعتيادي',
        overridden: false,
        hoursAgo: 40,
      );
    }

    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Business Operations
  
  /// Days between dispensings: from active care plan, else 30.
  int dispensingIntervalDaysFor(String patientId) {
    return getPlanForPatient(patientId)?.medicationFrequencyDays ?? 30;
  }

  bool isPatientInDispensingCooldown(Patient patient) {
    return patient.isWithinDispensingCooldown(
      cooldownDays: dispensingIntervalDaysFor(patient.id),
    );
  }

  bool patientHasPriorDispense(String patientId) {
    final p = getPatientById(patientId);
    return p?.lastDispensingDate != null;
  }

  bool isCarePlanPendingReview(String patientId) {
    final plan = getPlanForPatient(patientId);
    return plan?.clinicalApprovalStatus == 'pending_review';
  }

  /// Beneficiaries who may receive medication now (eligible + plan approved + interval met or authorized).
  int countPatientsReadyToDispense() =>
      _patients.where((p) => canDispensePatient(p)).length;

  bool canDispensePatient(Patient patient) {
    if (!patient.programEligibility.eligible) return false;
    if (isCarePlanPendingReview(patient.id)) return false;
    if (!isPatientInDispensingCooldown(patient)) return true;
    return _dispenseAuthorizations.contains(patient.id);
  }

  DispensingUiStatus dispensingUiStatus(Patient patient) {
    if (!patient.programEligibility.eligible) {
      return DispensingUiStatus.clinicalIneligible;
    }
    if (isCarePlanPendingReview(patient.id)) {
      return DispensingUiStatus.pendingCarePlan;
    }
    if (!isPatientInDispensingCooldown(patient)) {
      return DispensingUiStatus.eligible;
    }
    if (_dispenseAuthorizations.contains(patient.id)) {
      return DispensingUiStatus.approvedEarly;
    }
    return DispensingUiStatus.pendingClinicalReview;
  }

  void ensureEarlyDispenseReviewQueued(String patientId) {
    final p = getPatientById(patientId);
    if (p == null) return;
    if (!isPatientInDispensingCooldown(p)) return;
    if (_dispenseAuthorizations.contains(patientId)) return;
    if (isCarePlanPendingReview(patientId)) return;
    if (_earlyDispenseReviewQueue.add(patientId)) {
      notifyListeners();
    }
  }

  List<({Patient patient, String reviewType})> get pendingClinicalReviews {
    final seen = <String>{};
    final out = <({Patient patient, String reviewType})>[];

    for (final plan in _treatmentPlans) {
      if (plan.clinicalApprovalStatus != 'pending_review') continue;
      final p = getPatientById(plan.patientId);
      if (p == null || seen.contains(p.id)) continue;
      seen.add(p.id);
      out.add((patient: p, reviewType: 'care_plan'));
    }

    for (final id in _earlyDispenseReviewQueue) {
      if (seen.contains(id) || _dispenseAuthorizations.contains(id)) continue;
      final p = getPatientById(id);
      if (p == null) continue;
      seen.add(id);
      out.add((patient: p, reviewType: 'early_dispense'));
    }
    return out;
  }

  void approveClinicalReview(String patientId) {
    for (var i = 0; i < _treatmentPlans.length; i++) {
      if (_treatmentPlans[i].patientId == patientId &&
          _treatmentPlans[i].clinicalApprovalStatus == 'pending_review') {
        _treatmentPlans[i] = _treatmentPlans[i].copyWith(clinicalApprovalStatus: 'approved');
      }
    }
    _dispenseAuthorizations.add(patientId);
    _earlyDispenseReviewQueue.remove(patientId);

    final p = getPatientById(patientId);
    if (p != null) {
      _logs.insert(
        0,
        ActivityLog.clinicalReviewApproved(
          id: 'LOG${_logs.length + 1}',
          patient: PatientRef(id: p.id, name: p.fullName, nameAr: p.fullNameAr),
          timestamp: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  static String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static String _nextEligibleAfter(DateTime from, int days) =>
      _formatDate(from.add(Duration(days: days)));

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
    final plan = getPlanForPatient(patientId);
    final intervalDays = plan?.medicationFrequencyDays ?? 30;
    final doseToDispense = DoseUtils.toInventoryDose(plan?.medicationDose ?? dose);

    // Check inventory
    bool hasInventory = false;
    int inv25 = c.inventory2_5mg;
    int inv5 = c.inventory5mg;
    int inv75 = c.inventory7_5mg;
    int inv10 = c.inventory10mg;
    int disp25 = c.dispensed2_5mg;
    int disp5 = c.dispensed5mg;
    int disp75 = c.dispensed7_5mg;
    int disp10 = c.dispensed10mg;

    if (doseToDispense == '2.5 mg' && inv25 > 0) {
      inv25--;
      disp25++;
      hasInventory = true;
    } else if (doseToDispense == '5 mg' && inv5 > 0) {
      inv5--;
      disp5++;
      hasInventory = true;
    } else if (doseToDispense == '7.5 mg' && inv75 > 0) {
      inv75--;
      disp75++;
      hasInventory = true;
    } else if (doseToDispense == '10 mg' && inv10 > 0) {
      inv10--;
      disp10++;
      hasInventory = true;
    }

    if (!hasInventory) return false;

    _centers[centerIndex] = c.copyWith(
      inventory2_5mg: inv25,
      inventory5mg: inv5,
      inventory7_5mg: inv75,
      inventory10mg: inv10,
      dispensed2_5mg: disp25,
      dispensed5mg: disp5,
      dispensed7_5mg: disp75,
      dispensed10mg: disp10,
    );

    final now = DateTime.now();
    final nowStr = _formatDate(now);
    final nextStr = _nextEligibleAfter(now, intervalDays);
    final updatedDoseHistory = List<String>.from(p.doseHistory)..add(doseToDispense);

    final newRecord = PatientDispenseRecord(
      date: nowStr,
      dose: doseToDispense,
      centerId: centerId,
    );
    _patients[patientIndex] = p.copyWith(
      lastDispensingDate: nowStr,
      lastDispensingCenterId: centerId,
      nextEligibleDate: nextStr,
      currentDose: doseToDispense,
      doseHistory: updatedDoseHistory,
      dispenseRecords: [...p.dispenseRecords, newRecord],
    );

    // Add activity log
    _dispenseAuthorizations.remove(patientId);
    _earlyDispenseReviewQueue.remove(patientId);

    _logs.insert(
      0,
      ActivityLog.dispense(
        id: 'LOG${_logs.length + 1}',
        patient: PatientRef(id: p.id, name: p.fullName, nameAr: p.fullNameAr),
        dose: doseToDispense,
        center: CenterRef(name: c.name, nameAr: c.nameAr),
        timestamp: DateTime.now(),
        isOverride: isOverride,
      ),
    );

    notifyListeners();
    return true;
  }

  // Replenish inventory for a center
  void replenishInventory(String centerId, String dose, int amount) {
    final centerIndex = _centers.indexWhere((c) => c.id == centerId);
    if (centerIndex == -1) return;

    final c = _centers[centerIndex];
    int inv25 = c.inventory2_5mg;
    int inv5 = c.inventory5mg;
    int inv75 = c.inventory7_5mg;
    int inv10 = c.inventory10mg;

    if (dose == '2.5 mg') {
      inv25 += amount;
    } else if (dose == '5 mg' || dose == '5.0 mg') {
      inv5 += amount;
    } else if (dose == '7.5 mg') {
      inv75 += amount;
    } else if (dose == '10 mg' || dose == '10.0 mg') {
      inv10 += amount;
    }

    _centers[centerIndex] = c.copyWith(
      inventory2_5mg: inv25,
      inventory5mg: inv5,
      inventory7_5mg: inv75,
      inventory10mg: inv10,
    );

    _logs.insert(
      0,
      ActivityLog.inventoryReplenish(
        id: 'LOG${_logs.length + 1}',
        centerName: c.name,
        centerNameAr: c.nameAr,
        dose: dose,
        amount: amount,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
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
        id: 'LOG${_logs.length + 1}',
        patientName: p.fullName,
        patientNameAr: p.fullNameAr,
        patientId: p.id,
        eventType: ActivityEventType.weightUpdate,
        action: 'Weight updated · ${newWeight.toStringAsFixed(1)} kg',
        actionAr: 'تحديث وزن · ${newWeight.toStringAsFixed(1)} كغ',
        centerName: 'Physician Portal',
        centerNameAr: 'بوابة الطبيب المعالج',
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

    final doseLabel = DoseUtils.toInventoryDose(newDose);
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: p.fullName,
        patientNameAr: p.fullNameAr,
        patientId: p.id,
        eventType: ActivityEventType.doseChange,
        action: 'Dose changed · $doseLabel',
        actionAr: 'تعديل جرعة · $doseLabel',
        centerName: 'Physician Portal',
        centerNameAr: 'بوابة الطبيب المعالج',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );

    notifyListeners();
  }

  String generateNextPatientId() {
    final nums = _patients
        .map((p) => int.tryParse(p.id.replaceAll(RegExp(r'[^0-9]'), '')))
        .whereType<int>();
    final next = (nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b)) + 1;
    return 'P${next.toString().padLeft(3, '0')}';
  }

  // Add new Patient
  void registerPatient(Patient newPatient) {
    _patients.add(newPatient);

    final chronicNote = newPatient.hasChronicDisease
        ? 'Chronic disease: yes'
        : 'Chronic disease: no';
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: newPatient.fullName,
        patientNameAr: newPatient.fullNameAr,
        patientId: newPatient.id,
        eventType: ActivityEventType.registration,
        action: 'Beneficiary registered · $chronicNote',
        actionAr: newPatient.hasChronicDisease
            ? 'تسجيل مستفيد · أمراض مزمنة: نعم'
            : 'تسجيل مستفيد · أمراض مزمنة: لا',
        centerName: 'Physician Portal',
        centerNameAr: 'بوابة الطبيب المعالج',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );

    for (final doc in newPatient.clinicalAttachments) {
      _logs.insert(
        0,
        ActivityLog(
          id: 'LOG${_logs.length + 1}',
          patientName: newPatient.fullName,
          patientNameAr: newPatient.fullNameAr,
          patientId: newPatient.id,
          eventType: ActivityEventType.documentUpload,
          action: 'Lab document uploaded · ${doc.fileName}',
          actionAr: 'رفع مستند · ${doc.fileName}',
          centerName: 'Physician Portal',
          centerNameAr: 'بوابة الطبيب المعالج',
          timestamp: doc.uploadedAt,
          status: 'Success',
          statusAr: 'ناجح',
        ),
      );
    }

    notifyListeners();
  }

  // Add new Doctor
  void addDoctor(Doctor doctor) {
    _doctors.add(doctor);
    _logs.insert(
      0,
      ActivityLog.adminAction(
        id: 'LOG${_logs.length + 1}',
        actionDesc: 'Added new physician: ${doctor.name}',
        actionDescAr: 'تمت إضافة طبيب جديد: ${doctor.name}',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // Add new Physical Therapy Center
  void addPhysicalTherapyCenter(PhysicalTherapyCenter center) {
    _therapyCenters.add(center);
    notifyListeners();
  }

  // Add new Dispensing Center
  void addDispensingCenter(DispensingCenter center) {
    _centers.add(center);
    _logs.insert(
      0,
      ActivityLog.adminAction(
        id: 'LOG${_logs.length + 1}',
        actionDesc: 'Added new dispensing center: ${center.name}',
        actionDescAr: 'تمت إضافة منفذ صرف جديد: ${center.nameAr}',
        timestamp: DateTime.now(),
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
        id: 'LOG${_logs.length + 1}',
        patientName: 'System Inventory',
        patientNameAr: 'جرد النظام',
        patientId: 'SYS',
        eventType: ActivityEventType.inventoryReplenish,
        action: 'Inventory restocked · ${c.name}',
        actionAr: 'إعادة تخزين · ${c.nameAr}',
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
      if (log.eventType == ActivityEventType.dispense && log.status != 'Flagged') {
        final p = _patients.firstWhere((pat) => pat.id == log.patientId, orElse: () => _patients.first);
        double rate = p.residencyStatus == ResidencyStatus.citizen ? 1.0 : (p.residencyStatus == ResidencyStatus.resident ? 0.5 : 0.0);
        total += 1000.0 * rate;
      }
    }
    // Add legacy count for realistic data
    return 42.5 * 1000000 + total;
  }

  int get fraudIncidentsPrevented {
    return _logs.where((l) => l.status == 'Flagged' || l.status == 'Overridden').length +
        DemoMetrics.nationalFraudPreventedBase;
  }

  double get nationalAverageBmiDrop {
    if (_patients.isEmpty) return 0;
    final current = averageBmi;
    return (DemoMetrics.baselineNationalBmi - current).clamp(0, 10);
  }

  double get obesityIndexReductionPercent {
    if (DemoMetrics.baselineNationalBmi <= 0) return 0;
    return ((DemoMetrics.baselineNationalBmi - averageBmi) / DemoMetrics.baselineNationalBmi * 100)
        .clamp(0, 100);
  }

  void createTreatmentPlan(TreatmentPlan plan) {
    final patientIndex = _patients.indexWhere((p) => p.id == plan.patientId);
    if (patientIndex == -1) return;

    final p = _patients[patientIndex];
    final needsReview = p.lastDispensingDate != null &&
        p.isWithinDispensingCooldown(cooldownDays: plan.medicationFrequencyDays);
    final planToSave = plan.copyWith(
      clinicalApprovalStatus: needsReview ? 'pending_review' : 'approved',
    );

    _treatmentPlans.removeWhere((tp) => tp.patientId == plan.patientId);
    _treatmentPlans.add(planToSave);
    if (needsReview) {
      _dispenseAuthorizations.remove(plan.patientId);
      _earlyDispenseReviewQueue.remove(plan.patientId);
    }

    final dose = DoseUtils.toInventoryDose(planToSave.medicationDose);
    final String nextEligible;
    if (p.lastDispensingDate == null) {
      nextEligible = 'Eligible Now';
    } else {
      final parts = p.lastDispensingDate!.split('-');
      if (parts.length == 3) {
        final last = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        nextEligible = _nextEligibleAfter(last, planToSave.medicationFrequencyDays);
      } else {
        nextEligible = _nextEligibleAfter(DateTime.now(), planToSave.medicationFrequencyDays);
      }
    }

    _patients[patientIndex] = p.copyWith(
      currentDose: dose,
      nextEligibleDate: nextEligible,
    );

    _logs.insert(
      0,
      ActivityLog.carePlan(
        id: 'LOG${_logs.length + 1}',
        patient: PatientRef(id: p.id, name: p.fullName, nameAr: p.fullNameAr),
        dose: dose,
        intervalDays: planToSave.medicationFrequencyDays,
        timestamp: DateTime.now(),
        pendingReview: needsReview,
      ),
    );

    notifyListeners();
  }

  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  PhysicalTherapyCenter? getTherapyCenterById(String? centerId) {
    if (centerId == null || centerId.isEmpty) return null;
    try {
      return _therapyCenters.firstWhere((c) => c.id == centerId);
    } catch (_) {
      return null;
    }
  }

  /// Map marker / care-plan ID → localized center name (same data as national map).
  String therapyCenterLabel(BuildContext context, String? centerId) {
    final center = getTherapyCenterById(centerId);
    if (center != null) return center.getLocalizedName(context);
    if (centerId == null || centerId.isEmpty) return '';
    return centerId;
  }

  DispensingCenter? getDispensingCenterById(String? centerId) {
    if (centerId == null || centerId.isEmpty) return null;
    try {
      return _centers.firstWhere((c) => c.id == centerId);
    } catch (_) {
      return null;
    }
  }

  String dispensingFacilityLabel(BuildContext context, String? centerId) {
    final center = getDispensingCenterById(centerId);
    if (center != null) return center.getLocalizedName(context);
    if (centerId == null || centerId.isEmpty) return '';
    return centerId;
  }

  TreatmentPlan? getPlanForPatient(String patientId) {
    try {
      return _treatmentPlans.firstWhere((p) => p.patientId == patientId && p.status == 'Active');
    } catch (e) {
      return null;
    }
  }

  void checkInSession(String planId, String sessionId, double weight) {
    final plan = _treatmentPlans.firstWhere((p) => p.id == planId);
    final session = plan.sessions.firstWhere((s) => s.id == sessionId);
    session.isAttended = true;
    session.weightAfter = weight;
    
    // Also update patient weight
    final patientIndex = _patients.indexWhere((p) => p.id == plan.patientId);
    if (patientIndex != -1) {
      final p = _patients[patientIndex];
      _patients[patientIndex] = p.copyWith(
        weight: weight,
        weightHistory: [...p.weightHistory, weight],
      );
    }
    notifyListeners();
  }

  void logMedication(String planId, DateTime time) {
    notifyListeners();
  }

  void completeExercise(String planId, String exerciseId) {
    final plan = _treatmentPlans.firstWhere((p) => p.id == planId);
    final ex = plan.homeExercises.firstWhere((e) => e.id == exerciseId);
    ex.completedDates.add(DateTime.now());
    notifyListeners();
  }

}
