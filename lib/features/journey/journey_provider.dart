import 'package:flutter/foundation.dart';

import '../../core/demo/demo_clock.dart';
import '../../core/constants/mock_data.dart';
import '../../core/auth/access_control.dart';
import 'journey_models.dart';

class JourneyProvider extends ChangeNotifier {
  JourneyProvider({DataProvider? dataProvider, AccessControlProvider? access})
    : _access = access {
    loadScenario(DemoScenario.successfulApproval);
    if (dataProvider != null) {
      attach(dataProvider, access ?? AccessControlProvider());
    }
  }

  DemoScenario _scenario = DemoScenario.successfulApproval;
  late DemoTreatmentRequest _request;
  DataProvider? _dataProvider;
  AccessControlProvider? _access;
  final Map<String, List<DemoTreatmentRequest>> _localRequestsByPatient = {};
  Map<String, List<DemoTreatmentRequest>> get _requestsByPatient =>
      _dataProvider?.treatmentRequestHistory ?? _localRequestsByPatient;

  void attach(DataProvider dataProvider, AccessControlProvider access) {
    if (identical(_dataProvider, dataProvider) && identical(_access, access)) {
      return;
    }
    _dataProvider?.removeListener(_syncFromStore);
    _dataProvider = dataProvider;
    _access = access;
    dataProvider.addListener(_syncFromStore);
    _syncFromStore();
  }

