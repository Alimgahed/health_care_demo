import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/locale_provider.dart';
import '../utils/dose_utils.dart';
import '../../features/treatment_plan/models/treatment_plan.dart';
import '../../features/journey/journey_models.dart';
import '../auth/access_control.dart';
import '../demo/demo_session_provider.dart';
import '../../features/clinical/patient_clinical_models.dart';
import '../clinical/clinical_eligibility_rules.dart'
    show ClinicalEligibilityRules, ProgramEligibilityResult;
import '../models/activity_log.dart';

enum ResidencyStatus { citizen, resident, visitor }

enum DispensingUiStatus {
  eligible,
  pendingCarePlan,
  pendingClinicalReview,
  approvedEarly,
  clinicalIneligible,
}

/// One authoritative, explainable result for the pharmacy's pre-dispense gate.
class DispensingValidationResult {
  final Patient? patient;
  final TreatmentPlan? plan;
  final List<String> issues;
  final List<String> warnings;
  final int availableStock;
  final String normalizedDose;

  const DispensingValidationResult({
    required this.patient,
    required this.plan,
    required this.issues,
    this.warnings = const [],
    required this.availableStock,
    required this.normalizedDose,
  });

  bool get canDispense => issues.isEmpty;
}

enum AppointmentStatus { scheduled, completed, cancelled, missed }

enum PharmacyRequestStatus {
  ready,
  pendingReview,
  notEligible,
  outOfStock,
  expired,
  cancelled,
  dispensed,
}

enum FinancialReviewStatus { estimated, settled, cancelled }

/// Explicit assumptions used only by the local demo coverage estimator.
/// These values are not an approved ministry benefit policy or drug tariff.
abstract final class DemoFinancialSupportPolicy {
  static const double medicationUnitPriceAed = 1000.0;
  static const double citizenCoverageRate = 1.0;
  static const double residentCoverageRate = 0.5;
  static const double visitorCoverageRate = 0.0;
  static const String policyLabel = 'Local demo assumption · v1';

  static double coverageRateFor(ResidencyStatus status) => switch (status) {
    ResidencyStatus.citizen => citizenCoverageRate,
    ResidencyStatus.resident => residentCoverageRate,
    ResidencyStatus.visitor => visitorCoverageRate,
  };
}

class FinancialSupportRecord {
  final String id;
  final String patientId;
  final String treatmentRequestId;
  final String treatmentPlanId;
  final double totalAed;
  final double coveredAed;
  final double copayAed;
  final FinancialReviewStatus status;
  final DateTime assessedAt;

  const FinancialSupportRecord({
    required this.id,
    required this.patientId,
    required this.treatmentRequestId,
    required this.treatmentPlanId,
    required this.totalAed,
    required this.coveredAed,
    required this.copayAed,
    required this.status,
    required this.assessedAt,
  });

  FinancialSupportRecord copyWith({FinancialReviewStatus? status}) =>
      FinancialSupportRecord(
        id: id,
        patientId: patientId,
        treatmentRequestId: treatmentRequestId,
        treatmentPlanId: treatmentPlanId,
        totalAed: totalAed,
        coveredAed: coveredAed,
        copayAed: copayAed,
        status: status ?? this.status,
        assessedAt: assessedAt,
      );
}

class PharmacyDispensingRequest {
  final String id;
  final String patientId;
  final String treatmentPlanId;
  final String treatmentRequestId;
  final String medication;
  final String dose;
  final int quantity;
  final DateTime requestedAt;
  final String assignedCenterId;
  final bool priority;
  final PharmacyRequestStatus status;

  const PharmacyDispensingRequest({
    required this.id,
    required this.patientId,
    required this.treatmentPlanId,
    this.treatmentRequestId = '',
    required this.medication,
    required this.dose,
    required this.quantity,
    required this.requestedAt,
    required this.assignedCenterId,
    this.priority = false,
    required this.status,
  });

  PharmacyDispensingRequest copyWith({
    PharmacyRequestStatus? status,
    String? treatmentRequestId,
  }) => PharmacyDispensingRequest(
    id: id,
    patientId: patientId,
    treatmentPlanId: treatmentPlanId,
    treatmentRequestId: treatmentRequestId ?? this.treatmentRequestId,
    medication: medication,
    dose: dose,
    quantity: quantity,
    requestedAt: requestedAt,
    assignedCenterId: assignedCenterId,
    priority: priority,
    status: status ?? this.status,
  );
}

class PatientAppointment {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final String doctor;
  final String purpose;
  final AppointmentStatus status;

  const PatientAppointment({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.doctor,
    required this.purpose,
    this.status = AppointmentStatus.scheduled,
  });

  PatientAppointment copyWith({
    DateTime? dateTime,
    AppointmentStatus? status,
  }) => PatientAppointment(
    id: id,
    patientId: patientId,
    dateTime: dateTime ?? this.dateTime,
    doctor: doctor,
    purpose: purpose,
    status: status ?? this.status,
  );
}

class PatientLabResult {
  final String id;
  final String patientId;
  final String testCode;
  final String nameEn;
  final String nameAr;
  final double value;
  final String unit;
  final String referenceRange;
  final String date;
  final String source;
  final String notes;
  final String categoryEn;
  final String categoryAr;
  final List<double> trend;

  const PatientLabResult({
    this.id = '',
    this.patientId = '',
    this.testCode = '',
    required this.nameEn,
    required this.nameAr,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.date,
    this.source = 'Program laboratory record',
    this.notes = '',
    required this.categoryEn,
    required this.categoryAr,
    required this.trend,
  });
}

class PatientNotification {
  final String id;
  final String patientId;
  final String title;
  final String detail;
  final DateTime createdAt;
  final bool isRead;

  const PatientNotification({
    required this.id,
    required this.patientId,
    required this.title,
    required this.detail,
    required this.createdAt,
    this.isRead = false,
  });

  PatientNotification copyWith({bool? isRead}) => PatientNotification(
    id: id,
    patientId: patientId,
    title: title,
    detail: detail,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

const demoLaboratoryResults = <PatientLabResult>[
  PatientLabResult(
    nameEn: 'HbA1c',
    nameAr: 'السكر التراكمي HbA1c',
    value: 8.5,
    unit: '%',
    referenceRange: '4.0 – 5.6',
    date: '2026-06-12',
    categoryEn: 'Diabetes',
    categoryAr: 'السكري',
    trend: [11.2, 10.4, 9.5, 8.8, 8.5, 8.1],
  ),
  PatientLabResult(
    nameEn: 'Fasting glucose',
    nameAr: 'سكر صائم',
    value: 160,
    unit: 'mg/dL',
    referenceRange: '70 – 99',
    date: '2026-06-12',
    categoryEn: 'Diabetes',
    categoryAr: 'السكري',
    trend: [240, 205, 178, 169, 155, 145],
  ),
  PatientLabResult(
    nameEn: 'Total cholesterol',
    nameAr: 'الكوليسترول الكلي',
    value: 210,
    unit: 'mg/dL',
    referenceRange: '< 200',
    date: '2026-06-12',
    categoryEn: 'Lipids',
    categoryAr: 'دهون الدم',
    trend: [250, 240, 228, 220, 215, 210],
  ),
  PatientLabResult(
    nameEn: 'LDL cholesterol',
    nameAr: 'الكوليسترول LDL',
    value: 132,
    unit: 'mg/dL',
    referenceRange: '< 100',
    date: '2026-06-12',
    categoryEn: 'Lipids',
    categoryAr: 'دهون الدم',
    trend: [190, 175, 155, 140, 132, 120],
  ),
  PatientLabResult(
    nameEn: 'HDL cholesterol',
    nameAr: 'الكوليسترول HDL',
    value: 42,
    unit: 'mg/dL',
    referenceRange: '> 40',
    date: '2026-06-12',
    categoryEn: 'Lipids',
    categoryAr: 'دهون الدم',
    trend: [36, 37, 39, 40, 41, 42],
  ),
  PatientLabResult(
    nameEn: 'Triglycerides',
    nameAr: 'الدهون الثلاثية',
    value: 180,
    unit: 'mg/dL',
    referenceRange: '< 150',
    date: '2026-06-12',
    categoryEn: 'Lipids',
    categoryAr: 'دهون الدم',
    trend: [235, 220, 205, 195, 188, 180],
  ),
  PatientLabResult(
    nameEn: 'Creatinine',
    nameAr: 'وظائف الكلى (Creatinine)',
    value: 1.1,
    unit: 'mg/dL',
    referenceRange: '0.6 – 1.3',
    date: '2026-06-12',
    categoryEn: 'Kidney',
    categoryAr: 'وظائف الكلى',
    trend: [1.0, 1.0, 1.1, 1.0, 1.1, 1.1],
  ),
  PatientLabResult(
    nameEn: 'Vitamin D',
    nameAr: 'فيتامين D',
    value: 18,
    unit: 'ng/mL',
    referenceRange: '30 – 100',
    date: '2026-06-12',
    categoryEn: 'Vitamins',
    categoryAr: 'الفيتامينات',
    trend: [12, 13, 14, 16, 17, 18],
  ),
];

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
  final List<String>? allergies;
  final List<String>? currentMedications;

  /// HbA1c % on file (e.g. 7.2). Used by rule engine — edit thresholds in [ClinicalEligibilityConfig].
  final double? hba1cPercent;

  /// Fasting glucose mg/dL on file.
  final double? fastingGlucoseMgDl;
  final List<PatientLabResult> labResults;

  double get bmi => weight / ((height / 100) * (height / 100));

  ProgramEligibilityResult get programEligibility =>
      ClinicalEligibilityRules.evaluateFields(
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
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
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
    this.allergies,
    this.currentMedications,
    this.hba1cPercent,
    this.fastingGlucoseMgDl,
    this.labResults = demoLaboratoryResults,
  });

  bool _isAr(BuildContext context) =>
      Provider.of<LocaleProvider>(context, listen: false).locale.languageCode ==
      'ar';

  String getLocalizedFullName(BuildContext context) =>
      _isAr(context) ? fullNameAr : fullName;
  String getLocalizedNationality(BuildContext context) =>
      _isAr(context) ? nationalityAr : nationality;
  String getLocalizedGender(BuildContext context) =>
      _isAr(context) ? genderAr : gender;
  String getLocalizedEmirate(BuildContext context) =>
      _isAr(context) ? emirateAr : emirate;
  List<String> getLocalizedMedicalConditions(BuildContext context) =>
      _isAr(context) ? medicalConditionsAr : medicalConditions;
  String getLocalizedResidency(BuildContext context) {
    if (_isAr(context)) {
      switch (residencyStatus) {
        case ResidencyStatus.citizen:
          return 'مواطن';
        case ResidencyStatus.resident:
          return 'مقيم';
        case ResidencyStatus.visitor:
          return 'زائر';
      }
    } else {
      switch (residencyStatus) {
        case ResidencyStatus.citizen:
          return 'Citizen';
        case ResidencyStatus.resident:
          return 'Resident';
        case ResidencyStatus.visitor:
          return 'Visitor';
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
    double? complianceRate,
    bool? hasChronicDisease,
    List<PatientAttachment>? clinicalAttachments,
    List<String>? allergies,
    List<String>? currentMedications,
    double? hba1cPercent,
    double? fastingGlucoseMgDl,
    List<PatientLabResult>? labResults,
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
      dispenseRecords: resetDispensingFacility
          ? const []
          : (dispenseRecords ?? this.dispenseRecords),
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      currentDose: currentDose ?? this.currentDose,
      latitude: latitude,
      longitude: longitude,
      emirate: emirate,
      emirateAr: emirateAr,
      weightHistory: weightHistory ?? this.weightHistory,
      doseHistory: doseHistory ?? this.doseHistory,
      complianceRate: complianceRate ?? this.complianceRate,
      hasChronicDisease: hasChronicDisease ?? this.hasChronicDisease,
      clinicalAttachments: clinicalAttachments ?? this.clinicalAttachments,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      hba1cPercent: hba1cPercent ?? this.hba1cPercent,
      fastingGlucoseMgDl: fastingGlucoseMgDl ?? this.fastingGlucoseMgDl,
      labResults: labResults ?? this.labResults,
    );
  }
}

enum MedicationDoseStatus { taken, skipped, missed }

class MedicationDoseEvent {
  final String id;
  final String planId;
  final String patientId;
  final DateTime scheduledAt;
  final DateTime recordedAt;
  final MedicationDoseStatus status;

