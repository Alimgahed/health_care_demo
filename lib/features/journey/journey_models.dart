enum RequestStatus {
  draft,
  submitted,
  assessing,
  needsInformation,
  underReview,
  approved,
  rejected,
  readyToDispense,
  dispensed,
  monitoring,
  renewalDue,
  completed,
  expired,
  cancelled,
}

enum CriterionResult { pass, fail, missing, warning, notApplicable }

enum AiRecommendation { approve, review, moreInformation }

enum ReviewDecision { approve, reject, moreInformation }

enum DemoScenario {
  successfulApproval,
  missingLaboratory,
  duplicateMedication,
  aiWarning,
  humanOverride,
  rejectedRequest,
  urgentCase,
}

class EligibilityCriterion {
  final String id;
  final String labelEn;
  final String labelAr;
  final String evidenceEn;
  final String evidenceAr;
  final String explanationEn;
  final String explanationAr;
  final CriterionResult result;

  const EligibilityCriterion({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.evidenceEn,
    required this.evidenceAr,
    required this.explanationEn,
    required this.explanationAr,
    required this.result,
  });
}

class JourneyAuditEvent {
  final String action;
  final String actor;
  final String role;
  final RequestStatus? previousState;
  final RequestStatus newState;
  final DateTime timestamp;
  final String reason;
  final AiRecommendation? aiRecommendation;
  final ReviewDecision? humanDecision;

  const JourneyAuditEvent({
    required this.action,
    required this.actor,
    required this.role,
    required this.previousState,
    required this.newState,
    required this.timestamp,
    this.reason = '',
    this.aiRecommendation,
    this.humanDecision,
  });
}

class DemoTreatmentRequest {
  final String id;
  final String patientId;
  final String treatmentPlanId;
  final String patientNameEn;
  final String patientNameAr;
  final String mrn;
  final int age;
  final String genderEn;
  final String genderAr;
  final String hospitalEn;
  final String hospitalAr;
  final String diagnosisEn;
  final String diagnosisAr;
  final String medication;
  final String dose;
  final String indicationEn;
  final String indicationAr;
  final String previousTreatmentEn;
  final String previousTreatmentAr;
  final String currentMedicationEn;
  final String currentMedicationAr;
  final double? crp;
  final double? esr;
  final bool physicianReportAttached;
  final bool recentDuplicate;
  final bool urgent;
  final DateTime createdAt;
  final DateTime? approvalValidUntil;
  final DateTime? lastDispenseAt;
  final DateTime? followUpAt;
  final int adherencePercent;
  final String monitoringObservationEn;
  final String monitoringObservationAr;
  final RequestStatus status;
  final List<EligibilityCriterion> criteria;
  final AiRecommendation aiRecommendation;
  final ReviewDecision? humanDecision;
  final String reviewerNote;
  final String overrideReason;
  final List<JourneyAuditEvent> audit;

  const DemoTreatmentRequest({
    required this.id,
    required this.patientId,
    this.treatmentPlanId = '',
    required this.patientNameEn,
    required this.patientNameAr,
    required this.mrn,
    required this.age,
    required this.genderEn,
    required this.genderAr,
    required this.hospitalEn,
    required this.hospitalAr,
    required this.diagnosisEn,
    required this.diagnosisAr,
    required this.medication,
    required this.dose,
    required this.indicationEn,
    required this.indicationAr,
    required this.previousTreatmentEn,
    required this.previousTreatmentAr,
    required this.currentMedicationEn,
    required this.currentMedicationAr,
    required this.crp,
    required this.esr,
    required this.physicianReportAttached,
    required this.recentDuplicate,
    required this.urgent,
    required this.createdAt,
    required this.status,
    required this.criteria,
    required this.aiRecommendation,
    this.approvalValidUntil,
    this.lastDispenseAt,
    this.followUpAt,
    this.adherencePercent = 0,
    this.monitoringObservationEn = '',
    this.monitoringObservationAr = '',
    this.humanDecision,
    this.reviewerNote = '',
    this.overrideReason = '',
    this.audit = const [],
  });

  DemoTreatmentRequest copyWith({
    RequestStatus? status,
    List<EligibilityCriterion>? criteria,
    AiRecommendation? aiRecommendation,
    ReviewDecision? humanDecision,
    String? reviewerNote,
    String? overrideReason,
    DateTime? approvalValidUntil,
    DateTime? lastDispenseAt,
    DateTime? followUpAt,
    int? adherencePercent,
    String? monitoringObservationEn,
    String? monitoringObservationAr,
    List<JourneyAuditEvent>? audit,
    double? crp,
    double? esr,
    bool? physicianReportAttached,
  }) => DemoTreatmentRequest(
    id: id,
    patientId: patientId,
    treatmentPlanId: treatmentPlanId,
    patientNameEn: patientNameEn,
    patientNameAr: patientNameAr,
    mrn: mrn,
    age: age,
    genderEn: genderEn,
    genderAr: genderAr,
    hospitalEn: hospitalEn,
    hospitalAr: hospitalAr,
    diagnosisEn: diagnosisEn,
    diagnosisAr: diagnosisAr,
    medication: medication,
    dose: dose,
    indicationEn: indicationEn,
    indicationAr: indicationAr,
    previousTreatmentEn: previousTreatmentEn,
    previousTreatmentAr: previousTreatmentAr,
    currentMedicationEn: currentMedicationEn,
    currentMedicationAr: currentMedicationAr,
    crp: crp ?? this.crp,
    esr: esr ?? this.esr,
    physicianReportAttached:
        physicianReportAttached ?? this.physicianReportAttached,
    recentDuplicate: recentDuplicate,
    urgent: urgent,
    createdAt: createdAt,
    approvalValidUntil: approvalValidUntil ?? this.approvalValidUntil,
    lastDispenseAt: lastDispenseAt ?? this.lastDispenseAt,
    followUpAt: followUpAt ?? this.followUpAt,
    adherencePercent: adherencePercent ?? this.adherencePercent,
    monitoringObservationEn:
        monitoringObservationEn ?? this.monitoringObservationEn,
    monitoringObservationAr:
        monitoringObservationAr ?? this.monitoringObservationAr,
    status: status ?? this.status,
    criteria: criteria ?? this.criteria,
    aiRecommendation: aiRecommendation ?? this.aiRecommendation,
    humanDecision: humanDecision ?? this.humanDecision,
    reviewerNote: reviewerNote ?? this.reviewerNote,
    overrideReason: overrideReason ?? this.overrideReason,
    audit: audit ?? this.audit,
  );
}

class TransitionResult {
  final bool success;
  final String message;
  const TransitionResult(this.success, this.message);
}