  void _syncFromStore() {
    final latest = _dataProvider?.activeTreatmentRequestFor(_request.patientId);
    if (latest != null && latest.id != _request.id) {
      _request = latest;
      notifyListeners();
      return;
    }
    final stored = _dataProvider?.treatmentRequestById(_request.id);
    if (stored != null && !identical(stored, _request)) {
      _request = stored;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dataProvider?.removeListener(_syncFromStore);
    super.dispose();
  }

  void _replaceHistory(String patientId, List<DemoTreatmentRequest> history) {
    final data = _dataProvider;
    if (data == null) {
      _localRequestsByPatient[patientId] = List.of(history);
    } else {
      data.replaceTreatmentRequestHistory(patientId, history);
    }
  }

  DemoScenario get scenario => _scenario;
  DemoTreatmentRequest get request => _request;
  List<DemoTreatmentRequest> get requests =>
      List.unmodifiable(_requestsByPatient.values.expand((items) => items));

  List<DemoTreatmentRequest> historyForPatient(String patientId) =>
      List.unmodifiable(_requestsByPatient[patientId] ?? const []);

  bool can(AppPermission permission) => _access?.can(permission) ?? true;

  TransitionResult _denied(AppPermission permission) {
    _appendAudit(
      'ACCESS_DENIED',
      'Current user',
      _access?.role.name ?? 'unknown',
      reason: 'Missing permission: ${permission.name}',
    );
    return TransitionResult(false, 'Permission denied: ${permission.name}.');
  }

  /// Connects the journey workspace to the real patient selected in the
  /// existing registry. No second patient record is created.
  void bindExistingPatient(Patient patient) {
    final existing = _requestsByPatient[patient.id];
    if (existing != null && existing.isNotEmpty) {
      _request = existing.last;
      notifyListeners();
      return;
    }
    final eligibility = patient.programEligibility;
    final criteria = <EligibilityCriterion>[
      _criterion(
        'age',
        'Patient criteria',
        'معايير المريض',
        '${patient.age} years',
        '${patient.age} سنة',
        patient.age >= 18 ? CriterionResult.pass : CriterionResult.fail,
        'Adult patient requirement.',
        'شرط بلوغ المريض سن الرشد.',
      ),
      _criterion(
        'diagnosis',
        'Diagnosis criteria',
        'معايير التشخيص',
        patient.medicalConditions.isEmpty
            ? 'Missing'
            : patient.medicalConditions.join(', '),
        patient.medicalConditionsAr.isEmpty
            ? 'غير متوفر'
            : patient.medicalConditionsAr.join('، '),
        patient.medicalConditions.isEmpty
            ? CriterionResult.missing
            : CriterionResult.pass,
        'Diagnosis is read from the existing patient record.',
        'تمت قراءة التشخيص من سجل المريض الحالي.',
      ),
      _criterion(
        'bmi',
        'BMI programme criterion',
        'معيار مؤشر كتلة الجسم',
        patient.bmi.toStringAsFixed(1),
        patient.bmi.toStringAsFixed(1),
        eligibility.violations.any((v) => v.code.name == 'bmiTooLow')
            ? CriterionResult.fail
            : CriterionResult.pass,
        'BMI is evaluated by the configured local programme rule.',
        'تم تقييم مؤشر كتلة الجسم بواسطة قاعدة البرنامج المحلية.',
      ),
      _criterion(
        'hba1c',
        'HbA1c laboratory result',
        'نتيجة HbA1c',
        patient.hba1cPercent == null ? 'Missing' : '${patient.hba1cPercent}%',
        patient.hba1cPercent == null ? 'غير متوفر' : '${patient.hba1cPercent}٪',
        patient.hba1cPercent == null
            ? CriterionResult.missing
            : (eligibility.violations.any((v) => v.code.name == 'hba1cTooHigh')
                  ? CriterionResult.warning
                  : CriterionResult.pass),
        'Latest value from the existing patient record.',
        'أحدث قيمة من سجل المريض الحالي.',
      ),
      _criterion(
        'glucose',
        'Fasting glucose',
        'سكر صائم',
        patient.fastingGlucoseMgDl == null
            ? 'Missing'
            : '${patient.fastingGlucoseMgDl} mg/dL',
        patient.fastingGlucoseMgDl == null
            ? 'غير متوفر'
            : '${patient.fastingGlucoseMgDl} ملغم/ديسيلتر',
        patient.fastingGlucoseMgDl == null
            ? CriterionResult.missing
            : (eligibility.violations.any(
                    (v) => v.code.name == 'glucoseTooHigh',
                  )
                  ? CriterionResult.warning
                  : CriterionResult.pass),
        'Latest value from the existing patient record.',
        'أحدث قيمة من سجل المريض الحالي.',
      ),
      _criterion(
        'duplicate',
        'Duplicate medication check',
        'فحص تكرار الدواء',
        patient.isWithinDispensingCooldown()
            ? 'Recent dispense found'
            : 'No recent duplicate found',
        patient.isWithinDispensingCooldown()
            ? 'يوجد صرف حديث'
            : 'لا يوجد صرف مكرر حديث',
        patient.isWithinDispensingCooldown()
            ? CriterionResult.warning
            : CriterionResult.pass,
        'Uses the existing dispensing history.',
        'يعتمد على سجل الصرف الحالي.',
      ),
      _criterion(
        'documents',
        'Required documentation',
        'المستندات المطلوبة',
        patient.clinicalAttachments.isEmpty
            ? 'No attachment on file'
            : '${patient.clinicalAttachments.length} attachment(s)',
        patient.clinicalAttachments.isEmpty
            ? 'لا توجد مرفقات'
            : '${patient.clinicalAttachments.length} مرفقات',
        patient.clinicalAttachments.isEmpty
            ? CriterionResult.warning
            : CriterionResult.pass,
        'Documents are read from the same patient record.',
        'تمت قراءة المستندات من سجل المريض نفسه.',
      ),
    ];
    final hasMissing = criteria.any((c) => c.result == CriterionResult.missing);
    final hasConcern = criteria.any(
      (c) =>
          c.result == CriterionResult.fail ||
          c.result == CriterionResult.warning,
    );
    _scenario = hasMissing
        ? DemoScenario.missingLaboratory
        : (hasConcern
              ? DemoScenario.aiWarning
              : DemoScenario.successfulApproval);
    _request = DemoTreatmentRequest(
      id: 'TR-${patient.id}-01',
      patientId: patient.id,
      treatmentPlanId: _dataProvider?.getPlanForPatient(patient.id)?.id ?? '',
      patientNameEn: patient.fullName,
      patientNameAr: patient.fullNameAr,
      mrn: patient.id,
      age: patient.age,
      genderEn: patient.gender,
      genderAr: patient.genderAr,
      hospitalEn: 'Existing programme facility',
      hospitalAr: 'منشأة البرنامج الحالية',
      diagnosisEn: patient.medicalConditions.isEmpty
          ? 'Not recorded'
          : patient.medicalConditions.first,
      diagnosisAr: patient.medicalConditionsAr.isEmpty
          ? 'غير مسجل'
          : patient.medicalConditionsAr.first,
      medication: 'Mounjaro',
      dose: patient.currentDose,
      indicationEn: 'Existing medication programme',
      indicationAr: 'برنامج الدواء الحالي',
      previousTreatmentEn: patient.doseHistory.isEmpty
          ? 'Not recorded'
          : patient.doseHistory.join(' → '),
      previousTreatmentAr: patient.doseHistory.isEmpty
          ? 'غير مسجل'
          : patient.doseHistory.join(' ← '),
      currentMedicationEn: 'Mounjaro ${patient.currentDose}',
      currentMedicationAr: 'مونجارو ${patient.currentDose}',
      crp: null,
      esr: null,
      physicianReportAttached: patient.clinicalAttachments.isNotEmpty,
      recentDuplicate: patient.isWithinDispensingCooldown(),
      urgent: false,
      createdAt: DemoClock.daysAgo(3),
      status: RequestStatus.draft,
      criteria: criteria,
      aiRecommendation: hasMissing
          ? AiRecommendation.moreInformation
          : (hasConcern ? AiRecommendation.review : AiRecommendation.approve),
      audit: [
        JourneyAuditEvent(
          action: 'PATIENT_WORKSPACE_OPENED',
          actor: 'Current doctor',
          role: 'Doctor',
          previousState: null,
          newState: RequestStatus.draft,
          timestamp: DemoClock.now,
        ),
      ],
    );
    _replaceHistory(patient.id, [_request]);
    notifyListeners();
  }

  TransitionResult createRequestForPatient(Patient patient) {
    if (!can(AppPermission.createTreatmentRequest)) {
      return _denied(AppPermission.createTreatmentRequest);
    }
    final history = List<DemoTreatmentRequest>.from(
      _requestsByPatient[patient.id] ?? const [],
    );
    if (history.isNotEmpty &&
        !const [
          RequestStatus.completed,
          RequestStatus.rejected,
          RequestStatus.expired,
          RequestStatus.cancelled,
          RequestStatus.dispensed,
        ].contains(history.last.status)) {
      return const TransitionResult(
        false,
        'An active treatment request already exists.',
      );
    }
    if (history.isEmpty) bindExistingPatient(patient);
    final fresh = _request;
    _request = DemoTreatmentRequest(
      id: 'TR-${patient.id}-${(history.length + 1).toString().padLeft(2, '0')}',
      patientId: fresh.patientId,
      treatmentPlanId:
          _dataProvider?.getPlanForPatient(patient.id)?.id ??
          fresh.treatmentPlanId,
      patientNameEn: fresh.patientNameEn,
      patientNameAr: fresh.patientNameAr,
      mrn: fresh.mrn,
      age: fresh.age,
      genderEn: fresh.genderEn,
      genderAr: fresh.genderAr,
      hospitalEn: fresh.hospitalEn,
      hospitalAr: fresh.hospitalAr,
      diagnosisEn: fresh.diagnosisEn,
      diagnosisAr: fresh.diagnosisAr,
      medication: fresh.medication,
      dose: fresh.dose,
      indicationEn: fresh.indicationEn,
      indicationAr: fresh.indicationAr,
      previousTreatmentEn: fresh.previousTreatmentEn,
      previousTreatmentAr: fresh.previousTreatmentAr,
      currentMedicationEn: fresh.currentMedicationEn,
      currentMedicationAr: fresh.currentMedicationAr,
      crp: fresh.crp,
      esr: fresh.esr,
      physicianReportAttached: fresh.physicianReportAttached,
      recentDuplicate: fresh.recentDuplicate,
      urgent: fresh.urgent,
      createdAt: DemoClock.now,
      status: RequestStatus.draft,
      criteria: fresh.criteria,
      aiRecommendation: fresh.aiRecommendation,
      audit: const [],
    );
    _replaceHistory(patient.id, [...history, _request]);
    _appendAudit(
      'TREATMENT_REQUEST_CREATED',
      'Current user',
      _access?.role.name ?? 'systemAdmin',
    );
    return const TransitionResult(true, 'Treatment request created.');
  }

  int get totalRequests => requests.length;
  int get approvedRequests => requests
      .where(
        (r) =>
            r.status == RequestStatus.approved ||
            r.status == RequestStatus.readyToDispense ||
            r.status == RequestStatus.dispensed ||
            r.status == RequestStatus.monitoring ||
            r.status == RequestStatus.renewalDue ||
            r.status == RequestStatus.completed,
      )
      .length;
  int get rejectedRequests =>
      requests.where((r) => r.status == RequestStatus.rejected).length;
  int get pendingRequests => requests
      .where(
        (r) =>
            r.status != RequestStatus.rejected &&
            r.status != RequestStatus.completed &&
            r.status != RequestStatus.cancelled &&
            r.status != RequestStatus.expired,
      )
      .length;
  int get dispensedRequests => requests
      .where(
        (r) =>
            r.status == RequestStatus.dispensed ||
            r.status == RequestStatus.monitoring ||
            r.status == RequestStatus.renewalDue ||
            r.status == RequestStatus.completed,
      )
      .length;
  double get approvalRate =>
      totalRequests == 0 ? 0 : approvedRequests / totalRequests;

  static const Map<RequestStatus, Set<RequestStatus>> _allowed = {
    RequestStatus.draft: {RequestStatus.submitted},
    RequestStatus.submitted: {RequestStatus.assessing},
    RequestStatus.assessing: {
      RequestStatus.needsInformation,
      RequestStatus.underReview,
    },
    RequestStatus.needsInformation: {RequestStatus.submitted},
    RequestStatus.underReview: {
      RequestStatus.approved,
      RequestStatus.rejected,
      RequestStatus.needsInformation,
    },
    RequestStatus.approved: {RequestStatus.readyToDispense},
    RequestStatus.readyToDispense: {RequestStatus.dispensed},
    RequestStatus.dispensed: {RequestStatus.monitoring},
    RequestStatus.monitoring: {
      RequestStatus.renewalDue,
      RequestStatus.completed,
    },
    RequestStatus.renewalDue: {
      RequestStatus.monitoring,
      RequestStatus.completed,
    },
    RequestStatus.rejected: {},
    RequestStatus.completed: {},
    RequestStatus.expired: {},
    RequestStatus.cancelled: {},
  };

  void loadScenario(DemoScenario value) {
    DemoClock.reset();
    _scenario = value;
    _request = _seed(value);
    _replaceHistory(_request.patientId, [_request]);
    notifyListeners();
  }

  TransitionResult submit() {
    if (!can(AppPermission.createTreatmentRequest)) {
      return _denied(AppPermission.createTreatmentRequest);
    }
    if (_request.status != RequestStatus.draft &&
        _request.status != RequestStatus.needsInformation) {
      return const TransitionResult(false, 'Request is not editable.');
    }
    if (_dataProvider != null &&
        (_request.treatmentPlanId.isEmpty ||
            _dataProvider?.getPlanForPatient(_request.patientId)?.id !=
                _request.treatmentPlanId)) {
      return const TransitionResult(
        false,
        'Create an active treatment plan before submitting the request.',
      );
    }
    return _move(
      RequestStatus.submitted,
      'REQUEST_SUBMITTED',
      'Dr. Maya Hassan',
      'Doctor',
    );
  }

  TransitionResult evaluate() {
    if (!can(AppPermission.reviewEligibility)) {
      return _denied(AppPermission.reviewEligibility);
    }
    if (_request.status != RequestStatus.submitted) {
      return const TransitionResult(
        false,
        'Only submitted requests can be assessed.',
      );
    }
    final start = _move(
      RequestStatus.assessing,
      'ELIGIBILITY_EVALUATION_STARTED',
      'Demo rule engine',
      'System',
    );
    if (!start.success) return start;
    final criteria = _evaluate(_request);
    final hasMissing = criteria.any((c) => c.result == CriterionResult.missing);
    final hasFail = criteria.any((c) => c.result == CriterionResult.fail);
    final hasWarning = criteria.any((c) => c.result == CriterionResult.warning);
    final recommendation = hasMissing
        ? AiRecommendation.moreInformation
        : (hasFail || hasWarning
              ? AiRecommendation.review
              : AiRecommendation.approve);
    _request = _request.copyWith(
      criteria: criteria,
      aiRecommendation: recommendation,
    );
    _appendAudit(
      'AI_RECOMMENDATION_GENERATED',
      'Simulated AI assistant',
      'Decision Support',
    );
    if (hasMissing) {
      return _move(
        RequestStatus.needsInformation,
        'MORE_INFORMATION_REQUIRED',
        'Demo rule engine',
        'System',
        reason: 'Mandatory evidence is missing.',
      );
    }
    return _move(
      RequestStatus.underReview,
      'REVIEW_STARTED',
      'Dr. Omar Al Nuaimi',
      'Medical Reviewer',
    );
  }

  TransitionResult review(ReviewDecision decision, {required String reason}) {
    final permission = decision == ReviewDecision.reject
        ? AppPermission.rejectTreatment
        : AppPermission.approveTreatment;
    if (!can(permission)) return _denied(permission);
    if (_request.status != RequestStatus.underReview) {
      return const TransitionResult(
        false,
        'Only a request under review can receive a decision.',
      );
    }
    if (decision != ReviewDecision.approve && reason.trim().isEmpty) {
      return const TransitionResult(
        false,
        'A reason is required for this decision.',
      );
    }
    final override =
        (decision == ReviewDecision.approve &&
            _request.aiRecommendation != AiRecommendation.approve) ||
        (decision == ReviewDecision.reject &&
            _request.aiRecommendation == AiRecommendation.approve);
    if (override && reason.trim().isEmpty) {
      return const TransitionResult(false, 'An override reason is required.');
    }
    if (decision == ReviewDecision.approve &&
        _dataProvider != null &&
        !_dataProvider!.approveTreatmentRequest(
          _request.id,
          actorRole: _access?.role ?? AppRole.patient,
        )) {
      return const TransitionResult(
        false,
        'The plan, eligibility, or required laboratory results need review.',
      );
    }
    final next = switch (decision) {
      ReviewDecision.approve => RequestStatus.approved,
      ReviewDecision.reject => RequestStatus.rejected,
      ReviewDecision.moreInformation => RequestStatus.needsInformation,
    };
    _request = _request.copyWith(
      humanDecision: decision,
      reviewerNote: reason,
      overrideReason: override ? reason : '',
      approvalValidUntil: decision == ReviewDecision.approve
          ? DemoClock.daysFromNow(30)
          : null,
    );
    final result = _move(
      next,
      decision.name.toUpperCase(),
      'Dr. Omar Al Nuaimi',
      'Medical Reviewer',
      reason: reason,
    );
    if (override) {
      _appendAudit(
        'AI_OVERRIDE',
        'Dr. Omar Al Nuaimi',
        'Medical Reviewer',
        reason: reason,
      );
    }
    return result;
  }

  TransitionResult markReadyForDispensing() {
    if (!can(AppPermission.sendToPharmacy)) {
      return _denied(AppPermission.sendToPharmacy);
    }
    if (_request.status != RequestStatus.approved) {
      return const TransitionResult(
        false,
        'Only approved requests can enter the pharmacy queue.',
      );
    }
    if (_request.approvalValidUntil == null ||
        _request.approvalValidUntil!.isBefore(DemoClock.now)) {
      return const TransitionResult(false, 'Approval is missing or expired.');
    }
    if (_dataProvider != null) {
      final issues = _dataProvider!.pharmacyReleaseIssues(_request.id);
      if (issues.isNotEmpty) return TransitionResult(false, issues.join(' '));
    }
    return _move(
      RequestStatus.readyToDispense,
      'PHARMACY_QUEUE_ENTERED',
      'Demo workflow',
      'System',
    );
  }

  List<String> pharmacySafetyIssues() {
    final issues = <String>[];
    if (_request.status != RequestStatus.readyToDispense) {
      issues.add('Request is not ready to dispense.');
    }
    if (_request.humanDecision != ReviewDecision.approve) {
      issues.add('Human approval is missing.');
    }
    if (_request.approvalValidUntil == null ||
        _request.approvalValidUntil!.isBefore(DemoClock.now)) {
      issues.add('Approval is expired or invalid.');
    }
    if (!_request.physicianReportAttached) {
      issues.add('Required physician report is missing.');
    }
    if (_request.recentDuplicate) {
      issues.add(
        'Recent duplicate medication activity requires authorized resolution.',
      );
    }
    return issues;
  }

  TransitionResult dispense({String overrideReason = ''}) {
    if (!can(AppPermission.dispenseMedication)) {
      return _denied(AppPermission.dispenseMedication);
    }
    if (_request.status != RequestStatus.readyToDispense) {
      return const TransitionResult(
        false,
        'Dispensing requires READY_TO_DISPENSE status.',
      );
    }
    final issues = pharmacySafetyIssues();
    if (issues.isNotEmpty && overrideReason.trim().isEmpty) {
      return TransitionResult(false, issues.join(' '));
    }
    final data = _dataProvider;
    if (data != null) {
      final center = data.centers.isEmpty ? null : data.centers.first;
      if (center == null ||
          !data.dispenseMedication(
            patientId: _request.patientId,
            centerId: center.id,
            dose: _request.dose,
            authorized: true,
            requestId: data.pharmacyRequestForPatient(_request.patientId)?.id,
            isOverride: overrideReason.trim().isNotEmpty,
          )) {
        return const TransitionResult(
          false,
          'Dispensing failed: eligibility, refill interval, or inventory check.',
        );
      }
      final updated = data.treatmentRequestById(_request.id);
      if (updated != null) _request = updated;
      return const TransitionResult(true, 'Medication dispensed.');
    }
    _request = _request.copyWith(
      lastDispenseAt: DemoClock.now,
      overrideReason: overrideReason,
    );
    return _move(
      RequestStatus.dispensed,
      'DISPENSED',
      'Layla Al Hashimi',
      'Pharmacist',
      reason: overrideReason,
    );
  }

  TransitionResult startMonitoring() {
    if (!can(AppPermission.startFollowUp)) {
      return _denied(AppPermission.startFollowUp);
    }
    if (_request.status != RequestStatus.dispensed) {
      return const TransitionResult(
        false,
        'Monitoring starts after dispensing.',
      );
    }
    _request = _request.copyWith(
      followUpAt: DemoClock.daysFromNow(14),
      adherencePercent: _dataProvider
          ?.getPatientById(_request.patientId)
          ?.complianceRate
          .round(),
      monitoringObservationEn:
          'Follow-up is scheduled. Review adherence and laboratory results at the next visit.',
      monitoringObservationAr:
          'تم تحديد موعد المتابعة. راجع الالتزام ونتائج التحاليل في الزيارة القادمة.',
    );
    return _move(
      RequestStatus.monitoring,
      'MONITORING_STARTED',
      'Dr. Maya Hassan',
      'Doctor',
    );
  }

  TransitionResult completeTreatment({String reason = 'Treatment goals met'}) {
    if (!can(AppPermission.startFollowUp)) {
      return _denied(AppPermission.startFollowUp);
    }
    if (_request.status != RequestStatus.monitoring &&
        _request.status != RequestStatus.renewalDue) {
      return const TransitionResult(
        false,
        'Only monitored treatment can be completed.',
      );
    }
    return _move(
      RequestStatus.completed,
      'TREATMENT_COMPLETED',
      'Current clinician',
      _access?.role.name ?? 'careCoordinator',
      reason: reason,
    );
  }

  TransitionResult markRenewalDue() {
    if (!can(AppPermission.startFollowUp)) {
      return _denied(AppPermission.startFollowUp);
    }
    if (_request.status != RequestStatus.monitoring) {
      return const TransitionResult(
        false,
        'Renewal is due only during active monitoring.',
      );
    }
    return _move(
      RequestStatus.renewalDue,
      'TREATMENT_RENEWAL_DUE',
      'Demo workflow',
      'System',
      reason: 'Follow-up and continuation decision are due.',
    );
  }

  void recordMedicationAdherence(
    String patientId,
    MedicationDoseStatus status,
  ) {
    final history = _requestsByPatient[patientId];
    if (history == null || history.isEmpty) return;
    _request = history.last;
    final patient = _dataProvider?.getPatientById(patientId);
    _request = _request.copyWith(
      adherencePercent: ((patient?.complianceRate ?? 0) * 100).round(),
    );
    _appendAudit(
      'MEDICATION_${status.name.toUpperCase()}',
      'Demo patient',
      'Patient',
      reason: 'Medication status recorded from the patient portal.',
    );
  }

  TransitionResult cancelTreatment({required String reason}) {
    if (!can(AppPermission.createTreatmentRequest)) {
      return _denied(AppPermission.createTreatmentRequest);
    }
    if (reason.trim().isEmpty) {
      return const TransitionResult(
        false,
        'A cancellation reason is required.',
      );
    }
    if (_request.status == RequestStatus.completed ||
        _request.status == RequestStatus.cancelled) {
      return const TransitionResult(false, 'Treatment cannot be cancelled.');
    }
    final previous = _request.status;
    _request = _request.copyWith(status: RequestStatus.cancelled);
    _appendTerminalAudit('TREATMENT_CANCELLED', previous, reason);
    return const TransitionResult(true, 'Treatment cancelled.');
  }

  TransitionResult expireTreatment({
    String reason = 'Approval validity ended',
  }) {
    if (!can(AppPermission.createTreatmentRequest)) {
      return _denied(AppPermission.createTreatmentRequest);
    }
    if (_request.status == RequestStatus.completed ||
        _request.status == RequestStatus.cancelled) {
      return const TransitionResult(false, 'Treatment cannot be expired.');
    }
    final previous = _request.status;
    _request = _request.copyWith(status: RequestStatus.expired);
    _appendTerminalAudit('TREATMENT_EXPIRED', previous, reason);
    return const TransitionResult(true, 'Treatment expired.');
  }

  void _appendTerminalAudit(
    String action,
    RequestStatus previous,
    String reason,
  ) {
    final event = JourneyAuditEvent(
      action: action,
      actor: 'Current user',
      role: _access?.role.name ?? 'systemAdmin',
      previousState: previous,
      newState: _request.status,
      timestamp: DemoClock.now,
      reason: reason,
    );
    _request = _request.copyWith(audit: [..._request.audit, event]);
    _saveCurrent();
    _dataProvider?.recordJourneyAudit(
      patientId: _request.patientId,
      action: action,
      role: event.role,
      status: _request.status.name,
    );
    notifyListeners();
  }

  TransitionResult completeMissingLaboratoryInformation({
    required double crp,
    required double esr,
    required DateTime collectedAt,
    required String source,
    required String physicianReportReference,
  }) {
    if (!can(AppPermission.editLabResults)) {
      return _denied(AppPermission.editLabResults);
    }
    if (crp < 0 ||
        esr < 0 ||
        source.trim().isEmpty ||
        physicianReportReference.trim().isEmpty) {
      return const TransitionResult(
        false,
        'Enter valid CRP, ESR, laboratory source, and physician report reference.',
      );
    }
    _request = _request.copyWith(
      crp: crp,
      esr: esr,
      status: RequestStatus.submitted,
      physicianReportAttached: true,
    );
    _saveCurrent();
    _dataProvider?.addOrUpdateJourneyLabs(
      patientId: _request.patientId,
      crp: crp,
      esr: esr,
      collectedAt: collectedAt,
      source: source,
    );
    _dataProvider?.addJourneyDocument(
      patientId: _request.patientId,
      fileName: physicianReportReference.trim(),
      category: 'physician_report',
    );
    _appendAudit(
      'LAB_RESULTS_COMPLETED',
      'Current user',
      _access?.role.name ?? 'systemAdmin',
      reason: 'CRP and ESR added from $source.',
    );
    return evaluate();
  }

  TransitionResult _move(
    RequestStatus next,
    String action,
    String actor,
    String role, {
    String reason = '',
  }) {
    final current = _request.status;
    if (!(_allowed[current]?.contains(next) ?? false)) {
      return TransitionResult(
        false,
        'Invalid transition: ${current.name} → ${next.name}.',
      );
    }
    final event = JourneyAuditEvent(
      action: action,
      actor: actor,
      role: role,
      previousState: current,
      newState: next,
      timestamp: DemoClock.now,
      reason: reason,
      aiRecommendation: _request.aiRecommendation,
      humanDecision: _request.humanDecision,
    );
    _request = _request.copyWith(
      status: next,
      audit: [..._request.audit, event],
    );
    _saveCurrent();
    _dataProvider?.recordJourneyAudit(
      patientId: _request.patientId,
      action: action,
      role: role,
      status: next.name,
    );
    notifyListeners();
    return const TransitionResult(true, 'Workflow updated.');
  }

  void _saveCurrent() {
    if (_dataProvider != null) {
      _dataProvider!.saveTreatmentRequest(_request);
      return;
    }
    final history = List<DemoTreatmentRequest>.from(
      _localRequestsByPatient[_request.patientId] ?? const [],
    );
    final index = history.indexWhere((item) => item.id == _request.id);
    if (index >= 0) {
      history[index] = _request;
    } else {
      history.add(_request);
    }
    _localRequestsByPatient[_request.patientId] = history;
  }

  void _appendAudit(
    String action,
    String actor,
    String role, {
    String reason = '',
  }) {
    _request = _request.copyWith(
      audit: [
        ..._request.audit,
        JourneyAuditEvent(
          action: action,
          actor: actor,
          role: role,
          previousState: _request.status,
          newState: _request.status,
          timestamp: DemoClock.now,
          reason: reason,
          aiRecommendation: _request.aiRecommendation,
          humanDecision: _request.humanDecision,
        ),
      ],
    );
    _saveCurrent();
    _dataProvider?.recordJourneyAudit(
      patientId: _request.patientId,
      action: action,
      role: role,
      status: _request.status.name,
    );
    notifyListeners();
  }

  static List<EligibilityCriterion> _evaluate(DemoTreatmentRequest r) => [
    _criterion(
      'age',
      'Patient criteria',
      'معايير المريض',
      '${r.age} years',
      '${r.age} سنة',
      r.age >= 18 ? CriterionResult.pass : CriterionResult.fail,
      'Adult patient requirement.',
      'شرط بلوغ المريض سن الرشد.',
    ),
    _criterion(
      'diagnosis',
      'Diagnosis criteria',
      'معايير التشخيص',
      r.diagnosisEn,
      r.diagnosisAr,
      r.diagnosisEn.isEmpty ? CriterionResult.missing : CriterionResult.pass,
      'Documented diagnosis matches the requested pathway.',
      'التشخيص الموثق متوافق مع مسار الطلب.',
    ),
    _criterion(
      'crp',
      'CRP laboratory result',
      'نتيجة تحليل CRP',
      r.crp == null ? 'Missing' : '${r.crp} mg/L',
      r.crp == null ? 'غير متوفر' : '${r.crp} ملغم/لتر',
      r.crp == null ? CriterionResult.missing : CriterionResult.pass,
      'Recent inflammatory marker is required.',
      'مؤشر الالتهاب الحديث مطلوب.',
    ),
    _criterion(
      'esr',
      'ESR laboratory result',
      'نتيجة تحليل ESR',
      r.esr == null ? 'Missing' : '${r.esr} mm/hr',
      r.esr == null ? 'غير متوفر' : '${r.esr} ملم/ساعة',
      r.esr == null ? CriterionResult.missing : CriterionResult.pass,
      'Recent ESR supports assessment.',
      'تحليل ESR الحديث يدعم التقييم.',
    ),
    _criterion(
      'previous',
      'Previous treatment',
      'العلاج السابق',
      r.previousTreatmentEn,
      r.previousTreatmentAr,
      r.previousTreatmentEn.isEmpty
          ? CriterionResult.missing
          : CriterionResult.pass,
      'Prior therapy is documented.',
      'العلاج السابق موثق.',
    ),
    _criterion(
      'duplicate',
      'Duplicate medication check',
      'فحص تكرار الدواء',
      r.recentDuplicate
          ? 'Recent matching dispense found'
          : 'No recent duplicate found',
      r.recentDuplicate
          ? 'تم العثور على صرف حديث مماثل'
          : 'لا يوجد صرف مكرر حديث',
      r.recentDuplicate ? CriterionResult.warning : CriterionResult.pass,
      'Dispensing history was checked locally.',
      'تم فحص سجل الصرف محليًا.',
    ),
    _criterion(
      'document',
      'Required documentation',
      'المستندات المطلوبة',
      r.physicianReportAttached
          ? 'Physician report attached'
          : 'Physician report missing',
      r.physicianReportAttached ? 'تقرير الطبيب مرفق' : 'تقرير الطبيب غير مرفق',
      r.physicianReportAttached
          ? CriterionResult.pass
          : CriterionResult.missing,
      'A supporting physician report is mandatory.',
      'تقرير الطبيب الداعم إلزامي.',
    ),
    _criterion(
      'policy',
      'Policy / protocol criteria',
      'معايير السياسة والبروتوكول',
      'Demo policy v1.0 evaluated',
      'تم تقييم سياسة العرض v1.0',
      CriterionResult.pass,
      'Local deterministic demo policy.',
      'سياسة عرض محلية وحتمية.',
    ),
  ];

  static EligibilityCriterion _criterion(
    String id,
    String en,
    String ar,
    String evidenceEn,
    String evidenceAr,
    CriterionResult result,
    String explanationEn,
    String explanationAr,
  ) => EligibilityCriterion(
    id: id,
    labelEn: en,
    labelAr: ar,
    evidenceEn: evidenceEn,
    evidenceAr: evidenceAr,
    explanationEn: explanationEn,
    explanationAr: explanationAr,
    result: result,
  );

  static DemoTreatmentRequest _seed(DemoScenario scenario) {
    final configuration = switch (scenario) {
      DemoScenario.successfulApproval => (
        name: 'Aisha Al Nuaimi',
        nameAr: 'عائشة النعيمي',
        esr: 42.0,
        report: true,
        duplicate: false,
        urgent: false,
        status: RequestStatus.draft,
        ai: AiRecommendation.approve,
        human: null as ReviewDecision?,
      ),
      DemoScenario.missingLaboratory => (
        name: 'Omar Al Mazrouei',
        nameAr: 'عمر المزروعي',
        esr: null,
        report: true,
        duplicate: false,
        urgent: false,
        status: RequestStatus.submitted,
        ai: AiRecommendation.moreInformation,
        human: null,
      ),
      DemoScenario.duplicateMedication => (
        name: 'Mariam Al Ketbi',
        nameAr: 'مريم الكتبي',
        esr: 54.0,
        report: true,
        duplicate: true,
        urgent: false,
        status: RequestStatus.underReview,
        ai: AiRecommendation.review,
        human: null,
      ),
      DemoScenario.aiWarning => (
        name: 'Saeed Al Mansoori',
        nameAr: 'سعيد المنصوري',
        esr: 61.0,
        report: true,
        duplicate: true,
        urgent: false,
        status: RequestStatus.underReview,
        ai: AiRecommendation.review,
        human: null,
      ),
      DemoScenario.humanOverride => (
        name: 'Noora Al Shamsi',
        nameAr: 'نورة الشامسي',
        esr: 48.0,
        report: true,
        duplicate: false,
        urgent: false,
        status: RequestStatus.underReview,
        ai: AiRecommendation.approve,
        human: null,
      ),
      DemoScenario.rejectedRequest => (
        name: 'Hamad Al Falasi',
        nameAr: 'حمد الفلاسي',
        esr: 70.0,
        report: true,
        duplicate: true,
        urgent: false,
        status: RequestStatus.rejected,
        ai: AiRecommendation.review,
        human: ReviewDecision.reject,
      ),
      DemoScenario.urgentCase => (
        name: 'Fatima Al Suwaidi',
        nameAr: 'فاطمة السويدي',
        esr: 88.0,
        report: true,
        duplicate: false,
        urgent: true,
        status: RequestStatus.underReview,
        ai: AiRecommendation.approve,
        human: null,
      ),
    };
    final base = DemoTreatmentRequest(
      id: 'TR-${scenario.index + 1001}',
      patientId: 'JP-${scenario.index + 1}',
      patientNameEn: configuration.name,
      patientNameAr: configuration.nameAr,
      mrn: 'MRN-2026-${1200 + scenario.index}',
      age: 38 + scenario.index,
      genderEn: scenario.index.isEven ? 'Female' : 'Male',
      genderAr: scenario.index.isEven ? 'أنثى' : 'ذكر',
      hospitalEn: 'Sheikh Khalifa Medical City',
      hospitalAr: 'مدينة الشيخ خليفة الطبية',
      diagnosisEn: 'Rheumatoid Arthritis',
      diagnosisAr: 'التهاب المفاصل الروماتويدي',
      medication: 'Adalimumab (Humira)',
      dose: '40 mg every 2 weeks',
      indicationEn: 'Active disease despite conventional therapy',
      indicationAr: 'مرض نشط رغم العلاج التقليدي',
      previousTreatmentEn: 'Methotrexate for 6 months',
      previousTreatmentAr: 'ميثوتركسات لمدة 6 أشهر',
      currentMedicationEn: 'Methotrexate 15 mg weekly',
      currentMedicationAr: 'ميثوتركسات 15 ملغم أسبوعيًا',
      crp: 65,
      esr: configuration.esr,
      physicianReportAttached: configuration.report,
      recentDuplicate: configuration.duplicate,
      urgent: configuration.urgent,
      createdAt: DemoClock.daysAgo(3),
      status: configuration.status,
      criteria: const [],
      aiRecommendation: configuration.ai,
      humanDecision: configuration.human,
    );
    final criteria = _evaluate(base);
    return base.copyWith(
      criteria: criteria,
      audit: [
        JourneyAuditEvent(
          action: 'REQUEST_CREATED',
          actor: 'Dr. Maya Hassan',
          role: 'Doctor',
          previousState: null,
          newState: RequestStatus.draft,
          timestamp: DemoClock.daysAgo(3),
        ),
      ],
    );
  }
}