  const MedicationDoseEvent({
    required this.id,
    required this.planId,
    required this.patientId,
    required this.scheduledAt,
    required this.recordedAt,
    required this.status,
  });
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

  bool _isAr(BuildContext context) =>
      Provider.of<LocaleProvider>(context, listen: false).locale.languageCode ==
      'ar';

  String getLocalizedName(BuildContext context) =>
      _isAr(context) ? nameAr : name;
  String getLocalizedEmirate(BuildContext context) =>
      _isAr(context) ? emirateAr : emirate;
  String getLocalizedSpecialty(BuildContext context) =>
      _isAr(context) ? specialtyAr : specialty;
  String getLocalizedHospital(BuildContext context) =>
      _isAr(context) ? hospitalAr : hospital;
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
  final List<MedicationBatch> batches;
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
    List<MedicationBatch>? batches,
    this.dispensed2_5mg = 0,
    this.dispensed5mg = 0,
    this.dispensed7_5mg = 0,
    this.dispensed10mg = 0,
    required this.latitude,
    required this.longitude,
    required this.phone,
  }) : batches =
           batches ??
           _defaultBatches(
             id,
             inventory2_5mg,
             inventory5mg,
             inventory7_5mg,
             inventory10mg,
           );

  static List<MedicationBatch> _defaultBatches(
    String centerId,
    int d25,
    int d5,
    int d75,
    int d10,
  ) => [
    if (d25 > 0)
      MedicationBatch(
        id: '$centerId-25-2026A',
        dose: '2.5 mg',
        quantity: d25,
        expiryDate: DateTime(2027, 12, 31),
      ),
    if (d5 > 0)
      MedicationBatch(
        id: '$centerId-5-2026A',
        dose: '5 mg',
        quantity: d5,
        expiryDate: DateTime(2027, 12, 31),
      ),
    if (d75 > 0)
      MedicationBatch(
        id: '$centerId-75-2026A',
        dose: '7.5 mg',
        quantity: d75,
        expiryDate: DateTime(2027, 12, 31),
      ),
    if (d10 > 0)
      MedicationBatch(
        id: '$centerId-10-2026A',
        dose: '10 mg',
        quantity: d10,
        expiryDate: DateTime(2027, 12, 31),
      ),
  ];

  int get totalAvailable =>
      inventory2_5mg + inventory5mg + inventory7_5mg + inventory10mg;
  int get totalDispensed =>
      dispensed2_5mg + dispensed5mg + dispensed7_5mg + dispensed10mg;
  int get totalAllocated => totalAvailable + totalDispensed;

  bool _isAr(BuildContext context) =>
      Provider.of<LocaleProvider>(context, listen: false).locale.languageCode ==
      'ar';

  String getLocalizedName(BuildContext context) =>
      _isAr(context) ? nameAr : name;
  String getLocalizedRegion(BuildContext context) =>
      _isAr(context) ? regionAr : region;

  DispensingCenter copyWith({
    int? inventory2_5mg,
    int? inventory5mg,
    int? inventory7_5mg,
    int? inventory10mg,
    int? dispensed2_5mg,
    int? dispensed5mg,
    int? dispensed7_5mg,
    int? dispensed10mg,
    List<MedicationBatch>? batches,
  }) {
    final next25 = inventory2_5mg ?? this.inventory2_5mg;
    final next5 = inventory5mg ?? this.inventory5mg;
    final next75 = inventory7_5mg ?? this.inventory7_5mg;
    final next10 = inventory10mg ?? this.inventory10mg;
    return DispensingCenter(
      id: id,
      name: name,
      nameAr: nameAr,
      region: region,
      regionAr: regionAr,
      inventory2_5mg: next25,
      inventory5mg: next5,
      inventory7_5mg: next75,
      inventory10mg: next10,
      batches:
          batches ??
          (inventory2_5mg == null &&
                  inventory5mg == null &&
                  inventory7_5mg == null &&
                  inventory10mg == null
              ? this.batches.map((batch) => batch.copyWith()).toList()
              : _defaultBatches(id, next25, next5, next75, next10)),
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

class MedicationBatch {
  final String id;
  final String dose;
  final DateTime expiryDate;
  final int quantity;

  const MedicationBatch({
    required this.id,
    required this.dose,
    required this.expiryDate,
    required this.quantity,
  });

  MedicationBatch copyWith({int? quantity}) => MedicationBatch(
    id: id,
    dose: dose,
    expiryDate: expiryDate,
    quantity: quantity ?? this.quantity,
  );
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

  bool _isAr(BuildContext context) =>
      Provider.of<LocaleProvider>(context, listen: false).locale.languageCode ==
      'ar';

  String getLocalizedName(BuildContext context) =>
      _isAr(context) ? nameAr : name;
  String getLocalizedEmirate(BuildContext context) =>
      _isAr(context) ? emirateAr : emirate;
  String getLocalizedChiefTherapist(BuildContext context) =>
      _isAr(context) ? chiefTherapistAr : chiefTherapist;
  List<String> getLocalizedServices(BuildContext context) =>
      _isAr(context) ? servicesAr : services;
}

class MockData {
  // Legacy static lists to keep compatibility with parts of the code
  static final List<Doctor> doctors = _generateInitialDoctors();
  static final List<Patient> patients = _generateInitialPatients();
  static final List<DispensingCenter> centers = _generateInitialCenters();
  static final List<PhysicalTherapyCenter> therapyCenters =
      _generateInitialTherapyCenters();

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
          TherapySession(
            id: 'S1',
            sessionNumber: 1,
            scheduledDate: DateTime.now().subtract(const Duration(days: 7)),
            isAttended: true,
            weightAfter: 104.5,
          ),
          TherapySession(
            id: 'S2',
            sessionNumber: 2,
            scheduledDate: DateTime.now(),
            isAttended: false,
          ),
          TherapySession(
            id: 'S3',
            sessionNumber: 3,
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
          ),
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
          TherapySession(
            id: 'S1',
            sessionNumber: 1,
            scheduledDate: DateTime.now().subtract(const Duration(days: 14)),
            isAttended: true,
            weightAfter: 88.0,
          ),
          TherapySession(
            id: 'S2',
            sessionNumber: 2,
            scheduledDate: DateTime.now().subtract(const Duration(days: 7)),
            isAttended: true,
            weightAfter: 87.5,
          ),
          TherapySession(
            id: 'S3',
            sessionNumber: 3,
            scheduledDate: DateTime.now(),
            isAttended: false,
          ),
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
          TherapySession(
            id: 'S1',
            sessionNumber: 1,
            scheduledDate: DateTime.now().add(const Duration(days: 2)),
            isAttended: false,
          ),
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
        services: [
          'Obesity Rehab',
          'Cardio Conditioning',
          'Post-Bariatric Training',
        ],
        servicesAr: [
          'تأهيل السمنة',
          'التكييف القلبي',
          'تدريب ما بعد جراحة السمنة',
        ],

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
        services: [
          'Kinesiotherapy',
          'Body Contouring Rehab',
          'Post-Surgical Exercise',
        ],
        servicesAr: [
          'العلاج الحركي',
          'تأهيل نحت الجسم',
          'تمارين ما بعد الجراحة',
        ],

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
        services: [
          'Obesity Rehab',
          'Mobility Therapy',
          'Muscle Strength Conditioning',
        ],
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
        services: [
          'Post-Bariatric Training',
          'Joint Mobility Therapy',
          'Hydrotherapy',
        ],
        servicesAr: [
          'تدريب ما بعد جراحة السمنة',
          'علاج حركة المفاصل',
          'العلاج المائي',
        ],

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
        // Al Ain city rolls up to Abu Dhabi emirate in regional reporting.
        region: 'Abu Dhabi',
        regionAr: 'أبوظبي',

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
      'Ahmed Al Mansoori',
      'Khalid Al Hashimi',
      'Zayed Al Nahyan',
      'Sultan Al Qasimi',
      'Rashid Al Nuaimi',
      'Faisal Al Ketbi',
      'Humaid Al Shamsi',
      'Mohammed Al Falasi',
      'Saeed Al Maktoum',
      'Omar Al Suwaidi',
      'Tariq Al Jaber',
      'Hamdan Al Kaabi',
      'Yousef Al Shehhi',
      'Adnan Al Mazrouei',
      'Saif Al Hameli',
      'Majid Al Ghurair',
      'Ali Al Naboodah',
      'Marwan Al Tayer',
      'Salem Al Sayegh',
      'Waleed Al Gurg',
      'Hassan Ibrahim',
      'Mahmoud Ali',
      'Yasser Saeed',
      'Kareem Abdelrahman',
      'Tariq Hussein',
      'Ziad Khoury',
      'Marwan Haddad',
      'Wael Nasser',
      'Fares Mansour',
      'Ramy Abboud',
      'Assi El Zein',
      'Melhem Karam',
      'Saber Rebai',
      'George Saliba',
      'Kazem Al Ali',
      'Majid Al Mohandis',
      'Rashed Al Majed',
      'Abdul Majeed',
      'Hussein Al Jasmi',
      'Fahad Al Kubaisi',
      'Nabeel Shuail',
      'Abdullah Al Ruwaished',
      'Mohammed Abdu',
      'Talal Maddah',
      'Ayman Zidan',
      'Bassam Kousa',
      'Jamal Suliman',
      'Tim Hassan',
      'Samer Al Masri',
      'Qusai Khouli',
    ];
    final List<String> maleNamesAr = [
      'أحمد المنصوري',
      'خالد الهاشمي',
      'زايد آل نهيان',
      'سلطان القاسمي',
      'راشد النعيمي',
      'فيصل الكتبي',
      'حميد الشامسي',
      'محمد الفلاسي',
      'سعيد آل مكتوم',
      'عمر السويدي',
      'طارق الجابر',
      'حمدان الكعبي',
      'يوسف الشحي',
      'عدنان المزروعي',
      'سيف الهاملي',
      'ماجد الغرير',
      'علي النابودة',
      'مروان الطاير',
      'سالم الصايغ',
      'وليد القرق',
      'حسن إبراهيم',
      'محمود علي',
      'ياسر سعيد',
      'كريم عبدالرحمن',
      'طارق حسين',
      'زياد خوري',
      'مروان حداد',
      'وائل ناصر',
      'فارس منصور',
      'رامي عبود',
      'عاصي الزين',
      'ملحم كرم',
      'صابر الرباعي',
      'جورج صليبا',
      'كاظم العلي',
      'ماجد المهندس',
      'راشد الماجد',
      'عبدالمجيد',
      'حسين الجسمي',
      'فهد الكبيسي',
      'نبيل شعيل',
      'عبدالله الرويشد',
      'محمد عبده',
      'طلال مداح',
      'أيمن زيدان',
      'بسام كوسا',
      'جمال سليمان',
      'تيم حسن',
      'سامر المصري',
      'قصي خولي',
    ];

    final List<String> femaleNames = [
      'Sarah Yousef',
      'Fatima Al Qasimi',
      'Mariam Al Kaabi',
      'Shamma Al Maktoum',
      'Amna Al Shehhi',
      'Reem Al Hashimi',
      'Maitha Al Falasi',
      'Latifa Al Maktoum',
      'Muna Al Shamsi',
      'Hessa Al Suwaidi',
      'Aisha Al Jaber',
      'Noora Al Mansoori',
      'Salama Al Ketbi',
      'Hind Al Mazrouei',
      'Jawahir Al Qasimi',
      'Rawda Al Hameli',
      'Shaikha Al Tayer',
      'Moza Al Naboodah',
      'Alia Al Sayegh',
      'Budoor Al Gurg',
      'Laila Ali',
      'Mona Zaki',
      'Hend Rostom',
      'Faten Hamama',
      'Soad Hosny',
      'Nadia Lutfi',
      'Shadia',
      'Sabah',
      'Fayrouz',
      'Umm Kulthum',
      'Nancy Ajram',
      'Elissa',
      'Haifa Wehbe',
      'Najwa Karam',
      'Nawal El Zoghbi',
      'Diana Haddad',
      'Carole Samaha',
      'Myriam Fares',
      'Yara',
      'Maya Diab',
      'Assala Nasri',
      'Sherine Abdel Wahab',
      'Angham',
      'Samira Said',
      'Latifa',
      'Ahlam',
      'Nawal Al Kuwaitia',
      'Balqees',
      'Dalia',
      'Youssra',
    ];
    final List<String> femaleNamesAr = [
      'سارة يوسف',
      'فاطمة القاسمي',
      'مريم الكعبي',
      'شمة آل مكتوم',
      'آمنة الشحي',
      'ريم الهاشمي',
      'ميثاء الفلاسي',
      'لطيفة آل مكتوم',
      'منى الشامسي',
      'حصة السويدي',
      'عائشة الجابر',
      'نورة المنصوري',
      'سلامة الكتبي',
      'هند المزروعي',
      'جواهر القاسمي',
      'روضة الهاملي',
      'شيخة الطاير',
      'موزة النابودة',
      'عليا الصايغ',
      'بدور القرق',
      'ليلى علي',
      'منى زكي',
      'هند رستم',
      'فاتن حمامة',
      'سعاد حسني',
      'نادية لطفي',
      'شادية',
      'صباح',
      'فيروز',
      'أم كلثوم',
      'نانسي عجرم',
      'إليسا',
      'هيفاء وهبي',
      'نجوى كرم',
      'نوال الزغبي',
      'ديانا حداد',
      'كارول سماحة',
      'ميريام فارس',
      'يارا',
      'مايا دياب',
      'أصالة نصري',
      'شيرين عبدالوهاب',
      'أنغام',
      'سميرة سعيد',
      'لطيفة',
      'أحلام',
      'نوال الكويتية',
      'بلقيس',
      'داليا',
      'يسرا',
    ];

    final List<String> nationalities = [
      'United Arab Emirates',
      'Egypt',
      'Saudi Arabia',
      'Jordan',
      'Lebanon',
      'Syria',
      'Palestine',
      'Oman',
      'Kuwait',
      'Bahrain',
      'Qatar',
      'Morocco',
      'Algeria',
      'Tunisia',
      'Sudan',
    ];
    final List<String> nationalitiesAr = [
      'الإمارات العربية المتحدة',
      'مصر',
      'المملكة العربية السعودية',
      'الأردن',
      'لبنان',
      'سوريا',
      'فلسطين',
      'عمان',
      'الكويت',
      'البحرين',
      'قطر',
      'المغرب',
      'الجزائر',
      'تونس',
      'السودان',
    ];

    final List<String> conditions = [
      'Obesity',
      'Type 2 Diabetes',
      'Hypertension',
      'Dyslipidemia',
      'Pre-diabetes',
      'PCOS',
      'Sleep Apnea',
      'Fatty Liver Disease',
      'Osteoarthritis',
    ];
    final List<String> conditionsAr = [
      'السمنة',
      'السكري من النوع 2',
      'ارتفاع ضغط الدم',
      'عسر شحميات الدم',
      'مرحلة ما قبل السكري',
      'تكيس المبايض',
      'توقف التنفس أثناء النوم',
      'مرض الكبد الدهني',
      'هشاشة العظام',
    ];

    final List<Map<String, dynamic>> emirateCoords = [
      {'name': 'Abu Dhabi', 'nameAr': 'أبوظبي', 'lat': 24.4539, 'lng': 54.3773},
      {'name': 'Dubai', 'nameAr': 'دبي', 'lat': 25.2048, 'lng': 55.2708},
      {'name': 'Sharjah', 'nameAr': 'الشارقة', 'lat': 25.3463, 'lng': 55.4209},
      {'name': 'Ajman', 'nameAr': 'عجمان', 'lat': 25.4052, 'lng': 55.4390},
      {
        'name': 'Umm Al Quwain',
        'nameAr': 'أم القيوين',
        'lat': 25.5647,
        'lng': 55.5551,
      },
      {
        'name': 'Ras Al Khaimah',
        'nameAr': 'رأس الخيمة',
        'lat': 25.7895,
        'lng': 55.9432,
      },
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
        lastDispensingDate: '2026-06-10',
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
        lastDispensingDate: '2026-06-15',
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
        lastDispensingDate: '2026-05-20',
        nextEligibleDate: '2026-05-15',
        currentDose: '7.5 mg',
        latitude: 24.1873,
        longitude: 55.7606,
        // Al Ain is a city within Abu Dhabi emirate, not an emirate itself.
        emirate: 'Abu Dhabi',
        emirateAr: 'أبوظبي',
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
        lastDispensingDate: '2026-06-05',
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

      final natIdx = rand.nextInt(10) < 6
          ? 0
          : rand.nextInt(nationalities.length);
      final nationality = nationalities[natIdx];
      final nationalityAr = nationalitiesAr[natIdx];

      final residency = nationality == 'United Arab Emirates'
          ? ResidencyStatus.citizen
          : (rand.nextBool()
                ? ResidencyStatus.resident
                : ResidencyStatus.visitor);

      final age = 18 + rand.nextInt(65);
      final height = gender == 'Male'
          ? 165 + rand.nextDouble() * 25
          : 150 + rand.nextDouble() * 25;
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

      String? lastDispDate;
      String? nextDispDate = 'Eligible Now';

      final hasHistory = rand.nextBool() || rand.nextBool(); // 75% have history
      if (hasHistory) {
        final isRecent = rand
            .nextBool(); // 50% of those with history are recent (ineligible)
        if (isRecent) {
          final day = 15 + rand.nextInt(14); // 15 to 28
          lastDispDate = '2026-09-$day';
          final nextDate = DateTime(2026, 9, day).add(const Duration(days: 28));
          nextDispDate =
              '${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';
        } else {
          final month = 6 + rand.nextInt(2); // 6 or 7
          final day = 10 + rand.nextInt(20);
          lastDispDate = '2026-0$month-$day';
          final nextDate = DateTime(
            2026,
            month,
            day,
          ).add(const Duration(days: 28));
          nextDispDate =
              '${nextDate.year}-0${nextDate.month}-${nextDate.day.toString().padLeft(2, '0')}';
        }
      }

      final currentDose = [
        '2.5 mg',
        '5 mg',
        '7.5 mg',
        '10 mg',
      ][rand.nextInt(4)];
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
          complianceRate: double.parse(
            (0.70 + rand.nextDouble() * 0.29).toStringAsFixed(2),
          ),
        ),
      );
    }
    return list;
  }
}

