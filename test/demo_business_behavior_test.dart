import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/demo/demo_session_provider.dart';
import 'package:mounjaro_demo/core/models/activity_log.dart';
import 'package:mounjaro_demo/core/utils/dose_utils.dart';
import 'package:mounjaro_demo/features/dashboard/web/web_admin_shell.dart';
import 'package:mounjaro_demo/features/journey/journey_models.dart';
import 'package:mounjaro_demo/features/journey/journey_provider.dart';

void main() {
  test('registry KPIs derive from live patient state', () {
    final data = DataProvider();
    final before = data.totalPatientCount;
    final source = data.patients.first;
    data.registerPatient(
      Patient(
        id: 'P-TEST-KPI',
        emiratesId: '784-2000-0000000-1',
        fullName: 'Demo KPI Patient',
        fullNameAr: 'مريض مؤشرات تجريبي',
        nationality: source.nationality,
        nationalityAr: source.nationalityAr,
        residencyStatus: source.residencyStatus,
        age: 30,
        gender: source.gender,
        genderAr: source.genderAr,
        weight: 90,
        height: 170,
        medicalConditions: const ['Type 2 Diabetes'],
        medicalConditionsAr: const ['السكري من النوع الثاني'],
        latitude: 25.2,
        longitude: 55.2,
        emirate: 'Dubai',
        emirateAr: 'دبي',
        weightHistory: const [90],
        doseHistory: const [],
        complianceRate: 0,
        hasChronicDisease: true,
        hba1cPercent: 7.2,
        fastingGlucoseMgDl: 130,
      ),
    );
    expect(data.totalPatientCount, before + 1);
    expect(
      data.eligiblePatientCount,
      data.patients.where((p) => p.programEligibility.eligible).length,
    );
  });

  test('medication events update adherence and audit trail', () {
    final data = DataProvider();
    final plan = data.treatmentPlans.firstWhere((p) => p.patientId == 'P999');
    data.logMedication(
      plan.id,
      DateTime(2026, 9, 28, 9),
      status: MedicationDoseStatus.taken,
    );
    data.logMedication(
      plan.id,
      DateTime(2026, 10, 5, 9),
      status: MedicationDoseStatus.missed,
    );
    expect(data.medicationEventsFor('P999'), hasLength(2));
    expect(data.getPatientById('P999')!.complianceRate, .5);
    expect(
      data.logs.any(
        (log) =>
            log.patientId == 'P999' &&
            log.eventType == ActivityEventType.medicationAdherence,
      ),
      isTrue,
    );
  });

  test('each patient keeps multiple treatment requests and history', () {
    final data = DataProvider();
    final access = AccessControlProvider(initialRole: AppRole.doctor);
    final journey = JourneyProvider(dataProvider: data, access: access);
    final patient = data.getPatientById('P999')!;
    journey.bindExistingPatient(patient);
    expect(journey.historyForPatient(patient.id), isNotEmpty);
    final before = journey.historyForPatient(patient.id).length;
    expect(journey.createRequestForPatient(patient).success, isFalse);
    expect(
      journey.cancelTreatment(reason: 'Treatment plan replaced').success,
      isTrue,
    );
    expect(journey.createRequestForPatient(patient).success, isTrue);
    expect(journey.historyForPatient(patient.id), hasLength(before + 1));
    expect(
      journey
          .historyForPatient(patient.id)
          .any((r) => r.status == RequestStatus.cancelled),
      isTrue,
    );
    expect(
      data.pharmacyRequestForPatient(patient.id)?.treatmentRequestId,
      journey.request.id,
    );
  });

  test('rejected and expired requests are terminal demo states', () {
    final journey = JourneyProvider()
      ..loadScenario(DemoScenario.rejectedRequest);
    expect(journey.request.status, RequestStatus.rejected);
    expect(journey.dispense().success, isFalse);

    final active = JourneyProvider();
    expect(active.expireTreatment().success, isTrue);
    expect(active.request.status, RequestStatus.expired);
    expect(
      active.request.audit.any((e) => e.action == 'TREATMENT_EXPIRED'),
      isTrue,
    );
  });

  test('monitoring can move to renewal due and completion', () {
    final journey = JourneyProvider();
    expect(journey.submit().success, isTrue);
    expect(journey.evaluate().success, isTrue);
    expect(
      journey.review(ReviewDecision.approve, reason: 'Approved').success,
      isTrue,
    );
    expect(journey.markReadyForDispensing().success, isTrue);
    expect(journey.dispense().success, isTrue);
    expect(journey.startMonitoring().success, isTrue);
    expect(journey.markRenewalDue().success, isTrue);
    expect(journey.request.status, RequestStatus.renewalDue);
    expect(journey.completeTreatment().success, isTrue);
    expect(journey.request.status, RequestStatus.completed);
  });

  test('mock patient context follows the selected patient', () {
    final session = DemoSessionProvider();
    expect(session.patientId, 'P999');
    session.selectPatient('P002');
    expect(session.patientId, 'P002');
  });

  test('medical reviewer role can decide but cannot dispense', () {
    final access = AccessControlProvider(initialRole: AppRole.medicalReviewer);
    expect(access.can(AppPermission.approveTreatment), isTrue);
    expect(access.can(AppPermission.rejectTreatment), isTrue);
    expect(access.can(AppPermission.dispenseMedication), isFalse);
  });

  testWidgets('admin portal preview scopes clinical authority to doctor', (
    tester,
  ) async {
    final data = DataProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: data,
        child: MaterialApp(
          home: OperationalPortalPreview(
            role: AppRole.doctor,
            child: Builder(
              builder: (context) {
                final access = context.watch<AccessControlProvider>();
                final journey = context.watch<JourneyProvider>();
                return Text(
                  '${access.role.name}:${journey.can(AppPermission.approveTreatment)}',
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('doctor:false'), findsOneWidget);
  });

  test('dispensing synchronizes inventory patient and audit state', () {
    final data = DataProvider();
    final patient = data.patients.firstWhere(
      (p) => data
          .validateDispensing(
            patientId: p.id,
            centerId: 'C001',
            hasPermission: true,
          )
          .canDispense,
    );
    final center = data.centers.first;
    final inventoryBefore = center.totalAvailable;
    final recordsBefore = patient.dispenseRecords.length;
    final result = data.dispenseMedication(
      patientId: patient.id,
      centerId: center.id,
      dose: data.getPlanForPatient(patient.id)!.medicationDose,
      authorized: true,
      requestId: data.pharmacyRequestForPatient(patient.id)!.id,
      pharmacistNotes: 'Identity and prescription verified.',
    );
    expect(result, isTrue);
    expect(data.centers.first.totalAvailable, inventoryBefore - 1);
    expect(
      data.getPatientById(patient.id)!.dispenseRecords,
      hasLength(recordsBefore + 1),
    );
    expect(data.logs.first.patientId, patient.id);
    expect(data.logs.first.actorRole, 'pharmacist');
    expect(data.logs.first.notes, 'Identity and prescription verified.');
    expect(data.pharmacyRequestForPatient(patient.id), isNull);
  });

  test('insufficient inventory blocks dispensing without changing patient', () {
    final data = DataProvider();
    final patient = data.patients.firstWhere(
      (p) => data
          .validateDispensing(
            patientId: p.id,
            centerId: 'C001',
            hasPermission: true,
          )
          .canDispense,
    );
    final center = data.centers.first;
    center.batches.clear();
    final before = patient.dispenseRecords.length;
    expect(
      data.dispenseMedication(
        patientId: patient.id,
        centerId: center.id,
        dose: data.getPlanForPatient(patient.id)!.medicationDose,
        authorized: true,
        requestId: data.pharmacyRequestForPatient(patient.id)!.id,
      ),
      isFalse,
    );
    expect(data.getPatientById(patient.id)!.dispenseRecords, hasLength(before));
  });

  test('dispense authorization is enforced at the data boundary', () {
    final data = DataProvider();
    final patient = data.patients.firstWhere(
      (p) => data
          .validateDispensing(
            patientId: p.id,
            centerId: 'C001',
            hasPermission: true,
          )
          .canDispense,
    );
    final plan = data.getPlanForPatient(patient.id)!;
    final request = data.pharmacyRequestForPatient(patient.id)!;
    final recordsBefore = patient.dispenseRecords.length;
    expect(
      data
          .validateDispensing(patientId: patient.id, centerId: 'C001')
          .canDispense,
      isFalse,
    );
    expect(
      data.dispenseMedication(
        patientId: patient.id,
        centerId: 'C001',
        dose: plan.medicationDose,
        authorized: false,
        requestId: request.id,
      ),
      isFalse,
    );
    expect(
      data.getPatientById(patient.id)!.dispenseRecords,
      hasLength(recordsBefore),
    );
  });

  test('expired batches do not count as available medication stock', () {
    final data = DataProvider();
    final patient = data.patients.firstWhere(
      (p) => data
          .validateDispensing(
            patientId: p.id,
            centerId: 'C001',
            hasPermission: true,
          )
          .canDispense,
    );
    final plan = data.getPlanForPatient(patient.id)!;
    final center = data.centers.first;
    center.batches.removeWhere(
      (batch) => DoseUtils.dosesMatch(batch.dose, plan.medicationDose),
    );
    center.batches.add(
      MedicationBatch(
        id: 'EXPIRED-LOT',
        dose: plan.medicationDose,
        quantity: plan.medicationQuantity,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    expect(
      data
          .validateDispensing(
            patientId: patient.id,
            centerId: center.id,
            hasPermission: true,
          )
          .canDispense,
      isFalse,
    );
  });

  test(
    'pharmacy queue contains plan-linked requests and no patient-only entries',
    () {
      final data = DataProvider();
      expect(data.pharmacyRequests, isNotEmpty);
      for (final request in data.pharmacyRequests) {
        final patient = data.getPatientById(request.patientId);
        final plan = data.getPlanForPatient(request.patientId);
        expect(patient, isNotNull);
        expect(plan, isNotNull);
        expect(request.treatmentPlanId, plan!.id);
        expect(request.medication, isNotEmpty);
        expect(request.dose, isNotEmpty);
        expect(request.quantity, greaterThan(0));
        expect(request.assignedCenterId, isNotEmpty);
      }
    },
  );

  test('restock requires permission and a future-expiring valid batch', () {
    final data = DataProvider();
    final center = data.centers.first;
    final initial = data.availableStockForDose(center, '5 mg');
    data.replenishInventory(
      center.id,
      '5 mg',
      5,
      authorized: false,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
    expect(data.availableStockForDose(center, '5 mg'), initial);
    data.replenishInventory(
      center.id,
      '5 mg',
      5,
      authorized: true,
      expiryDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(data.availableStockForDose(center, '5 mg'), initial);
    final expiry = DateTime.now().add(const Duration(days: 90));
    data.replenishInventory(
      center.id,
      '5 mg',
      5,
      authorized: true,
      expiryDate: expiry,
    );
    expect(data.availableStockForDose(data.centers.first, '5 mg'), initial + 5);
    expect(
      data.centers.first.batches.any((batch) => batch.expiryDate == expiry),
      isTrue,
    );
  });

  test('appointments support rescheduled cancelled and missed states', () {
    final data = DataProvider();
    const patientId = 'P999';
    final first = data.createAppointment(
      patientId: patientId,
      dateTime: DateTime(2026, 10, 1),
      doctor: 'Demo doctor',
      purpose: 'Follow-up',
    );
    data.rescheduleAppointment(patientId, first.id, DateTime(2026, 10, 8));
    expect(data.appointmentsFor(patientId).last.dateTime.day, 8);
    data.markAppointmentMissed(patientId, first.id);
    expect(
      data.appointmentsFor(patientId).last.status,
      AppointmentStatus.missed,
    );
    final second = data.createAppointment(
      patientId: patientId,
      dateTime: DateTime(2026, 10, 15),
      doctor: 'Demo doctor',
      purpose: 'Renewal',
    );
    data.cancelAppointment(patientId, second.id);
    expect(
      data.appointmentsFor(patientId).last.status,
      AppointmentStatus.cancelled,
    );
  });

  test('Patient360 source reflects adherence and journey synchronization', () {
    final data = DataProvider();
    final access = AccessControlProvider(initialRole: AppRole.systemAdmin);
    final journey = JourneyProvider(dataProvider: data, access: access);
    final patient = data.getPatientById('P999')!;
    journey.bindExistingPatient(patient);
    final plan = data.getPlanForPatient(patient.id)!;
    data.logMedication(plan.id, DateTime.now());
    journey.recordMedicationAdherence(patient.id, MedicationDoseStatus.taken);
    expect(data.getPatientById(patient.id)!.complianceRate, 1);
    expect(journey.request.adherencePercent, 100);
    expect(
      journey.request.audit.any((e) => e.action == 'MEDICATION_TAKEN'),
      isTrue,
    );
  });
}
