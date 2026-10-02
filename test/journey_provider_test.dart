import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mounjaro_demo/features/journey/journey_models.dart';
import 'package:mounjaro_demo/features/journey/journey_provider.dart';
import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/features/treatment_plan/models/treatment_plan.dart';

void preparePlan(DataProvider data, String patientId) {
  data.createTreatmentPlan(
    TreatmentPlan(
      id: 'TP-TEST-$patientId',
      patientId: patientId,
      doctorName: 'Dr. Test',
      createdAt: DateTime.now(),
      medicationDose: '10 mg',
      medicationFrequencyDays: 28,
      reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
      assignedCenterId: 'C001',
      sessions: const [],
      homeExercises: const [],
      targetWeight: 95,
    ),
  );
}

void main() {
  group('connected medication journey', () {
    test('valid journey reaches monitoring', () {
      final provider = JourneyProvider();
      expect(provider.submit().success, isTrue);
      expect(provider.evaluate().success, isTrue);
      expect(provider.request.status, RequestStatus.underReview);
      expect(
        provider
            .review(ReviewDecision.approve, reason: 'Evidence verified')
            .success,
        isTrue,
      );
      expect(provider.markReadyForDispensing().success, isTrue);
      expect(provider.dispense().success, isTrue);
      expect(provider.startMonitoring().success, isTrue);
      expect(provider.request.status, RequestStatus.monitoring);
      expect(
        provider.request.audit.any((e) => e.action == 'DISPENSED'),
        isTrue,
      );
    });

    test('missing laboratory cannot reach approval', () {
      final provider = JourneyProvider()
        ..loadScenario(DemoScenario.missingLaboratory);
      expect(provider.evaluate().success, isTrue);
      expect(provider.request.status, RequestStatus.needsInformation);
      expect(
        provider.review(ReviewDecision.approve, reason: 'approve').success,
        isFalse,
      );
    });

    test('rejected request cannot be dispensed', () {
      final provider = JourneyProvider()
        ..loadScenario(DemoScenario.rejectedRequest);
      expect(provider.markReadyForDispensing().success, isFalse);
      expect(provider.dispense().success, isFalse);
      expect(provider.request.status, RequestStatus.rejected);
    });

    test('human override requires reason and is audited', () {
      final provider = JourneyProvider()
        ..loadScenario(DemoScenario.humanOverride);
      expect(
        provider.review(ReviewDecision.reject, reason: '').success,
        isFalse,
      );
      expect(
        provider
            .review(
              ReviewDecision.reject,
              reason: 'Additional evidence required',
            )
            .success,
        isTrue,
      );
      expect(provider.request.overrideReason, isNotEmpty);
      expect(
        provider.request.audit.any((e) => e.action == 'AI_OVERRIDE'),
        isTrue,
      );
    });

    test('duplicate medication requires pharmacy override', () {
      final provider = JourneyProvider()
        ..loadScenario(DemoScenario.duplicateMedication);
      expect(
        provider
            .review(
              ReviewDecision.approve,
              reason: 'Reviewer accepted exception',
            )
            .success,
        isTrue,
      );
      expect(provider.markReadyForDispensing().success, isTrue);
      expect(provider.dispense().success, isFalse);
      expect(
        provider.dispense(overrideReason: 'Verified replacement dose').success,
        isTrue,
      );
    });
  });

  test('legacy dispensing cannot override clinical ineligibility', () {
    final provider = DataProvider();
    final patient = provider.patients.firstWhere(
      (candidate) => !candidate.programEligibility.eligible,
    );
    final result = provider.dispenseMedication(
      patientId: patient.id,
      centerId: provider.centers.first.id,
      dose: patient.currentDose,
      authorized: true,
      isOverride: true,
    );
    expect(result, isFalse);
  });

  test('journey state is restored per patient', () {
    final data = DataProvider();
    final provider = JourneyProvider(dataProvider: data);
    final patientA = data.getPatientById('P999')!;
    final patientB = data.patients.firstWhere(
      (candidate) => candidate.id != patientA.id &&
          candidate.programEligibility.eligible,
    );
    preparePlan(data, patientA.id);
    preparePlan(data, patientB.id);
    provider.bindExistingPatient(patientA);
    expect(provider.submit().success, isTrue);
    expect(provider.request.status, RequestStatus.submitted);
    provider.bindExistingPatient(patientB);
    expect(provider.request.patientId, patientB.id);
    expect(provider.request.status, RequestStatus.draft);
    provider.bindExistingPatient(patientA);
    expect(provider.request.patientId, patientA.id);
    expect(provider.request.status, RequestStatus.submitted);
  });

  test('missing CRP and ESR can be completed and eligibility recalculates', () {
    final data = DataProvider();
    final provider = JourneyProvider(dataProvider: data);
    final patient = data.getPatientById('P999')!;
    preparePlan(data, patient.id);
    provider.bindExistingPatient(patient);
    expect(provider.submit().success, isTrue);
    expect(provider.evaluate().success, isTrue);
    expect(provider.request.status, RequestStatus.needsInformation);
    final result = provider.completeMissingLaboratoryInformation(
      crp: 3.2,
      esr: 12,
      collectedAt: DateTime(2026, 9, 27),
      source: 'Central laboratory',
      physicianReportReference: 'physician-report.pdf',
    );
    expect(result.success, isTrue);
    expect(provider.request.status, RequestStatus.underReview);
    final updated = data.getPatientById(patient.id)!;
    expect(updated.labResults.any((lab) => lab.testCode == 'CRP'), isTrue);
    expect(updated.labResults.any((lab) => lab.testCode == 'ESR'), isTrue);
    expect(updated.clinicalAttachments, isNotEmpty);
  });

  test('doctor cannot approve treatment and denial is audited', () {
    final access = AccessControlProvider(initialRole: AppRole.doctor);
    final provider = JourneyProvider(access: access);
    expect(provider.submit().success, isTrue);
    expect(provider.evaluate().success, isTrue);
    expect(provider.request.status, RequestStatus.underReview);
    final result = provider.review(
      ReviewDecision.approve,
      reason: 'Not authorized',
    );
    expect(result.success, isFalse);
    expect(provider.request.status, RequestStatus.underReview);
    expect(
      provider.request.audit.any((event) => event.action == 'ACCESS_DENIED'),
      isTrue,
    );
  });

  test('pharmacist cannot create or submit treatment request', () {
    final access = AccessControlProvider(initialRole: AppRole.pharmacist);
    final provider = JourneyProvider(access: access);
    expect(provider.submit().success, isFalse);
    expect(provider.request.status, RequestStatus.draft);
  });

  test('authorized journey dispensing updates the patient record', () {
    final data = DataProvider();
    final access = AccessControlProvider(initialRole: AppRole.systemAdmin);
    final provider = JourneyProvider(dataProvider: data, access: access);
    final patient = data.getPatientById('P999')!;
    preparePlan(data, patient.id);
    final before = patient.dispenseRecords.length;
    provider.bindExistingPatient(patient);
    expect(provider.submit().success, isTrue);
    expect(provider.evaluate().success, isTrue);
    expect(
      provider
          .completeMissingLaboratoryInformation(
            crp: 2.4,
            esr: 10,
            collectedAt: DateTime(2026, 9, 27),
            source: 'Central laboratory',
            physicianReportReference: 'review.pdf',
          )
          .success,
      isTrue,
    );
    expect(
      provider
          .review(ReviewDecision.approve, reason: 'Evidence verified')
          .success,
      isTrue,
    );
    expect(provider.markReadyForDispensing().success, isTrue);
    expect(
      provider.dispense(overrideReason: 'Authorized demo dispense').success,
      isTrue,
    );
    final updated = data.getPatientById(patient.id)!;
    expect(updated.dispenseRecords.length, before + 1);
    expect(updated.lastDispensingDate, isNotNull);
    expect(updated.nextEligibleDate, isNotNull);
    expect(provider.request.status, RequestStatus.dispensed);
    expect(data.logs.first.patientId, patient.id);
  });

  test('laboratory results are patient specific', () {
    final data = DataProvider();
    final a = data.patients[0];
    final b = data.patients[1];
    expect(a.labResults.first.patientId, a.id);
    expect(b.labResults.first.patientId, b.id);
    expect(a.labResults.first.id, isNot(b.labResults.first.id));
  });
}