class DataProvider extends ChangeNotifier {
  final AccessControlProvider? _access;
  final DemoSessionProvider? _session;

  bool _can(AppPermission permission) => _access?.can(permission) ?? true;

  bool _canRecordFor(String patientId, AppPermission permission) =>
      _can(permission) &&
      (_access?.role != AppRole.patient || _session?.patientId == patientId);
  late List<Doctor> _doctors;
  late List<Patient> _patients;
  late List<DispensingCenter> _centers;
  late List<PhysicalTherapyCenter> _therapyCenters;
  final List<ActivityLog> _logs = [];
  final List<PharmacyDispensingRequest> _pharmacyRequests = [];
  final Map<String, List<PatientAppointment>> _appointments = {};
  final List<MedicationDoseEvent> _medicationEvents = [];
  final List<PatientNotification> _notifications = [];
  final List<FinancialSupportRecord> _financialRecords = [];
  final Map<String, List<DemoTreatmentRequest>> _treatmentRequests = {};

  DataProvider({AccessControlProvider? access, DemoSessionProvider? session})
    : _access = access,
      _session = session {
    _doctors = List.from(MockData.doctors);
    _patients = List.from(MockData.patients);

    // Inject a hardcoded "Clinical Ineffective" patient for demo purposes
    _patients.insert(
      0,
      Patient(
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
        lastDispensingDate: '2026-06-12',
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
      ),
    );
    _centers = MockData.centers.map((center) => center.copyWith()).toList();
    _therapyCenters = List.from(MockData.therapyCenters);

    _assignPatientSpecificLabResults();
    _ensureGoldenPatientPlan();
    _reconcilePatientDispenseRecords();
    _assignDispenseFacilities();
    _seedActivityLogs();
    _seedPharmacyRequests();
    _seedTreatmentRequests();
  }

  Map<String, List<DemoTreatmentRequest>> get treatmentRequestHistory =>
      Map<String, List<DemoTreatmentRequest>>.unmodifiable(
        _treatmentRequests.map(
          (patientId, history) => MapEntry(
            patientId,
            List<DemoTreatmentRequest>.unmodifiable(history),
          ),
        ),
      );

  List<DemoTreatmentRequest> treatmentRequestsFor(String patientId) =>
      List.unmodifiable(_treatmentRequests[patientId] ?? const []);

  DemoTreatmentRequest? treatmentRequestById(String id) {
    for (final history in _treatmentRequests.values) {
      for (final request in history) {
        if (request.id == id) return request;
      }
    }
    return null;
  }

  DemoTreatmentRequest? activeTreatmentRequestFor(String patientId) {
    final history = _treatmentRequests[patientId];
    return history == null || history.isEmpty ? null : history.last;
  }

  void replaceTreatmentRequestHistory(
    String patientId,
    List<DemoTreatmentRequest> history,
  ) {
    _treatmentRequests[patientId] = List.of(history);
    if (history.isNotEmpty) {
      _synchronizePlanApproval(history.last);
      _synchronizeRequestQueue(history.last);
    }
    notifyListeners();
  }

  void _synchronizeRequestQueue(DemoTreatmentRequest request) {
    final terminal = const {
      RequestStatus.rejected,
      RequestStatus.cancelled,
      RequestStatus.expired,
      RequestStatus.completed,
    }.contains(request.status);
    var activeQueueFound = false;
    for (var i = 0; i < _pharmacyRequests.length; i++) {
      final queue = _pharmacyRequests[i];
      if (queue.patientId != request.patientId ||
          queue.treatmentPlanId != request.treatmentPlanId ||
          queue.status == PharmacyRequestStatus.dispensed ||
          queue.status == PharmacyRequestStatus.cancelled) {
        continue;
      }
      if (terminal) {
        _pharmacyRequests[i] = queue.copyWith(
          status: PharmacyRequestStatus.cancelled,
        );
      } else {
        activeQueueFound = true;
        _pharmacyRequests[i] = queue.copyWith(treatmentRequestId: request.id);
      }
    }
    if (!terminal && !activeQueueFound) {
      final plan = getPlanForPatient(request.patientId);
      if (plan != null && plan.id == request.treatmentPlanId) {
        final centerId =
            _centers.any((center) => center.id == plan.assignedCenterId)
            ? plan.assignedCenterId!
            : (_centers.isEmpty ? '' : _centers.first.id);
        _pharmacyRequests.add(
          PharmacyDispensingRequest(
            id: 'RXQ-${request.id}',
            patientId: request.patientId,
            treatmentPlanId: plan.id,
            treatmentRequestId: request.id,
            medication: request.medication,
            dose: DoseUtils.toInventoryDose(plan.medicationDose),
            quantity: plan.medicationQuantity,
            requestedAt: DateTime.now(),
            assignedCenterId: centerId,
            status: PharmacyRequestStatus.pendingReview,
          ),
        );
      }
    }
    _refreshPharmacyQueue();
  }

  void saveTreatmentRequest(DemoTreatmentRequest request) {
    final history = _treatmentRequests.putIfAbsent(request.patientId, () => []);
    final index = history.indexWhere((item) => item.id == request.id);
    final previous = index < 0 ? null : history[index];
    if (index < 0) {
      history.add(request);
    } else {
      history[index] = request;
    }
    _synchronizePlanApproval(request);
    _synchronizeRequestQueue(request);
    if (previous?.status != request.status) {
      final update = switch (request.status) {
        RequestStatus.approved => (
          'Treatment approved',
          'Your treatment request was approved by a medical reviewer.',
        ),
        RequestStatus.needsInformation => (
          'More information needed',
          'Your care team needs additional information for your treatment request.',
        ),
        RequestStatus.rejected => (
          'Treatment request reviewed',
          'Your care team has updated your treatment request. Contact your doctor for details.',
        ),
        RequestStatus.readyToDispense => (
          'Medication ready for pharmacy',
          'Your approved request is available to the dispensing centre.',
        ),
        _ => null,
      };
      if (update != null) {
        _addPatientNotification(request.patientId, update.$1, update.$2);
      }
    }
    notifyListeners();
  }

