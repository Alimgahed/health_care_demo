import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/features/journey/journey_models.dart';
import 'package:mounjaro_demo/features/journey/journey_provider.dart';
import 'package:mounjaro_demo/features/treatment_plan/models/treatment_plan.dart';

void main() {
  late AccessControlProvider access;
  late DataProvider data;
  late JourneyProvider journey;

  void createFreshPlan(String patientId) {
    data.createTreatmentPlan(
      TreatmentPlan(
        id: 'TP-NEW-$patientId',
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

  setUp(() {
    access = AccessControlProvider(initialRole: AppRole.doctor);
    data = DataProvider(access: access);
    journey = JourneyProvider(dataProvider: data, access: access);
  });

  test(
    'same request progresses through review, pharmacy, patient, and reports',
    () {
      final patient = data.getPatientById('P999')!;
      expect(patient.programEligibility.eligible, isTrue);
      createFreshPlan(patient.id);
      journey.bindExistingPatient(patient);
      final requestId = journey.request.id;
      final planId = data.getPlanForPatient(patient.id)!.id;
      expect(journey.request.treatmentPlanId, planId);
      expect(journey.submit().success, isTrue);
      expect(journey.evaluate().success, isTrue);
      expect(journey.request.status, RequestStatus.needsInformation);
      expect(
        journey
            .completeMissingLaboratoryInformation(
              crp: 3.2,
              esr: 12,
              collectedAt: DateTime.now(),
              source: 'Central laboratory',
              physicianReportReference: 'review.pdf',
            )
            .success,
        isTrue,
      );
      expect(journey.request.status, RequestStatus.underReview);
      expect(
        data.pendingClinicalReviews.any(
          (item) => item.patient.id == patient.id,
        ),
        isTrue,
      );
      expect(
        data.pharmacyRequestForPatient(patient.id)?.status,
        PharmacyRequestStatus.pendingReview,
      );

      access.setRole(AppRole.medicalReviewer);
      expect(
        journey
            .review(
              ReviewDecision.approve,
              reason: 'Clinical evidence reviewed',
            )
            .success,
        isTrue,
      );
      expect(
        data.getPlanForPatient(patient.id)?.clinicalApprovalStatus,
        'approved',
      );
      expect(
        data.treatmentRequestById(requestId)?.status,
        RequestStatus.approved,
      );
      expect(journey.markReadyForDispensing().success, isTrue);
      final queue = data.pharmacyRequestForPatient(patient.id)!;
      expect(queue.treatmentRequestId, requestId);
      expect(queue.status, PharmacyRequestStatus.ready);
      final beforeStock = data.availableStockForDose(
        data.centers.first,
        queue.dose,
      );
      final beforeRecords = patient.dispenseRecords.length;

      access.setRole(AppRole.pharmacist);
      expect(
        data.dispenseMedication(
          patientId: patient.id,
          centerId: queue.assignedCenterId,
          dose: queue.dose,
          authorized: true,
          requestId: queue.id,
        ),
        isTrue,
      );
      expect(
        data.treatmentRequestById(requestId)?.status,
        RequestStatus.dispensed,
      );
      expect(
        data.pharmacyRequests.firstWhere((item) => item.id == queue.id).status,
        PharmacyRequestStatus.dispensed,
      );
      expect(
        data.getPatientById(patient.id)!.dispenseRecords.length,
        beforeRecords + 1,
      );
      expect(
        data.availableStockForDose(data.centers.first, queue.dose),
        beforeStock - queue.quantity,
      );
      expect(
        data.coverageForRequest(requestId).status,
        FinancialReviewStatus.settled,
      );
      expect(data.notificationsFor(patient.id), isNotEmpty);
      expect(data.logs.any((log) => log.patientId == patient.id), isTrue);
      expect(
        data.dispenseMedication(
          patientId: patient.id,
          centerId: queue.assignedCenterId,
          dose: queue.dose,
          authorized: true,
          requestId: queue.id,
        ),
        isFalse,
      );
    },
  );

  test('role enforcement blocks approval and dispensing', () {
    createFreshPlan('P999');
    journey.bindExistingPatient(data.getPatientById('P999')!);
    expect(journey.submit().success, isTrue);
    expect(journey.evaluate().success, isTrue);
    expect(
      data.approveTreatmentRequest(
        journey.request.id,
        actorRole: AppRole.doctor,
      ),
      isFalse,
    );
    final queue = data.pharmacyRequestForPatient('P999')!;
    expect(
      data.dispenseMedication(
        patientId: 'P999',
        centerId: queue.assignedCenterId,
        dose: queue.dose,
        authorized: true,
        requestId: queue.id,
      ),
      isFalse,
    );
  });
}