  void _synchronizePlanApproval(DemoTreatmentRequest request) {
    final index = _treatmentPlans.indexWhere(
      (plan) =>
          plan.id == request.treatmentPlanId &&
          plan.patientId == request.patientId,
    );
    if (index < 0) return;
    final status = switch (request.status) {
      RequestStatus.approved ||
      RequestStatus.readyToDispense ||
      RequestStatus.dispensed ||
      RequestStatus.monitoring ||
      RequestStatus.renewalDue ||
      RequestStatus.completed => 'approved',
      RequestStatus.rejected => 'rejected',
      _ => 'pending_review',
    };
    if (_treatmentPlans[index].clinicalApprovalStatus != status) {
      _treatmentPlans[index] = _treatmentPlans[index].copyWith(
        clinicalApprovalStatus: status,
      );
    }
  }

  List<PatientNotification> notificationsFor(String patientId) =>
      List.unmodifiable(
        _notifications.where((item) => item.patientId == patientId),
      );

  List<FinancialSupportRecord> get financialRecords =>
      List.unmodifiable(_financialRecords);

  FinancialSupportRecord coverageForRequest(String treatmentRequestId) {
    final existing = _financialRecords.where(
      (item) => item.treatmentRequestId == treatmentRequestId,
    );
    if (existing.isNotEmpty) return existing.last;
    final request = treatmentRequestById(treatmentRequestId);
    if (request == null) {
      throw StateError('The treatment request was not found.');
    }
    final patient = getPatientById(request.patientId);
    final plan = getPlanForPatient(request.patientId);
    if (patient == null || plan == null || plan.id != request.treatmentPlanId) {
      throw StateError('The patient or treatment plan was not found.');
    }
    final assessment = coverageEstimateForPatient(patient.id)!;
    final linked = FinancialSupportRecord(
      id: 'FIN-${request.id}',
      patientId: patient.id,
      treatmentRequestId: request.id,
      treatmentPlanId: plan.id,
      totalAed: assessment.totalAed,
      coveredAed: assessment.coveredAed,
      copayAed: assessment.copayAed,
      status: FinancialReviewStatus.estimated,
      assessedAt: DateTime.now(),
    );
    _financialRecords.add(linked);
    return linked;
  }

  FinancialSupportRecord? coverageEstimateForPatient(String patientId) {
    final patient = getPatientById(patientId);
    final plan = getPlanForPatient(patientId);
    if (patient == null || plan == null) return null;
    final total =
        DemoFinancialSupportPolicy.medicationUnitPriceAed *
        plan.medicationQuantity;
    final covered =
        total *
        DemoFinancialSupportPolicy.coverageRateFor(patient.residencyStatus);
    return FinancialSupportRecord(
      id: 'EST-$patientId',
      patientId: patientId,
      treatmentRequestId: '',
      treatmentPlanId: plan.id,
      totalAed: total,
      coveredAed: covered,
      copayAed: total - covered,
      status: FinancialReviewStatus.estimated,
      assessedAt: DateTime.now(),
    );
  }

  TransitionResult submitRefillRequest({
    required String patientId,
    required String centerId,
  }) {
    if (!_canRecordFor(patientId, AppPermission.requestMedication)) {
      return const TransitionResult(
        false,
        'This patient account cannot submit the request.',
      );
    }
    final patient = getPatientById(patientId);
    final plan = getPlanForPatient(patientId);
    final center = getDispensingCenterById(centerId);
    if (patient == null || plan == null || center == null) {
      return const TransitionResult(
        false,
        'Patient, treatment plan, or centre is unavailable.',
      );
    }
    final existing = pharmacyRequestForPatient(patientId);
    if (existing != null) {
      if (existing.status == PharmacyRequestStatus.ready &&
          existing.assignedCenterId == centerId) {
        return const TransitionResult(
          true,
          'The medication request is already ready at this centre.',
        );
      }
      return const TransitionResult(
        false,
        'An active medication request already exists.',
      );
    }
    if (plan.clinicalApprovalStatus != 'approved' ||
        !plan.prescriptionValidUntil.isAfter(DateTime.now())) {
      return const TransitionResult(
        false,
        'Medical approval or a valid prescription is required.',
      );
    }
    if (!patient.programEligibility.eligible ||
        !_hasRequiredRecentLabs(patient)) {
      return const TransitionResult(
        false,
        'Clinical eligibility or recent laboratory information needs review.',
      );
    }
    if (isPatientInDispensingCooldown(patient) &&
        !_dispenseAuthorizations.contains(patientId)) {
      return const TransitionResult(
        false,
        'The next refill window has not opened.',
      );
    }
    if (_stockForDose(center, plan.medicationDose) < plan.medicationQuantity) {
      return const TransitionResult(
        false,
        'Medication is unavailable at the selected centre.',
      );
    }
    final now = DateTime.now();
    final requestId = 'TR-$patientId-${now.microsecondsSinceEpoch}';
    final request = DemoTreatmentRequest(
      id: requestId,
      patientId: patientId,
      treatmentPlanId: plan.id,
      patientNameEn: patient.fullName,
      patientNameAr: patient.fullNameAr,
      mrn: patient.id,
      age: patient.age,
      genderEn: patient.gender,
      genderAr: patient.genderAr,
      hospitalEn: 'Programme facility',
      hospitalAr: 'منشأة البرنامج',
      diagnosisEn: patient.medicalConditions.isEmpty
          ? 'Not recorded'
          : patient.medicalConditions.first,
      diagnosisAr: patient.medicalConditionsAr.isEmpty
          ? 'غير مسجل'
          : patient.medicalConditionsAr.first,
      medication: 'Mounjaro',
      dose: plan.medicationDose,
      indicationEn: 'Approved refill',
      indicationAr: 'إعادة صرف معتمدة',
      previousTreatmentEn: patient.doseHistory.join(' → '),
      previousTreatmentAr: patient.doseHistory.join(' ← '),
      currentMedicationEn: 'Mounjaro ${plan.medicationDose}',
      currentMedicationAr: 'مونجارو ${plan.medicationDose}',
      crp: null,
      esr: null,
      physicianReportAttached: patient.clinicalAttachments.isNotEmpty,
      recentDuplicate: false,
      urgent: false,
      createdAt: now,
      status: RequestStatus.readyToDispense,
      criteria: const [],
      aiRecommendation: AiRecommendation.approve,
      humanDecision: ReviewDecision.approve,
      approvalValidUntil: plan.prescriptionValidUntil,
      audit: [
        JourneyAuditEvent(
          action: 'REFILL_REQUESTED',
          actor: 'Patient',
          role: 'patient',
          previousState: null,
          newState: RequestStatus.readyToDispense,
          timestamp: now,
          reason: 'Refill under the existing approved treatment plan.',
        ),
      ],
    );
    _treatmentRequests.putIfAbsent(patientId, () => []).add(request);
    _pharmacyRequests.add(
      PharmacyDispensingRequest(
        id: 'RXQ-$requestId',
        patientId: patientId,
        treatmentPlanId: plan.id,
        treatmentRequestId: requestId,
        medication: 'Mounjaro',
        dose: DoseUtils.toInventoryDose(plan.medicationDose),
        quantity: plan.medicationQuantity,
        requestedAt: now,
        assignedCenterId: centerId,
        status: PharmacyRequestStatus.ready,
      ),
    );
    coverageForRequest(requestId);
    _addPatientNotification(
      patientId,
      'Refill request submitted',
      'The selected dispensing centre has received your medication request.',
    );
    _refreshPharmacyQueue();
    notifyListeners();
    return const TransitionResult(
      true,
      'Medication request submitted to pharmacy.',
    );
  }

  void markNotificationRead(String patientId, String notificationId) {
    if (!_canRecordFor(patientId, AppPermission.recordPatientActivity)) return;
    final index = _notifications.indexWhere(
      (item) => item.patientId == patientId && item.id == notificationId,
    );
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  void _addPatientNotification(String patientId, String title, String detail) {
    _notifications.insert(
      0,
      PatientNotification(
        id: 'NTF-$patientId-${DateTime.now().microsecondsSinceEpoch}',
        patientId: patientId,
        title: title,
        detail: detail,
        createdAt: DateTime.now(),
      ),
    );
  }

  bool approveTreatmentRequest(String requestId, {required AppRole actorRole}) {
    if (actorRole != AppRole.medicalReviewer &&
        actorRole != AppRole.systemAdmin) {
      return false;
    }
    final request = treatmentRequestById(requestId);
    if (request == null || request.status != RequestStatus.underReview) {
      return false;
    }
    final patient = getPatientById(request.patientId);
    final planIndex = _treatmentPlans.indexWhere(
      (item) =>
          item.id == request.treatmentPlanId &&
          item.patientId == request.patientId &&
          item.status == 'Active',
    );
    if (patient == null ||
        planIndex < 0 ||
        !patient.programEligibility.eligible ||
        !_hasRequiredRecentLabs(patient)) {
      return false;
    }
    _treatmentPlans[planIndex] = _treatmentPlans[planIndex].copyWith(
      clinicalApprovalStatus: 'approved',
    );
    notifyListeners();
    return true;
  }

  List<String> pharmacyReleaseIssues(String requestId) {
    final request = treatmentRequestById(requestId);
    if (request == null) return const ['Treatment request was not found.'];
    final patient = getPatientById(request.patientId);
    final plan = getPlanForPatient(request.patientId);
    final issues = <String>[];
    if (patient == null) issues.add('Patient record was not found.');
    if (plan == null || plan.id != request.treatmentPlanId) {
      issues.add('An active treatment plan is required.');
    } else if (plan.clinicalApprovalStatus != 'approved') {
      issues.add('Medical approval is required.');
    }
    if (patient != null && !patient.programEligibility.eligible) {
      issues.add('Clinical eligibility is not met.');
    }
    if (patient != null && !_hasRequiredRecentLabs(patient)) {
      issues.add('Required recent laboratory results are missing.');
    }
    if (plan != null && !plan.prescriptionValidUntil.isAfter(DateTime.now())) {
      issues.add('The prescription has expired.');
    }
    if (plan != null &&
        (plan.medicationQuantity < 1 ||
            plan.medicationFrequencyDays < 1 ||
            !DoseUtils.planDoseOptions
                .map(DoseUtils.toInventoryDose)
                .contains(DoseUtils.toInventoryDose(plan.medicationDose)))) {
      issues.add('The prescription dose, quantity, or interval is invalid.');
    }
    final queue = _pharmacyRequests.where(
      (item) =>
          item.treatmentRequestId == request.id &&
          item.status != PharmacyRequestStatus.cancelled &&
          item.status != PharmacyRequestStatus.dispensed,
    );
    if (queue.isEmpty) {
      issues.add('No pharmacy request is linked to this treatment.');
    } else if (plan != null) {
      final center = getDispensingCenterById(queue.first.assignedCenterId);
      if (center == null) {
        issues.add('The assigned pharmacy centre is unavailable.');
      } else if (_stockForDose(center, plan.medicationDose) <
          plan.medicationQuantity) {
        issues.add('Medication stock is unavailable at the assigned centre.');
      }
    }
    if (patient != null &&
        isPatientInDispensingCooldown(patient) &&
        !_dispenseAuthorizations.contains(patient.id)) {
      issues.add('The next dispensing window has not opened.');
    }
    if (request.humanDecision != ReviewDecision.approve) {
      issues.add('A reviewer decision is required.');
    }
    return issues;
  }

  void _seedTreatmentRequests() {
    for (final plan in _treatmentPlans) {
      final patient = getPatientById(plan.patientId);
      if (patient == null) continue;
      final queue = _pharmacyRequests.where(
        (item) => item.treatmentPlanId == plan.id,
      );
      final status = plan.clinicalApprovalStatus != 'approved'
          ? RequestStatus.underReview
          : queue.isNotEmpty &&
                queue.first.status == PharmacyRequestStatus.ready
          ? RequestStatus.readyToDispense
          : RequestStatus.approved;
      final request = DemoTreatmentRequest(
        id: 'TR-${patient.id}-${plan.id}',
        patientId: patient.id,
        treatmentPlanId: plan.id,
        patientNameEn: patient.fullName,
        patientNameAr: patient.fullNameAr,
        mrn: patient.id,
        age: patient.age,
        genderEn: patient.gender,
        genderAr: patient.genderAr,
        hospitalEn: 'Programme facility',
        hospitalAr: 'منشأة البرنامج',
        diagnosisEn: patient.medicalConditions.isEmpty
            ? 'Not recorded'
            : patient.medicalConditions.first,
        diagnosisAr: patient.medicalConditionsAr.isEmpty
            ? 'غير مسجل'
            : patient.medicalConditionsAr.first,
        medication: 'Mounjaro',
        dose: plan.medicationDose,
        indicationEn: 'Treatment programme',
        indicationAr: 'برنامج العلاج',
        previousTreatmentEn: patient.doseHistory.join(' → '),
        previousTreatmentAr: patient.doseHistory.join(' ← '),
        currentMedicationEn: 'Mounjaro ${plan.medicationDose}',
        currentMedicationAr: 'مونجارو ${plan.medicationDose}',
        crp: null,
        esr: null,
        physicianReportAttached: patient.clinicalAttachments.isNotEmpty,
        recentDuplicate: isPatientInDispensingCooldown(patient),
        urgent: false,
        createdAt: plan.createdAt,
        status: status,
        criteria: const [],
        aiRecommendation: AiRecommendation.review,
        humanDecision: plan.clinicalApprovalStatus == 'approved'
            ? ReviewDecision.approve
            : null,
        approvalValidUntil: plan.clinicalApprovalStatus == 'approved'
            ? plan.prescriptionValidUntil
            : null,
      );
      _treatmentRequests.putIfAbsent(patient.id, () => []).add(request);
    }
    _refreshPharmacyQueue();
  }

  void _ensureGoldenPatientPlan() {
    if (_treatmentPlans.any((plan) => plan.patientId == 'P999')) return;
    _treatmentPlans.add(
      TreatmentPlan(
        id: 'TP-P999',
        patientId: 'P999',
        doctorName: 'Dr. Ahmed Al Mansoori',
        createdAt: DateTime(2026, 6, 1),
        medicationDose: '10 mg',
        medicationFrequencyDays: 7,
        reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
        assignedCenterId: 'T001',
        totalSessions: 4,
        sessions: [
          TherapySession(
            id: 'S-P999-1',
            sessionNumber: 1,
            scheduledDate: DateTime(2026, 10, 1, 10, 30),
          ),
        ],
        homeExercises: [],
        targetWeight: 95,
      ),
    );
  }

  void _assignPatientSpecificLabResults() {
    for (var i = 0; i < _patients.length; i++) {
      final patient = _patients[i];
      final hba1c = patient.hba1cPercent ?? (6.2 + (i % 8) * .35);
      final glucose = patient.fastingGlucoseMgDl ?? (95 + (i % 9) * 11);
      final personalized = demoLaboratoryResults.map((result) {
        final value = switch (result.testCode.isNotEmpty
            ? result.testCode
            : result.nameEn) {
          'HbA1c' => hba1c,
          'Fasting glucose' => glucose,
          _ => result.value + ((i % 5) - 2) * .8,
        };
        return PatientLabResult(
          id: 'LAB-${patient.id}-${result.nameEn.replaceAll(' ', '-').toUpperCase()}',
          patientId: patient.id,
          testCode: result.testCode.isEmpty ? result.nameEn : result.testCode,
          nameEn: result.nameEn,
          nameAr: result.nameAr,
          value: value,
          unit: result.unit,
          referenceRange: result.referenceRange,
          date: result.date,
          source: result.source,
          notes: result.notes,
          categoryEn: result.categoryEn,
          categoryAr: result.categoryAr,
          // A single dated result cannot establish a historical trend.
          trend: [value],
        );
      }).toList();
      _patients[i] = patient.copyWith(
        labResults: personalized,
        hba1cPercent: hba1c,
        fastingGlucoseMgDl: glucose,
      );
    }
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

  List<PatientDispenseRecord> _buildDispenseRecordsFromHistory(
    Patient p,
    String centerId,
  ) {
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
  List<PharmacyDispensingRequest> get pharmacyRequests =>
      List.unmodifiable(_pharmacyRequests);

  PharmacyDispensingRequest? pharmacyRequestForPatient(String patientId) {
    for (final request in _pharmacyRequests.reversed) {
      if (request.patientId == patientId &&
          request.status != PharmacyRequestStatus.dispensed &&
          request.status != PharmacyRequestStatus.cancelled) {
        return request;
      }
    }
    return null;
  }

  void _seedPharmacyRequests() {
    for (final plan in _treatmentPlans) {
      if (plan.status != 'Active') continue;
      final patient = getPatientById(plan.patientId);
      if (patient == null) continue;
      if (getPlanForPatient(patient.id)?.id != plan.id) continue;
      final centerId =
          _centers.any((center) => center.id == plan.assignedCenterId)
          ? plan.assignedCenterId!
          : (_centers.isEmpty ? '' : _centers.first.id);
      DispensingCenter? center;
      for (final item in _centers) {
        if (item.id == centerId) {
          center = item;
          break;
        }
      }
      final dose = DoseUtils.toInventoryDose(plan.medicationDose);
      final status = plan.clinicalApprovalStatus != 'approved'
          ? PharmacyRequestStatus.pendingReview
          : !patient.programEligibility.eligible
          ? PharmacyRequestStatus.notEligible
          : !plan.prescriptionValidUntil.isAfter(DateTime.now())
          ? PharmacyRequestStatus.expired
          : !_hasRequiredRecentLabs(patient)
          ? PharmacyRequestStatus.pendingReview
          : patient.isWithinDispensingCooldown(
              cooldownDays: plan.medicationFrequencyDays,
            )
          ? PharmacyRequestStatus.pendingReview
          : center == null ||
                _stockForDose(center, dose) < plan.medicationQuantity
          ? PharmacyRequestStatus.outOfStock
          : PharmacyRequestStatus.ready;
      _pharmacyRequests.add(
        PharmacyDispensingRequest(
          id: 'RXQ-${plan.id}',
          patientId: patient.id,
          treatmentPlanId: plan.id,
          treatmentRequestId: 'TR-${patient.id}-${plan.id}',
          medication: 'Mounjaro',
          dose: dose,
          quantity: plan.medicationQuantity,
          requestedAt: plan.updatedAt ?? plan.createdAt,
          assignedCenterId: centerId,
          priority: patient.programEligibility.violations.isNotEmpty,
          status: status,
        ),
      );
    }
  }

  List<PhysicalTherapyCenter> get therapyCenters => _therapyCenters;

  final List<TreatmentPlan> _treatmentPlans = List.of(MockData.treatmentPlans);
  List<TreatmentPlan> get treatmentPlans => _treatmentPlans;
  List<ActivityLog> get logs => List.unmodifiable(_logs);
  List<MedicationDoseEvent> get medicationEvents =>
      List.unmodifiable(_medicationEvents);

  List<MedicationDoseEvent> medicationEventsFor(String patientId) =>
      List.unmodifiable(
        _medicationEvents.where((event) => event.patientId == patientId),
      );

  int get totalPatientCount => _patients.length;
  int get activePatientCount =>
      _patients.where((p) => getPlanForPatient(p.id) != null).length;
  int get eligiblePatientCount =>
      _patients.where((p) => p.programEligibility.eligible).length;
  int get patientsUnderTreatmentCount => _patients
      .where((p) => getPlanForPatient(p.id)?.status == 'Active')
      .length;

  List<PatientAppointment> appointmentsFor(String patientId) =>
      List.unmodifiable(
        _appointments.putIfAbsent(patientId, () {
          final plan = getPlanForPatient(patientId);
          if (plan == null) return <PatientAppointment>[];
          return plan.sessions
              .map(
                (session) => PatientAppointment(
                  id: 'APT-$patientId-${session.sessionNumber}',
                  patientId: patientId,
                  dateTime: session.scheduledDate,
                  doctor: 'Dr Ahmed Al Mansoori',
                  purpose: 'Treatment follow-up',
                  status: session.isAttended
                      ? AppointmentStatus.completed
                      : AppointmentStatus.scheduled,
                ),
              )
              .toList();
        }),
      );

  PatientAppointment createAppointment({
    required String patientId,
    required DateTime dateTime,
    required String doctor,
    required String purpose,
  }) {
    if (!_can(AppPermission.manageAppointments)) {
      throw StateError('Appointment changes are not permitted for this role.');
    }
    final appointment = PatientAppointment(
      id: 'APT-$patientId-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      dateTime: dateTime,
      doctor: doctor,
      purpose: purpose,
    );
    _appointments.putIfAbsent(patientId, () => []).add(appointment);
    _addPatientNotification(
      patientId,
      'Appointment scheduled',
      'A treatment appointment has been added to your schedule.',
    );
    _addAppointmentAudit(patientId, 'Appointment created', 'إنشاء موعد');
    notifyListeners();
    return appointment;
  }

  void rescheduleAppointment(
    String patientId,
    String appointmentId,
    DateTime dateTime,
  ) {
    if (!_can(AppPermission.manageAppointments)) return;
    final items = _appointments.putIfAbsent(patientId, () => []);
    final index = items.indexWhere((item) => item.id == appointmentId);
    if (index < 0) return;
    items[index] = items[index].copyWith(
      dateTime: dateTime,
      status: AppointmentStatus.scheduled,
    );
    _addPatientNotification(
      patientId,
      'Appointment rescheduled',
      'Your care team changed the date of a treatment appointment.',
    );
    _addAppointmentAudit(
      patientId,
      'Appointment rescheduled',
      'إعادة جدولة موعد',
    );
    notifyListeners();
  }

  void markAppointmentMissed(String patientId, String appointmentId) {
    if (!_can(AppPermission.manageAppointments)) return;
    final items = _appointments.putIfAbsent(patientId, () => []);
    final index = items.indexWhere((item) => item.id == appointmentId);
    if (index < 0) return;
    items[index] = items[index].copyWith(status: AppointmentStatus.missed);
    _addAppointmentAudit(
      patientId,
      'Appointment marked as missed',
      'تم تسجيل الموعد كموعد فائت',
    );
    notifyListeners();
  }

  void cancelAppointment(String patientId, String appointmentId) {
    if (!_can(AppPermission.manageAppointments)) return;
    final items = _appointments.putIfAbsent(patientId, () => []);
    final index = items.indexWhere((item) => item.id == appointmentId);
    if (index < 0) return;
    items[index] = items[index].copyWith(status: AppointmentStatus.cancelled);
    _addAppointmentAudit(patientId, 'Appointment cancelled', 'إلغاء موعد');
    notifyListeners();
  }

  void _addAppointmentAudit(String patientId, String action, String actionAr) {
    final patient = getPatientById(patientId);
    if (patient == null) return;
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: patient.fullName,
        patientNameAr: patient.fullNameAr,
        patientId: patient.id,
        eventType: ActivityEventType.other,
        action: action,
        actionAr: actionAr,
        centerName: 'Patient 360',
        centerNameAr: 'سجل المريض',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );
  }

  /// Flagged / overridden events for misuse prevention log and fraud alerts.
  List<ActivityLog> get misusePreventionLogs => List.unmodifiable(
    _logs.where((l) => l.status == 'Flagged' || l.status == 'Overridden'),
  );

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
      final dose = p.doseHistory.isNotEmpty
          ? p.doseHistory.last
          : p.currentDose;
      final center =
          getDispensingCenterById(p.lastDispensingCenterId) ?? _centers.first;
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
  int countPatientsReadyToDispense() {
    // Only count patients that have an active pharmacy request AND can actually be dispensed
    int count = 0;
    for (final req in _pharmacyRequests) {
      if (req.status == PharmacyRequestStatus.dispensed ||
          req.status == PharmacyRequestStatus.cancelled) {
        continue;
      }
      final p = getPatientById(req.patientId);
      if (p != null && canDispensePatient(p)) {
        count++;
      }
    }
    return count;
  }

  DispensingValidationResult validateDispensing({
    required String patientId,
    required String centerId,
    bool hasPermission = false,
    bool isOverride = false,
  }) {
    final patient = getPatientById(patientId);
    final plan = patient == null ? null : getPlanForPatient(patient.id);
    final issues = <String>[];
    final warnings = <String>[];
    if (patient == null) {
      issues.add('Patient record was not found.');
    }
    if (plan == null) {
      issues.add('No active treatment plan exists.');
    } else {
      if (plan.clinicalApprovalStatus != 'approved') {
        issues.add('Treatment plan is awaiting clinical approval.');
      }
      if (plan.prescriptionId.trim().isEmpty ||
          !plan.prescriptionValidUntil.isAfter(DateTime.now())) {
        issues.add('Prescription is missing or expired.');
      }
      if (plan.medicationDose.trim().isEmpty ||
          !DoseUtils.planDoseOptions
              .map(DoseUtils.toInventoryDose)
              .contains(DoseUtils.toInventoryDose(plan.medicationDose))) {
        issues.add('Prescribed medication dose is missing or invalid.');
      }
      if (plan.medicationQuantity < 1) {
        issues.add('Prescription quantity is missing or invalid.');
      }
      if (plan.medicationFrequencyDays < 1) {
        issues.add('Dispensing frequency is missing or invalid.');
      }
    }
    if (patient != null) {
      if (!patient.programEligibility.eligible) {
        issues.add('Patient does not meet programme clinical eligibility.');
      }
      if (!_hasRequiredRecentLabs(patient)) {
        issues.add('Required recent laboratory results are unavailable.');
      }
      if (patient.allergies == null) {
        warnings.add(
          'Allergy information is not recorded; verify with the patient.',
        );
      } else if (patient.allergies!.any((allergy) {
        final normalized = allergy.toLowerCase();
        return normalized.contains('mounjaro') ||
            normalized.contains('tirzepatide');
      })) {
        issues.add(
          'A recorded allergy to the prescribed medication requires clinical review.',
        );
      }
      if (patient.currentMedications == null) {
        warnings.add(
          'Medication list is not recorded; interaction review is incomplete.',
        );
      } else if (patient.currentMedications!.isNotEmpty) {
        warnings.add(
          'Review the recorded medication list for potential interactions before dispensing.',
        );
      }
      if (isPatientInDispensingCooldown(patient) &&
          !_dispenseAuthorizations.contains(patient.id) &&
          !isOverride) {
        issues.add('Next dispensing window has not opened.');
      }
    }
    if (!hasPermission || !_can(AppPermission.dispenseMedication)) {
      issues.add('Current user cannot dispense medication.');
    }

    DispensingCenter? center;
    for (final item in _centers) {
      if (item.id == centerId) {
        center = item;
        break;
      }
    }
    final dose = plan == null
        ? ''
        : DoseUtils.toInventoryDose(plan.medicationDose);
    final stock = center == null ? 0 : _stockForDose(center, dose);
    if (center == null) {
      issues.add('Assigned pharmacy centre was not found.');
    } else if (plan != null && stock < plan.medicationQuantity) {
      issues.add('Insufficient in-date stock for the prescribed quantity.');
    }
    if (plan != null &&
        !_pharmacyRequests.any(
          (request) =>
              request.patientId == patientId &&
              request.treatmentPlanId == plan.id &&
              request.status == PharmacyRequestStatus.ready &&
              treatmentRequestById(request.treatmentRequestId)?.status ==
                  RequestStatus.readyToDispense,
        )) {
      issues.add(
        'No active approved dispensing request is in the pharmacy queue.',
      );
    }
    return DispensingValidationResult(
      patient: patient,
      plan: plan,
      issues: List.unmodifiable(issues),
      warnings: List.unmodifiable(warnings),
      availableStock: stock,
      normalizedDose: dose,
    );
  }

  int _stockForDose(DispensingCenter center, String dose) => center.batches
      .where(
        (batch) =>
            DoseUtils.dosesMatch(batch.dose, dose) &&
            batch.expiryDate.isAfter(DateTime.now()),
      )
      .fold(0, (total, batch) => total + batch.quantity);

  bool _hasRequiredRecentLabs(Patient patient) {
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    for (final code in const ['HbA1c', 'Fasting glucose']) {
      final valid = patient.labResults.any((lab) {
        final collected = DateTime.tryParse(lab.date);
        return lab.testCode == code &&
            collected != null &&
            !collected.isBefore(cutoff) &&
            !collected.isAfter(DateTime.now());
      });
      if (!valid) return false;
    }
    return true;
  }

  int availableStockForDose(DispensingCenter center, String dose) =>
      _stockForDose(center, dose);

  void _refreshPharmacyQueue() {
    for (var i = 0; i < _pharmacyRequests.length; i++) {
      final request = _pharmacyRequests[i];
      if (request.status == PharmacyRequestStatus.dispensed ||
          request.status == PharmacyRequestStatus.cancelled) {
        continue;
      }
      final patient = getPatientById(request.patientId);
      final plan = patient == null ? null : getPlanForPatient(patient.id);
      DispensingCenter? center;
      for (final candidate in _centers) {
        if (candidate.id == request.assignedCenterId) {
          center = candidate;
          break;
        }
      }
      var status = PharmacyRequestStatus.pendingReview;
      if (patient != null && plan != null) {
        final treatmentRequest = treatmentRequestById(
          request.treatmentRequestId,
        );
        if (treatmentRequest == null ||
            treatmentRequest.treatmentPlanId != plan.id ||
            treatmentRequest.status != RequestStatus.readyToDispense) {
          status = PharmacyRequestStatus.pendingReview;
        } else if (plan.clinicalApprovalStatus != 'approved') {
          status = PharmacyRequestStatus.pendingReview;
        } else if (!patient.programEligibility.eligible) {
          status = PharmacyRequestStatus.notEligible;
        } else if (!plan.prescriptionValidUntil.isAfter(DateTime.now())) {
          status = PharmacyRequestStatus.expired;
        } else if (!_hasRequiredRecentLabs(patient)) {
          status = PharmacyRequestStatus.pendingReview;
        } else if (patient.isWithinDispensingCooldown(
              cooldownDays: plan.medicationFrequencyDays,
            ) &&
            !_dispenseAuthorizations.contains(patient.id)) {
          status = PharmacyRequestStatus.pendingReview;
        } else if (center == null ||
            _stockForDose(center, plan.medicationDose) <
                plan.medicationQuantity) {
          status = PharmacyRequestStatus.outOfStock;
        } else {
          status = PharmacyRequestStatus.ready;
        }
      }
      _pharmacyRequests[i] = request.copyWith(status: status);
    }
  }

  List<MedicationBatch>? _consumeBatches(
    DispensingCenter center,
    String dose,
    int quantity,
  ) {
    final ordered = center.batches.map((batch) => batch.copyWith()).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    if (_stockForDose(center, dose) < quantity) return null;
    var remaining = quantity;
    final updated = <MedicationBatch>[];
    for (final batch in ordered) {
      if (remaining > 0 &&
          DoseUtils.dosesMatch(batch.dose, dose) &&
          batch.expiryDate.isAfter(DateTime.now())) {
        final used = batch.quantity < remaining ? batch.quantity : remaining;
        remaining -= used;
        if (batch.quantity > used) {
          updated.add(batch.copyWith(quantity: batch.quantity - used));
        }
      } else {
        updated.add(batch);
      }
    }
    return remaining == 0 ? updated : null;
  }

  bool canDispensePatient(
    Patient patient, {
    String? centerId,
    bool hasPermission = true,
  }) {
    final center =
        centerId ??
        patient.lastDispensingCenterId ??
        (_centers.isEmpty ? '' : _centers.first.id);
    return validateDispensing(
      patientId: patient.id,
      centerId: center,
      hasPermission: hasPermission,
    ).canDispense;
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
      if (activeTreatmentRequestFor(plan.patientId)?.status !=
          RequestStatus.underReview) {
        continue;
      }
      final p = getPatientById(plan.patientId);
      if (p == null || seen.contains(p.id)) continue;
      seen.add(p.id);
      out.add((patient: p, reviewType: 'care_plan'));
    }

    for (final patientId in _earlyDispenseReviewQueue) {
      final p = getPatientById(patientId);
      if (p == null || seen.contains(p.id)) continue;
      seen.add(p.id);
      out.add((patient: p, reviewType: 'early_dispense'));
    }

    return out;
  }

  bool approveClinicalReview(String patientId, {required AppRole actorRole}) {
    if (actorRole != AppRole.medicalReviewer &&
        actorRole != AppRole.systemAdmin) {
      return false;
    }
    final hasPendingPlan = _treatmentPlans.any(
      (plan) =>
          plan.patientId == patientId &&
          plan.clinicalApprovalStatus == 'pending_review',
    );
    final hasEarlyDispenseReview = _earlyDispenseReviewQueue.contains(
      patientId,
    );
    if (!hasPendingPlan && !hasEarlyDispenseReview) return false;
    final candidate = getPatientById(patientId);
    if (candidate == null ||
        !candidate.programEligibility.eligible ||
        !_hasRequiredRecentLabs(candidate)) {
      return false;
    }
    final treatmentRequest = activeTreatmentRequestFor(patientId);
    if (hasPendingPlan &&
        (treatmentRequest == null ||
            treatmentRequest.status != RequestStatus.underReview)) {
      return false;
    }
    for (var i = 0; i < _treatmentPlans.length; i++) {
      if (_treatmentPlans[i].patientId == patientId &&
          _treatmentPlans[i].clinicalApprovalStatus == 'pending_review') {
        _treatmentPlans[i] = _treatmentPlans[i].copyWith(
          clinicalApprovalStatus: 'approved',
        );
      }
    }
    if (hasEarlyDispenseReview) _dispenseAuthorizations.add(patientId);
    _earlyDispenseReviewQueue.remove(patientId);
    if (hasPendingPlan && treatmentRequest != null) {
      saveTreatmentRequest(
        treatmentRequest.copyWith(
          status: RequestStatus.approved,
          humanDecision: ReviewDecision.approve,
          approvalValidUntil: DateTime.now().add(const Duration(days: 30)),
          audit: [
            ...treatmentRequest.audit,
            JourneyAuditEvent(
              action: 'APPROVED',
              actor: 'Medical reviewer',
              role: actorRole.name,
              previousState: treatmentRequest.status,
              newState: RequestStatus.approved,
              timestamp: DateTime.now(),
            ),
          ],
        ),
      );
    }
    _refreshPharmacyQueue();

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
    return true;
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
    required bool authorized,
    String pharmacistNotes = '',
    String? requestId,
    String actorId = 'demo-pharmacist',
    String actorRole = 'pharmacist',
    bool isOverride = false,
  }) {
    final patientIndex = _patients.indexWhere((p) => p.id == patientId);
    final centerIndex = _centers.indexWhere((c) => c.id == centerId);

    if (patientIndex == -1 ||
        centerIndex == -1 ||
        !authorized ||
        !_can(AppPermission.dispenseMedication)) {
      return false;
    }

    final p = _patients[patientIndex];
    final c = _centers[centerIndex];
    final plan = getPlanForPatient(patientId);
    final validation = validateDispensing(
      patientId: patientId,
      centerId: centerId,
      hasPermission: authorized,
      isOverride: isOverride,
    );
    if (!validation.canDispense || plan == null) return false;
    if (!DoseUtils.dosesMatch(dose, plan.medicationDose)) return false;
    final requestIndex = requestId == null
        ? _pharmacyRequests.indexWhere(
            (r) =>
                r.patientId == patientId &&
                r.status != PharmacyRequestStatus.dispensed,
          )
        : _pharmacyRequests.indexWhere(
            (r) => r.id == requestId && r.patientId == patientId,
          );
    if (requestIndex == -1 ||
        _pharmacyRequests[requestIndex].status != PharmacyRequestStatus.ready ||
        treatmentRequestById(
              _pharmacyRequests[requestIndex].treatmentRequestId,
            )?.status !=
            RequestStatus.readyToDispense ||
        _pharmacyRequests[requestIndex].treatmentPlanId != plan.id ||
        _pharmacyRequests[requestIndex].quantity != plan.medicationQuantity ||
        !DoseUtils.dosesMatch(
          _pharmacyRequests[requestIndex].dose,
          plan.medicationDose,
        )) {
      return false;
    }
    final intervalDays = plan.medicationFrequencyDays;
    final doseToDispense = validation.normalizedDose;

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

    final quantity = plan.medicationQuantity;
    final updatedBatches = _consumeBatches(c, doseToDispense, quantity);
    if (updatedBatches == null) return false;
    if (doseToDispense == '2.5 mg' && inv25 >= quantity) {
      inv25 -= quantity;
      disp25 += quantity;
      hasInventory = true;
    } else if (doseToDispense == '5 mg' && inv5 >= quantity) {
      inv5 -= quantity;
      disp5 += quantity;
      hasInventory = true;
    } else if (doseToDispense == '7.5 mg' && inv75 >= quantity) {
      inv75 -= quantity;
      disp75 += quantity;
      hasInventory = true;
    } else if (doseToDispense == '10 mg' && inv10 >= quantity) {
      inv10 -= quantity;
      disp10 += quantity;
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
      batches: updatedBatches,
    );

    final now = DateTime.now();
    final nowStr = _formatDate(now);
    final nextStr = _nextEligibleAfter(now, intervalDays);
    final updatedDoseHistory = List<String>.from(p.doseHistory)
      ..add(doseToDispense);

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
    _pharmacyRequests[requestIndex] = _pharmacyRequests[requestIndex].copyWith(
      status: PharmacyRequestStatus.dispensed,
    );

    final treatmentRequestId =
        _pharmacyRequests[requestIndex].treatmentRequestId;
    final treatmentRequest = treatmentRequestById(treatmentRequestId);
    if (treatmentRequest != null) {
      final event = JourneyAuditEvent(
        action: 'DISPENSED',
        actor: actorId,
        role: actorRole,
        previousState: treatmentRequest.status,
        newState: RequestStatus.dispensed,
        timestamp: now,
        reason: pharmacistNotes,
      );
      final history = _treatmentRequests[treatmentRequest.patientId]!;
      final index = history.indexWhere((item) => item.id == treatmentRequestId);
      history[index] = treatmentRequest.copyWith(
        status: RequestStatus.dispensed,
        lastDispenseAt: now,
        audit: [...treatmentRequest.audit, event],
      );
      final coverage = coverageForRequest(treatmentRequestId);
      final financialIndex = _financialRecords.indexWhere(
        (item) => item.id == coverage.id,
      );
      _financialRecords[financialIndex] = coverage.copyWith(
        status: FinancialReviewStatus.settled,
      );
    }

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
        requestId: _pharmacyRequests[requestIndex].id,
        actorId: actorId,
        actorRole: actorRole,
        notes: pharmacistNotes,
      ),
    );

    _addPatientNotification(
      patientId,
      'Medication dispensed',
      'Your medication was dispensed. The next eligible refill date has been updated.',
    );

    notifyListeners();
    return true;
  }

  // Replenish inventory for a center
  void replenishInventory(
    String centerId,
    String dose,
    int amount, {
    required bool authorized,
    DateTime? expiryDate,
  }) {
    final normalizedDose = DoseUtils.toInventoryDose(dose);
    if (!authorized ||
        !_can(AppPermission.managePharmacyInventory) ||
        amount <= 0 ||
        !DoseUtils.planDoseOptions
            .map(DoseUtils.toInventoryDose)
            .contains(normalizedDose) ||
        !(expiryDate ?? DateTime.now().add(const Duration(days: 365))).isAfter(
          DateTime.now(),
        )) {
      return;
    }
    final centerIndex = _centers.indexWhere((c) => c.id == centerId);
    if (centerIndex == -1) return;

    final c = _centers[centerIndex];
    int inv25 = c.inventory2_5mg;
    int inv5 = c.inventory5mg;
    int inv75 = c.inventory7_5mg;
    int inv10 = c.inventory10mg;

    if (normalizedDose == '2.5 mg') {
      inv25 += amount;
    } else if (normalizedDose == '5 mg') {
      inv5 += amount;
    } else if (normalizedDose == '7.5 mg') {
      inv75 += amount;
    } else if (normalizedDose == '10 mg') {
      inv10 += amount;
    }

    final batchId = '$centerId-${DateTime.now().microsecondsSinceEpoch}';
    final batches = [
      ...c.batches,
      MedicationBatch(
        id: batchId,
        dose: normalizedDose,
        quantity: amount,
        expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      ),
    ];
    _centers[centerIndex] = c.copyWith(
      inventory2_5mg: inv25,
      inventory5mg: inv5,
      inventory7_5mg: inv75,
      inventory10mg: inv10,
      batches: batches,
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

    _refreshPharmacyQueue();

    notifyListeners();
  }

  // Record a Patient weight check-in (Doctor or Patient portal)
  void recordWeight(String patientId, double newWeight) {
    if (!_canRecordFor(patientId, AppPermission.recordPatientActivity) ||
        !newWeight.isFinite ||
        newWeight <= 0 ||
        newWeight > 500) {
      return;
    }
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
    if (!_can(AppPermission.createTreatmentPlan) ||
        !DoseUtils.planDoseOptions
            .map(DoseUtils.toInventoryDose)
            .contains(DoseUtils.toInventoryDose(newDose))) {
      return;
    }
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
  void addOrUpdateJourneyLabs({
    required String patientId,
    required double crp,
    required double esr,
    required DateTime collectedAt,
    required String source,
  }) {
    if (!_can(AppPermission.editLabResults) ||
        crp < 0 ||
        esr < 0 ||
        source.trim().isEmpty) {
      return;
    }
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index < 0) return;
    final patient = _patients[index];
    final date = _formatDate(collectedAt);
    final retained = patient.labResults
        .where((r) => r.testCode != 'CRP' && r.testCode != 'ESR')
        .toList();
    final added = [
      PatientLabResult(
        id: 'LAB-$patientId-CRP-${collectedAt.millisecondsSinceEpoch}',
        patientId: patientId,
        testCode: 'CRP',
        nameEn: 'CRP',
        nameAr: 'تحليل CRP',
        value: crp,
        unit: 'mg/L',
        referenceRange: '0 – 5',
        date: date,
        source: source,
        categoryEn: 'Inflammation',
        categoryAr: 'مؤشرات الالتهاب',
        trend: [crp],
      ),
      PatientLabResult(
        id: 'LAB-$patientId-ESR-${collectedAt.millisecondsSinceEpoch}',
        patientId: patientId,
        testCode: 'ESR',
        nameEn: 'ESR',
        nameAr: 'تحليل ESR',
        value: esr,
        unit: 'mm/hr',
        referenceRange: '0 – 20',
        date: date,
        source: source,
        categoryEn: 'Inflammation',
        categoryAr: 'مؤشرات الالتهاب',
        trend: [esr],
      ),
    ];
    _patients[index] = patient.copyWith(labResults: [...retained, ...added]);
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: patient.fullName,
        patientNameAr: patient.fullNameAr,
        patientId: patient.id,
        eventType: ActivityEventType.clinicalReview,
        action: 'Laboratory results added · CRP / ESR',
        actionAr: 'إضافة نتائج مختبر · CRP / ESR',
        centerName: source,
        centerNameAr: source,
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );
    notifyListeners();
  }

  void addJourneyDocument({
    required String patientId,
    required String fileName,
    required String category,
  }) {
    if (!_can(AppPermission.editDocuments)) return;
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index < 0 || fileName.trim().isEmpty) return;
    final patient = _patients[index];
    final document = PatientAttachment(
      id: 'DOC-$patientId-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName.trim(),
      mimeType: fileName.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : 'image/jpeg',
      uploadedAt: DateTime.now(),
      category: category,
    );
    _patients[index] = patient.copyWith(
      clinicalAttachments: [...patient.clinicalAttachments, document],
    );
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: patient.fullName,
        patientNameAr: patient.fullNameAr,
        patientId: patient.id,
        eventType: ActivityEventType.documentUpload,
        action: 'Document added · ${document.fileName}',
        actionAr: 'إضافة مستند · ${document.fileName}',
        centerName: 'Patient 360',
        centerNameAr: 'سجل المريض',
        timestamp: DateTime.now(),
        status: 'Success',
        statusAr: 'ناجح',
      ),
    );
    notifyListeners();
  }

  void recordJourneyAudit({
    required String patientId,
    required String action,
    required String role,
    required String status,
  }) {
    final patient = getPatientById(patientId);
    if (patient == null) return;
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG${_logs.length + 1}',
        patientName: patient.fullName,
        patientNameAr: patient.fullNameAr,
        patientId: patient.id,
        eventType: ActivityEventType.clinicalReview,
        action: '$action · $role',
        actionAr: '$action · $role',
        centerName: 'Connected treatment journey',
        centerNameAr: 'رحلة العلاج المترابطة',
        timestamp: DateTime.now(),
        status: status,
        statusAr: status,
      ),
    );
    notifyListeners();
  }

  void registerPatient(Patient newPatient) {
    if (!_can(AppPermission.editPatient) ||
        _patients.any(
          (patient) =>
              patient.id == newPatient.id ||
              patient.emiratesId == newPatient.emiratesId,
        )) {
      return;
    }
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
    if (_access != null && _access.role != AppRole.systemAdmin) return;
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
    if (_access != null && _access.role != AppRole.systemAdmin) return;
    _therapyCenters.add(center);
    notifyListeners();
  }

  // Add new Dispensing Center
  void addDispensingCenter(DispensingCenter center) {
    if (_access != null && _access.role != AppRole.systemAdmin) return;
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
  void updateInventory(
    String centerId, {
    int? d2_5,
    int? d5,
    int? d7_5,
    int? d10,
  }) {
    if (!_can(AppPermission.managePharmacyInventory)) return;
    final idx = _centers.indexWhere((c) => c.id == centerId);
    if (idx == -1) return;

    final c = _centers[idx];
    final additions = <MedicationBatch>[
      if ((d2_5 ?? 0) > 0)
        MedicationBatch(
          id: '$centerId-25-${DateTime.now().microsecondsSinceEpoch}',
          dose: '2.5 mg',
          quantity: d2_5!,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        ),
      if ((d5 ?? 0) > 0)
        MedicationBatch(
          id: '$centerId-5-${DateTime.now().microsecondsSinceEpoch}',
          dose: '5 mg',
          quantity: d5!,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        ),
      if ((d7_5 ?? 0) > 0)
        MedicationBatch(
          id: '$centerId-75-${DateTime.now().microsecondsSinceEpoch}',
          dose: '7.5 mg',
          quantity: d7_5!,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        ),
      if ((d10 ?? 0) > 0)
        MedicationBatch(
          id: '$centerId-10-${DateTime.now().microsecondsSinceEpoch}',
          dose: '10 mg',
          quantity: d10!,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        ),
    ];
    if (additions.isEmpty) return;
    _centers[idx] = c.copyWith(
      inventory2_5mg: d2_5 != null ? c.inventory2_5mg + d2_5 : null,
      inventory5mg: d5 != null ? c.inventory5mg + d5 : null,
      inventory7_5mg: d7_5 != null ? c.inventory7_5mg + d7_5 : null,
      inventory10mg: d10 != null ? c.inventory10mg + d10 : null,
      batches: [...c.batches, ...additions],
    );
    _refreshPharmacyQueue();

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
    return _patients.map((p) => p.bmi).reduce((a, b) => a + b) /
        _patients.length;
  }

  double get averageCompliance {
    if (_patients.isEmpty) return 0.0;
    return _patients.map((p) => p.complianceRate).reduce((a, b) => a + b) /
        _patients.length;
  }

  int get criticalBmiCount {
    return _patients.where((p) => p.bmi >= 35.0).length;
  }

  double get totalGovtSubsidyDisbursed {
    return _financialRecords
        .where((record) => record.status == FinancialReviewStatus.settled)
        .fold(0.0, (total, record) => total + record.coveredAed);
  }

  int get fraudIncidentsPrevented {
    return _logs
        .where((l) => l.status == 'Flagged' || l.status == 'Overridden')
        .length;
  }

  double get nationalAverageBmiDrop {
    if (_patients.isEmpty) return 0;
    final baseline =
        _patients
            .map(
              (patient) => patient.weightHistory.isEmpty
                  ? patient.bmi
                  : patient.weightHistory.first /
                        ((patient.height / 100) * (patient.height / 100)),
            )
            .reduce((a, b) => a + b) /
        _patients.length;
    return (baseline - averageBmi).clamp(0, double.infinity);
  }

  double get obesityIndexReductionPercent {
    final baseline = averageBmi + nationalAverageBmiDrop;
    if (baseline <= 0) return 0;
    return (nationalAverageBmiDrop / baseline * 100).clamp(0, 100);
  }

  void createTreatmentPlan(TreatmentPlan plan) {
    if (!_can(AppPermission.createTreatmentPlan)) return;
    final patientIndex = _patients.indexWhere((p) => p.id == plan.patientId);
    if (patientIndex == -1) return;

    final p = _patients[patientIndex];
    if (!p.programEligibility.eligible ||
        plan.medicationQuantity < 1 ||
        plan.medicationFrequencyDays < 1 ||
        !plan.prescriptionValidUntil.isAfter(DateTime.now()) ||
        !DoseUtils.planDoseOptions
            .map(DoseUtils.toInventoryDose)
            .contains(DoseUtils.toInventoryDose(plan.medicationDose))) {
      return;
    }
    final needsReview =
        p.lastDispensingDate != null &&
        p.isWithinDispensingCooldown(
          cooldownDays: plan.medicationFrequencyDays,
        );
    final planToSave = plan.copyWith(clinicalApprovalStatus: 'pending_review');

    final requestId =
        'TR-${plan.patientId}-${DateTime.now().microsecondsSinceEpoch}';
    final activeHistory = _treatmentRequests[plan.patientId];
    if (activeHistory != null && activeHistory.isNotEmpty) {
      final previous = activeHistory.last;
      if (previous.status != RequestStatus.dispensed &&
          previous.status != RequestStatus.completed &&
          previous.status != RequestStatus.cancelled &&
          previous.status != RequestStatus.rejected) {
        activeHistory[activeHistory.length - 1] = previous.copyWith(
          status: RequestStatus.cancelled,
          audit: [
            ...previous.audit,
            JourneyAuditEvent(
              action: 'SUPERSEDED_BY_NEW_PLAN',
              actor: 'Current doctor',
              role: 'doctor',
              previousState: previous.status,
              newState: RequestStatus.cancelled,
              timestamp: DateTime.now(),
              reason: 'A new treatment plan was created.',
            ),
          ],
        );
      }
    }

    _treatmentRequests
        .putIfAbsent(plan.patientId, () => [])
        .add(
          DemoTreatmentRequest(
            id: requestId,
            patientId: p.id,
            treatmentPlanId: planToSave.id,
            patientNameEn: p.fullName,
            patientNameAr: p.fullNameAr,
            mrn: p.id,
            age: p.age,
            genderEn: p.gender,
            genderAr: p.genderAr,
            hospitalEn: 'Programme facility',
            hospitalAr: 'منشأة البرنامج',
            diagnosisEn: p.medicalConditions.isEmpty
                ? 'Not recorded'
                : p.medicalConditions.first,
            diagnosisAr: p.medicalConditionsAr.isEmpty
                ? 'غير مسجل'
                : p.medicalConditionsAr.first,
            medication: 'Mounjaro',
            dose: planToSave.medicationDose,
            indicationEn: 'Treatment programme',
            indicationAr: 'برنامج العلاج',
            previousTreatmentEn: p.doseHistory.join(' → '),
            previousTreatmentAr: p.doseHistory.join(' ← '),
            currentMedicationEn: 'Mounjaro ${planToSave.medicationDose}',
            currentMedicationAr: 'مونجارو ${planToSave.medicationDose}',
            crp: null,
            esr: null,
            physicianReportAttached: p.clinicalAttachments.isNotEmpty,
            recentDuplicate: isPatientInDispensingCooldown(p),
            urgent: false,
            createdAt: DateTime.now(),
            status: RequestStatus.draft,
            criteria: const [],
            aiRecommendation: AiRecommendation.review,
          ),
        );

    _treatmentPlans.removeWhere((tp) => tp.patientId == plan.patientId);
    _treatmentPlans.add(planToSave);
    for (var i = 0; i < _pharmacyRequests.length; i++) {
      final request = _pharmacyRequests[i];
      if (request.patientId == plan.patientId &&
          request.status != PharmacyRequestStatus.dispensed &&
          request.status != PharmacyRequestStatus.cancelled) {
        _pharmacyRequests[i] = request.copyWith(
          status: PharmacyRequestStatus.cancelled,
        );
      }
    }
    final assignedCenterId =
        _centers.any((center) => center.id == planToSave.assignedCenterId)
        ? planToSave.assignedCenterId!
        : (_centers.isEmpty ? '' : _centers.first.id);
    _pharmacyRequests.add(
      PharmacyDispensingRequest(
        id: 'RXQ-$requestId',
        patientId: plan.patientId,
        treatmentPlanId: planToSave.id,
        treatmentRequestId: requestId,
        medication: 'Mounjaro',
        dose: DoseUtils.toInventoryDose(planToSave.medicationDose),
        quantity: planToSave.medicationQuantity,
        requestedAt: DateTime.now(),
        assignedCenterId: assignedCenterId,
        priority: p.programEligibility.violations.isNotEmpty,
        status: PharmacyRequestStatus.pendingReview,
      ),
    );
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
        nextEligible = _nextEligibleAfter(
          last,
          planToSave.medicationFrequencyDays,
        );
      } else {
        nextEligible = _nextEligibleAfter(
          DateTime.now(),
          planToSave.medicationFrequencyDays,
        );
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
        pendingReview: true,
      ),
    );

    _refreshPharmacyQueue();
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
      return _treatmentPlans.firstWhere(
        (p) => p.patientId == patientId && p.status == 'Active',
      );
    } catch (e) {
      return null;
    }
  }

  void checkInSession(String planId, String sessionId, double weight) {
    final plans = _treatmentPlans.where((p) => p.id == planId);
    if (plans.isEmpty || !weight.isFinite || weight <= 0 || weight > 500) {
      return;
    }
    final plan = plans.first;
    if (!_canRecordFor(plan.patientId, AppPermission.recordPatientActivity)) {
      return;
    }
    final sessions = plan.sessions.where((s) => s.id == sessionId);
    if (sessions.isEmpty || sessions.first.isAttended) return;
    final session = sessions.first;
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
      _logs.insert(
        0,
        ActivityLog(
          id: 'LOG-${DateTime.now().microsecondsSinceEpoch}',
          patientName: p.fullName,
          patientNameAr: p.fullNameAr,
          patientId: p.id,
          eventType: ActivityEventType.weightUpdate,
          action: 'Session attended · ${weight.toStringAsFixed(1)} kg recorded',
          actionAr: 'حضور جلسة · تسجيل وزن ${weight.toStringAsFixed(1)} كغ',
          centerName: 'Patient Portal',
          centerNameAr: 'بوابة المريض',
          timestamp: DateTime.now(),
          status: 'Success',
          statusAr: 'ناجح',
        ),
      );
      _addPatientNotification(
        plan.patientId,
        'Session check-in recorded',
        'Your session attendance and latest weight are now in your care record.',
      );
    }
    notifyListeners();
  }

  void logMedication(
    String planId,
    DateTime time, {
    MedicationDoseStatus status = MedicationDoseStatus.taken,
  }) {
    final matches = _treatmentPlans.where((p) => p.id == planId);
    if (matches.isEmpty ||
        !_canRecordFor(
          matches.first.patientId,
          AppPermission.recordAdherence,
        )) {
      return;
    }
    final plan = matches.first;
    final patientIndex = _patients.indexWhere((p) => p.id == plan.patientId);
    if (patientIndex < 0) return;
    final patient = _patients[patientIndex];
    final event = MedicationDoseEvent(
      id: 'MED-${plan.patientId}-${_medicationEvents.length + 1}',
      planId: planId,
      patientId: plan.patientId,
      scheduledAt: time,
      recordedAt: DateTime.now(),
      status: status,
    );
    final interval = plan.medicationFrequencyDays < 1
        ? 1
        : plan.medicationFrequencyDays;
    final slot = time.difference(plan.createdAt).inDays ~/ interval;
    final duplicateIndex = _medicationEvents.indexWhere(
      (existing) =>
          existing.planId == planId &&
          existing.scheduledAt.difference(plan.createdAt).inDays ~/ interval ==
              slot,
    );
    if (duplicateIndex >= 0) {
      final prior = _medicationEvents[duplicateIndex];
      _medicationEvents.removeAt(duplicateIndex);
      _medicationEvents.insert(
        0,
        MedicationDoseEvent(
          id: prior.id,
          planId: planId,
          patientId: plan.patientId,
          scheduledAt: prior.scheduledAt,
          recordedAt: DateTime.now(),
          status: status,
        ),
      );
    } else {
      _medicationEvents.insert(0, event);
    }

    final patientEvents = medicationEventsFor(plan.patientId);
    final taken = patientEvents
        .where((e) => e.status == MedicationDoseStatus.taken)
        .length;
    final adherence = patientEvents.isEmpty
        ? 0.0
        : taken / patientEvents.length;
    _patients[patientIndex] = patient.copyWith(complianceRate: adherence);

    final label = switch (status) {
      MedicationDoseStatus.taken => (
        'Medication taken',
        'تم تناول الدواء',
        'Success',
        'ناجح',
      ),
      MedicationDoseStatus.skipped => (
        'Medication skipped',
        'تم تخطي الجرعة',
        'Skipped',
        'تم التخطي',
      ),
      MedicationDoseStatus.missed => (
        'Medication missed',
        'فات موعد الجرعة',
        'Missed',
        'فائت',
      ),
    };
    _logs.insert(
      0,
      ActivityLog(
        id: 'LOG-${DateTime.now().microsecondsSinceEpoch}',
        patientName: patient.fullName,
        patientNameAr: patient.fullNameAr,
        patientId: patient.id,
        eventType: ActivityEventType.medicationAdherence,
        action: '${label.$1} · ${plan.medicationDose}',
        actionAr: '${label.$2} · ${plan.medicationDose}',
        centerName: 'Patient Portal',
        centerNameAr: 'بوابة المريض',
        timestamp: event.recordedAt,
        status: label.$3,
        statusAr: label.$4,
      ),
    );
    if (status == MedicationDoseStatus.missed) {
      _addPatientNotification(
        patient.id,
        'Missed dose recorded',
        'Your care team can see the missed dose. Review the next scheduled dose in your plan.',
      );
    }
    notifyListeners();
  }

  void completeExercise(String planId, String exerciseId) {
    final plans = _treatmentPlans.where((p) => p.id == planId);
    if (plans.isEmpty) return;
    final plan = plans.first;
    if (!_canRecordFor(plan.patientId, AppPermission.recordPatientActivity)) {
      return;
    }
    final exercises = plan.homeExercises.where((e) => e.id == exerciseId);
    if (exercises.isEmpty) return;
    final ex = exercises.first;
    final today = DateTime.now();
    if (ex.completedDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    )) {
      return;
    }
    ex.completedDates.add(today);
    final patient = getPatientById(plan.patientId);
    if (patient != null) {
      _logs.insert(
        0,
        ActivityLog(
          id: 'LOG-${DateTime.now().microsecondsSinceEpoch}',
          patientName: patient.fullName,
          patientNameAr: patient.fullNameAr,
          patientId: patient.id,
          eventType: ActivityEventType.other,
          action: 'Home exercise completed · ${ex.name}',
          actionAr: 'تم إكمال تمرين منزلي · ${ex.nameAr}',
          centerName: 'Patient Portal',
          centerNameAr: 'بوابة المريض',
          timestamp: today,
          status: 'Success',
          statusAr: 'ناجح',
        ),
      );
    }
    notifyListeners();
  }
}
