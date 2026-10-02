import 'dart:convert';

import '../../../../core/constants/mock_data.dart';
import '../../journey/journey_models.dart';
import '../../clinical/patient_clinical_models.dart';
import '../../treatment_plan/models/treatment_plan.dart';

/// Filters shared by every section in the executive report.
class ReportFilters {
  final int periodDays;
  final String? emirate;
  final String? centerId;
  final ResidencyStatus? residency;
  final String? careStatus;
  final PharmacyRequestStatus? requestStatus;
  final RequestStatus? treatmentRequestStatus;
  final String? doctorId;

  const ReportFilters({
    this.periodDays = 180,
    this.emirate,
    this.centerId,
    this.residency,
    this.careStatus,
    this.requestStatus,
    this.treatmentRequestStatus,
    this.doctorId,
  });

  ReportFilters copyWith({
    int? periodDays,
    String? emirate,
    String? centerId,
    ResidencyStatus? residency,
    String? careStatus,
    PharmacyRequestStatus? requestStatus,
    RequestStatus? treatmentRequestStatus,
    String? doctorId,
    bool clearEmirate = false,
    bool clearCenter = false,
    bool clearResidency = false,
    bool clearCareStatus = false,
    bool clearRequestStatus = false,
    bool clearTreatmentRequestStatus = false,
    bool clearDoctor = false,
  }) => ReportFilters(
    periodDays: periodDays ?? this.periodDays,
    emirate: clearEmirate ? null : (emirate ?? this.emirate),
    centerId: clearCenter ? null : (centerId ?? this.centerId),
    residency: clearResidency ? null : (residency ?? this.residency),
    careStatus: clearCareStatus ? null : (careStatus ?? this.careStatus),
    requestStatus: clearRequestStatus
        ? null
        : (requestStatus ?? this.requestStatus),
    treatmentRequestStatus: clearTreatmentRequestStatus
        ? null
        : (treatmentRequestStatus ?? this.treatmentRequestStatus),
    doctorId: clearDoctor ? null : (doctorId ?? this.doctorId),
  );

  bool get hasFilters =>
      emirate != null ||
      centerId != null ||
      residency != null ||
      careStatus != null ||
      requestStatus != null ||
      treatmentRequestStatus != null ||
      doctorId != null;
}

class ReportDispense {
  final Patient patient;
  final PatientDispenseRecord record;
  final DateTime date;

  const ReportDispense(this.patient, this.record, this.date);
}

class ReportMonth {
  final DateTime month;
  final int handovers;

  const ReportMonth(this.month, this.handovers);
}

class ReportWeightObservation {
  final Patient patient;
  final DateTime date;
  final double weight;

  const ReportWeightObservation(this.patient, this.date, this.weight);
}

class ReportClinicalMonth {
  final DateTime month;
  final double averageWeight;
  final double averageBmi;
  final int observations;

  const ReportClinicalMonth({
    required this.month,
    required this.averageWeight,
    required this.averageBmi,
    required this.observations,
  });
}

class ReportFinancialSummary {
  final ResidencyStatus residency;
  final int patients;
  final int activePlans;
  final double estimatedProgramValueAed;
  final double estimatedCoverageAed;
  final double estimatedPatientShareAed;

  const ReportFinancialSummary({
    required this.residency,
    required this.patients,
    required this.activePlans,
    required this.estimatedProgramValueAed,
    required this.estimatedCoverageAed,
    required this.estimatedPatientShareAed,
  });
}

class ReportEmirateSummary {
  final String emirate;
  final int patients;
  final int eligiblePatients;
  final int activePlans;
  final int handovers;

  const ReportEmirateSummary({
    required this.emirate,
    required this.patients,
    required this.eligiblePatients,
    required this.activePlans,
    required this.handovers,
  });
}

class ReportFacilitySummary {
  final DispensingCenter center;
  final int patients;
  final int handovers;

  const ReportFacilitySummary({
    required this.center,
    required this.patients,
    required this.handovers,
  });
}

class ReportDoctorSummary {
  final Doctor doctor;
  final int patients;
  final int activePlans;
  final int approvedPlans;
  final int handovers;

  const ReportDoctorSummary({
    required this.doctor,
    required this.patients,
    required this.activePlans,
    required this.approvedPlans,
    required this.handovers,
  });
}

/// A calculated view over the app's shared DataProvider. It stores no report
/// records; every value is derived from the same patients, plans, requests,
/// dispensing history, appointments, laboratory results and inventory used by
/// the application portals.
class ReportAnalyticsData {
  final DataProvider source;
  final ReportFilters filters;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<Patient> patients;
  final List<DispensingCenter> centers;
  final List<TreatmentPlan> plans;
  final List<PharmacyDispensingRequest> requests;
  final List<PharmacyDispensingRequest> requestsInPeriod;
  final List<DemoTreatmentRequest> treatmentRequests;
  final List<DemoTreatmentRequest> treatmentRequestsInPeriod;
  final List<FinancialSupportRecord> financialRecordsInPeriod;
  final List<ReportDispense> handovers;
  final List<ReportWeightObservation> weightObservations;
  final List<PatientAppointment> appointments;
  final List<PatientLabResult> labResults;
  final List<MedicationDoseEvent> doseEvents;
  final Map<String, PharmacyDispensingRequest> latestRequestByPatient;
  final Map<String, DemoTreatmentRequest> latestTreatmentRequestByPatient;

  ReportAnalyticsData._({
    required this.source,
    required this.filters,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.patients,
    required this.centers,
    required this.plans,
    required this.requests,
    required this.requestsInPeriod,
    required this.treatmentRequests,
    required this.treatmentRequestsInPeriod,
    required this.financialRecordsInPeriod,
    required this.handovers,
    required this.weightObservations,
    required this.appointments,
    required this.labResults,
    required this.doseEvents,
    required this.latestRequestByPatient,
    required this.latestTreatmentRequestByPatient,
  });

  factory ReportAnalyticsData.derive(
    DataProvider source,
    ReportFilters filters, {
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final start = generatedAt.subtract(Duration(days: filters.periodDays));
    bool inPeriod(DateTime date) =>
        !date.isBefore(start) && !date.isAfter(generatedAt);

    final allPlans = source.treatmentPlans;
    final allRequests = source.pharmacyRequests;
    final allTreatmentRequests = source.treatmentRequestHistory.values
        .expand((history) => history)
        .toList();
    final allCenters = source.centers;
    bool matchesDoctor(Patient patient) {
      if (filters.doctorId == null) return true;
      final doctor = source.doctors.where((d) => d.id == filters.doctorId);
      if (doctor.isEmpty) return false;
      final doctorName = doctor.first.name
          .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
          .trim()
          .toLowerCase();
      return allPlans.any((plan) {
        if (plan.patientId != patient.id) return false;
        final planName = plan.doctorName
            .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
            .trim()
            .toLowerCase();
        return planName.startsWith(doctorName) ||
            doctorName.startsWith(planName);
      });
    }

    final visibleCenters = allCenters.where((center) {
      if (filters.emirate != null && center.region != filters.emirate) {
        return false;
      }
      return filters.centerId == null || center.id == filters.centerId;
    }).toList();
    final patients = source.patients.where((patient) {
      if (filters.emirate != null && patient.emirate != filters.emirate) {
        return false;
      }
      if (filters.residency != null &&
          patient.residencyStatus != filters.residency) {
        return false;
      }
      if (filters.careStatus == 'active' &&
          source.getPlanForPatient(patient.id) == null) {
        return false;
      }
      if (filters.careStatus == 'withoutPlan' &&
          source.getPlanForPatient(patient.id) != null) {
        return false;
      }
      if (filters.centerId != null) {
        final hasCenter =
            patient.lastDispensingCenterId == filters.centerId ||
            patient.dispenseRecords.any(
              (r) => r.centerId == filters.centerId,
            ) ||
            allPlans.any(
              (p) =>
                  p.patientId == patient.id &&
                  p.assignedCenterId == filters.centerId,
            ) ||
            allRequests.any(
              (r) =>
                  r.patientId == patient.id &&
                  r.assignedCenterId == filters.centerId,
            );
        if (!hasCenter) return false;
      }
      if (!matchesDoctor(patient)) return false;
      if (filters.requestStatus != null) {
        final patientRequests = allRequests.where(
          (request) => request.patientId == patient.id,
        );
        if (!patientRequests.any((r) => r.status == filters.requestStatus)) {
          return false;
        }
      }
      if (filters.treatmentRequestStatus != null &&
          source.activeTreatmentRequestFor(patient.id)?.status !=
              filters.treatmentRequestStatus) {
        return false;
      }
      return true;
    }).toList();

    final patientIds = patients.map((patient) => patient.id).toSet();
    final plans = allPlans
        .where((plan) => patientIds.contains(plan.patientId))
        .toList();
    final patientRequests = allRequests
        .where((request) => patientIds.contains(request.patientId))
        .where((request) {
          if (filters.centerId != null &&
              request.assignedCenterId != filters.centerId) {
            return false;
          }
          return true;
        })
        .toList();
    final requests = patientRequests
        .where(
          (request) =>
              filters.requestStatus == null ||
              request.status == filters.requestStatus,
        )
        .toList();
    final requestsInPeriod = requests
        .where((request) => inPeriod(request.requestedAt))
        .toList();
    final latestRequests = <String, PharmacyDispensingRequest>{};
    for (final request in patientRequests) {
      final current = latestRequests[request.patientId];
      if (current == null || request.requestedAt.isAfter(current.requestedAt)) {
        latestRequests[request.patientId] = request;
      }
    }
    final treatmentRequests = allTreatmentRequests
        .where((request) => patientIds.contains(request.patientId))
        .toList();
    final treatmentRequestsInPeriod = treatmentRequests
        .where((request) => inPeriod(request.createdAt))
        .toList();
    final latestTreatmentRequests = <String, DemoTreatmentRequest>{};
    for (final request in treatmentRequests) {
      final current = latestTreatmentRequests[request.patientId];
      if (current == null || request.createdAt.isAfter(current.createdAt)) {
        latestTreatmentRequests[request.patientId] = request;
      }
    }
    final financialRecordsInPeriod = source.financialRecords
        .where((record) => patientIds.contains(record.patientId))
        .where((record) => inPeriod(record.assessedAt))
        .toList();

    final handovers = <ReportDispense>[];
    for (final patient in patients) {
      for (final record in patient.dispenseRecords) {
        final parsed = DateTime.tryParse(record.date);
        if (parsed == null || !inPeriod(parsed)) continue;
        if (filters.centerId != null && record.centerId != filters.centerId) {
          continue;
        }
        handovers.add(ReportDispense(patient, record, parsed));
      }
    }
    handovers.sort((a, b) => a.date.compareTo(b.date));
    final weightObservations = <ReportWeightObservation>[];
    for (final plan in plans) {
      final patient = source.getPatientById(plan.patientId);
      if (patient == null) continue;
      for (final session in plan.sessions) {
        final weight = session.weightAfter;
        if (weight == null || !inPeriod(session.scheduledDate)) continue;
        weightObservations.add(
          ReportWeightObservation(patient, session.scheduledDate, weight),
        );
      }
    }
    weightObservations.sort((a, b) => a.date.compareTo(b.date));

    final appointments = patients
        .expand((patient) => source.appointmentsFor(patient.id))
        .where((appointment) => inPeriod(appointment.dateTime))
        .toList();
    final labResults = patients.expand((patient) => patient.labResults).where((
      result,
    ) {
      final date = DateTime.tryParse(result.date);
      return date != null && inPeriod(date);
    }).toList();
    final doseEvents = source.medicationEvents
        .where((event) => patientIds.contains(event.patientId))
        .where((event) => inPeriod(event.recordedAt))
        .toList();

    return ReportAnalyticsData._(
      source: source,
      filters: filters,
      generatedAt: generatedAt,
      periodStart: start,
      periodEnd: generatedAt,
      patients: patients,
      centers: visibleCenters,
      plans: plans,
      requests: requests,
      requestsInPeriod: requestsInPeriod,
      treatmentRequests: treatmentRequests,
      treatmentRequestsInPeriod: treatmentRequestsInPeriod,
      financialRecordsInPeriod: financialRecordsInPeriod,
      handovers: handovers,
      weightObservations: weightObservations,
      appointments: appointments,
      labResults: labResults,
      doseEvents: doseEvents,
      latestRequestByPatient: latestRequests,
      latestTreatmentRequestByPatient: latestTreatmentRequests,
    );
  }

  int get eligiblePatients =>
      patients.where((patient) => patient.programEligibility.eligible).length;
  int get activePlans => patients
      .where((patient) => source.getPlanForPatient(patient.id) != null)
      .length;
  int get pendingMedicalReview => treatmentRequests
      .where(
        (request) =>
            latestTreatmentRequestByPatient[request.patientId]?.id ==
            request.id,
      )
      .where(
        (request) =>
            request.status == RequestStatus.submitted ||
            request.status == RequestStatus.assessing ||
            request.status == RequestStatus.needsInformation ||
            request.status == RequestStatus.underReview,
      )
      .map((request) => request.patientId)
      .toSet()
      .length;
  int get lowStockFacilities =>
      centers.where((center) => center.totalAvailable < 10).length;
  int get readyForDispensing => requestsInPeriod
      .where((request) => request.status == PharmacyRequestStatus.ready)
      .length;
  int get blockedRequests => requestsInPeriod
      .where(
        (request) =>
            request.status == PharmacyRequestStatus.notEligible ||
            request.status == PharmacyRequestStatus.outOfStock ||
            request.status == PharmacyRequestStatus.expired,
      )
      .length;
  int get totalAvailableUnits =>
      centers.fold(0, (sum, center) => sum + center.totalAvailable);
  int get unitsExpiringWithin90Days => centers
      .expand((center) => center.batches)
      .where(
        (batch) =>
            !batch.expiryDate.isBefore(generatedAt) &&
            batch.expiryDate.isBefore(
              generatedAt.add(const Duration(days: 90)),
            ),
      )
      .fold(0, (sum, batch) => sum + batch.quantity);
  double? get averageBmi => patients.isEmpty
      ? null
      : patients.fold<double>(0, (sum, patient) => sum + patient.bmi) /
            patients.length;
  double? get adherenceRate {
    if (doseEvents.isEmpty) return null;
    final completed = doseEvents
        .where((event) => event.status == MedicationDoseStatus.taken)
        .length;
    return completed / doseEvents.length;
  }

  int get missedDoses => doseEvents
      .where((event) => event.status == MedicationDoseStatus.missed)
      .length;
  int get abnormalLabResults =>
      labResults.where((result) => !isWithinReference(result)).length;
  int get uniquePatientsDispensed =>
      handovers.map((entry) => entry.patient.id).toSet().length;
  int get clinicalReviewsInPeriod => treatmentRequestsInPeriod
      .where(
        (request) =>
            request.status == RequestStatus.submitted ||
            request.status == RequestStatus.assessing ||
            request.status == RequestStatus.needsInformation ||
            request.status == RequestStatus.underReview,
      )
      .map((request) => request.patientId)
      .toSet()
      .length;
  int get settledClaimCount => financialRecordsInPeriod
      .where((record) => record.status == FinancialReviewStatus.settled)
      .length;
  double get assessedProgramValueAed => financialRecordsInPeriod
      .where((record) => record.status != FinancialReviewStatus.cancelled)
      .fold(0, (sum, record) => sum + record.totalAed);
  double get assessedCoverageAed => financialRecordsInPeriod
      .where((record) => record.status != FinancialReviewStatus.cancelled)
      .fold(0, (sum, record) => sum + record.coveredAed);
  double get assessedPatientShareAed => financialRecordsInPeriod
      .where((record) => record.status != FinancialReviewStatus.cancelled)
      .fold(0, (sum, record) => sum + record.copayAed);
  double get settledProgramValueAed => financialRecordsInPeriod
      .where((record) => record.status == FinancialReviewStatus.settled)
      .fold(0, (sum, record) => sum + record.totalAed);
  double get settledCoverageAed => financialRecordsInPeriod
      .where((record) => record.status == FinancialReviewStatus.settled)
      .fold(0, (sum, record) => sum + record.coveredAed);
  double get estimatedProgramValueAed => financialSummaries.fold(
    0,
    (sum, item) => sum + item.estimatedProgramValueAed,
  );
  double get estimatedCoverageAed => financialSummaries.fold(
    0,
    (sum, item) => sum + item.estimatedCoverageAed,
  );
  double get estimatedPatientShareAed => financialSummaries.fold(
    0,
    (sum, item) => sum + item.estimatedPatientShareAed,
  );

  List<ReportFinancialSummary> get financialSummaries =>
      ResidencyStatus.values.map((status) {
        final categoryPatients = patients
            .where((patient) => patient.residencyStatus == status)
            .toList();
        var programValue = 0.0;
        var coverage = 0.0;
        var patientShare = 0.0;
        var planCount = 0;
        for (final patient in categoryPatients) {
          final plan = source.getPlanForPatient(patient.id);
          if (plan == null) continue;
          planCount++;
          final amount =
              DemoFinancialSupportPolicy.medicationUnitPriceAed *
              plan.medicationQuantity;
          final covered =
              amount * DemoFinancialSupportPolicy.coverageRateFor(status);
          programValue += amount;
          coverage += covered;
          patientShare += amount - covered;
        }
        return ReportFinancialSummary(
          residency: status,
          patients: categoryPatients.length,
          activePlans: planCount,
          estimatedProgramValueAed: programValue,
          estimatedCoverageAed: coverage,
          estimatedPatientShareAed: patientShare,
        );
      }).toList();

  List<ReportClinicalMonth> get clinicalMonthlyObservations {
    final groups = <DateTime, List<ReportWeightObservation>>{};
    for (final observation in weightObservations) {
      final month = DateTime(observation.date.year, observation.date.month);
      groups.putIfAbsent(month, () => []).add(observation);
    }
    final months = groups.keys.toList()..sort();
    return months.map((month) {
      final observations = groups[month]!;
      final averageWeight =
          observations.fold<double>(0, (sum, entry) => sum + entry.weight) /
          observations.length;
      final averageBmi =
          observations.fold<double>(
            0,
            (sum, entry) =>
                sum +
                entry.weight /
                    ((entry.patient.height / 100) *
                        (entry.patient.height / 100)),
          ) /
          observations.length;
      return ReportClinicalMonth(
        month: month,
        averageWeight: averageWeight,
        averageBmi: averageBmi,
        observations: observations.length,
      );
    }).toList();
  }

  bool isWithinReference(PatientLabResult result) {
    final range = result.referenceRange.trim();
    final less = RegExp(r'^<\s*([0-9.]+)').firstMatch(range);
    if (less != null) return result.value < double.parse(less.group(1)!);
    final greater = RegExp(r'^>\s*([0-9.]+)').firstMatch(range);
    if (greater != null) return result.value > double.parse(greater.group(1)!);
    final bounds = RegExp(r'([0-9.]+)\s*[–-]\s*([0-9.]+)').firstMatch(range);
    if (bounds != null) {
      return result.value >= double.parse(bounds.group(1)!) &&
          result.value <= double.parse(bounds.group(2)!);
    }
    return true; // An unparseable reference is not silently called abnormal.
  }

  List<int> get journeyCounts {
    final assessed = patients
        .where(
          (patient) =>
              patient.medicalConditions.isNotEmpty &&
              patient.labResults.isNotEmpty,
        )
        .toList();
    final eligible = assessed
        .where((patient) => patient.programEligibility.eligible)
        .toList();
    final planned = eligible
        .where((patient) => source.getPlanForPatient(patient.id) != null)
        .toList();
    final review = planned.where((patient) {
      final status = latestTreatmentRequestByPatient[patient.id]?.status;
      return status == RequestStatus.submitted ||
          status == RequestStatus.assessing ||
          status == RequestStatus.needsInformation ||
          status == RequestStatus.underReview;
    }).toList();
    final approved = planned.where((patient) {
      final status = latestTreatmentRequestByPatient[patient.id]?.status;
      return status == RequestStatus.approved ||
          status == RequestStatus.readyToDispense ||
          status == RequestStatus.dispensed ||
          status == RequestStatus.monitoring ||
          status == RequestStatus.renewalDue ||
          status == RequestStatus.completed;
    }).toList();
    final pharmacyReady = approved.where((patient) {
      final request = latestRequestByPatient[patient.id];
      final status = latestTreatmentRequestByPatient[patient.id]?.status;
      return request != null &&
          request.status == PharmacyRequestStatus.ready &&
          status == RequestStatus.readyToDispense;
    }).toList();
    final dispensedPatientIds = handovers
        .map((entry) => entry.patient.id)
        .toSet();
    final followUpPatientIds = appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.completed,
        )
        .map((appointment) => appointment.patientId)
        .toSet();
    return [
      patients.length,
      assessed.length,
      eligible.length,
      planned.length,
      review.length,
      approved.length,
      pharmacyReady.length,
      dispensedPatientIds.length,
      followUpPatientIds.length,
    ];
  }

  List<ReportMonth> get monthlyHandovers {
    final first = DateTime(periodStart.year, periodStart.month);
    final last = DateTime(periodEnd.year, periodEnd.month);
    final buckets = <DateTime, int>{};
    for (
      var month = first;
      !month.isAfter(last);
      month = DateTime(month.year, month.month + 1)
    ) {
      buckets[month] = 0;
    }
    for (final handover in handovers) {
      final key = DateTime(handover.date.year, handover.date.month);
      buckets.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return buckets.entries
        .map((entry) => ReportMonth(entry.key, entry.value))
        .toList();
  }

  List<ReportEmirateSummary> get emirateSummaries {
    final grouped = <String, List<Patient>>{};
    for (final patient in patients) {
      grouped.putIfAbsent(patient.emirate, () => []).add(patient);
    }
    final results = grouped.entries.map((entry) {
      final ids = entry.value.map((patient) => patient.id).toSet();
      return ReportEmirateSummary(
        emirate: entry.key,
        patients: entry.value.length,
        eligiblePatients: entry.value
            .where((patient) => patient.programEligibility.eligible)
            .length,
        activePlans: entry.value
            .where((patient) => source.getPlanForPatient(patient.id) != null)
            .length,
        handovers: handovers
            .where((item) => ids.contains(item.patient.id))
            .length,
      );
    }).toList();
    results.sort((a, b) => b.patients.compareTo(a.patients));
    return results;
  }

  List<ReportFacilitySummary> get facilitySummaries => centers.map((center) {
    final linked = patients.where((patient) {
      return patient.lastDispensingCenterId == center.id ||
          patient.dispenseRecords.any(
            (record) => record.centerId == center.id,
          ) ||
          plans.any(
            (plan) =>
                plan.patientId == patient.id &&
                plan.assignedCenterId == center.id,
          ) ||
          requests.any(
            (request) =>
                request.patientId == patient.id &&
                request.assignedCenterId == center.id,
          );
    }).toList();
    return ReportFacilitySummary(
      center: center,
      patients: linked.length,
      handovers: handovers
          .where((entry) => entry.record.centerId == center.id)
          .length,
    );
  }).toList();

  List<ReportDoctorSummary> get doctorSummaries {
    final result = <ReportDoctorSummary>[];
    for (final doctor in source.doctors) {
      if (filters.doctorId != null && doctor.id != filters.doctorId) {
        continue;
      }
      if (filters.emirate != null && doctor.emirate != filters.emirate) {
        continue;
      }
      final normalized = doctor.name
          .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
          .trim()
          .toLowerCase();
      final linkedPlans = plans.where((plan) {
        final planName = plan.doctorName
            .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
            .trim()
            .toLowerCase();
        return planName.startsWith(normalized) ||
            normalized.startsWith(planName);
      }).toList();
      final linkedPatientIds = linkedPlans
          .map((plan) => plan.patientId)
          .toSet();
      final activePlans = linkedPlans
          .where((plan) => plan.status.toLowerCase() == 'active')
          .toList();
      result.add(
        ReportDoctorSummary(
          doctor: doctor,
          patients: linkedPatientIds.length,
          activePlans: activePlans.length,
          approvedPlans: activePlans
              .where((plan) => plan.clinicalApprovalStatus == 'approved')
              .length,
          handovers: handovers
              .where((entry) => linkedPatientIds.contains(entry.patient.id))
              .length,
        ),
      );
    }
    result.sort((a, b) => b.activePlans.compareTo(a.activePlans));
    return result;
  }

  Map<ResidencyStatus, int> get residencyCounts => {
    for (final status in ResidencyStatus.values)
      status: patients.where((p) => p.residencyStatus == status).length,
  };

  String toCsv() {
    final rows = <List<String>>[];
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    rows.add(['Report', 'Program performance overview']);
    rows.add(['Environment', 'Demo data — in-memory application records']);
    rows.add([
      'Reporting period',
      '${date(periodStart)} to ${date(periodEnd)}',
    ]);
    rows.add(['Generated at', generatedAt.toIso8601String()]);
    rows.add(['Active filters', _activeFilterDescription()]);
    rows.add(['Disclaimer', 'Demonstration data; not a ministry submission']);
    rows.add([]);
    rows.add(['Metric', 'Value', 'Definition']);
    rows.add([
      'Patients in registry',
      '${patients.length}',
      'Current roster after cohort filters; not period-bound',
    ]);
    rows.add([
      'Eligible patients',
      '$eligiblePatients',
      'Current local clinical eligibility rule / filtered roster',
    ]);
    rows.add([
      'Active treatment plans',
      '$activePlans',
      'Patients with an active plan',
    ]);
    rows.add([
      'Dispensing handovers',
      '${handovers.length}',
      'Patient dispensing records dated inside the selected period',
    ]);
    rows.add([
      'Unique patients dispensed',
      '$uniquePatientsDispensed',
      'Distinct patients with a handover in the selected period',
    ]);
    rows.add([
      'Pending medical review',
      '$pendingMedicalReview',
      'Unique patients with current canonical treatment requests in submitted, assessing, needs-information or under-review states; point-in-time',
    ]);
    rows.add([
      'Facilities below stock threshold',
      '$lowStockFacilities',
      'Selected facilities with fewer than 10 available units',
    ]);
    rows.add([
      'Available inventory units',
      '$totalAvailableUnits',
      'Current stock across selected facilities; point-in-time',
    ]);
    rows.add([
      'Adherence rate',
      adherenceRate == null
          ? 'Not available'
          : '${(adherenceRate! * 100).toStringAsFixed(1)}%',
      'Taken medication events divided by all recorded dose events in period',
    ]);
    rows.add([
      'Demo-estimated program value (AED)',
      estimatedProgramValueAed.toStringAsFixed(2),
      'Current plans × configurable demo unit price and plan quantity; not a tariff or ministry policy',
    ]);
    rows.add([
      'Demo-estimated coverage (AED)',
      estimatedCoverageAed.toStringAsFixed(2),
      '${DemoFinancialSupportPolicy.policyLabel}; assumptions: unit price AED ${DemoFinancialSupportPolicy.medicationUnitPriceAed.toStringAsFixed(0)}, citizen ${(DemoFinancialSupportPolicy.citizenCoverageRate * 100).round()}%, resident ${(DemoFinancialSupportPolicy.residentCoverageRate * 100).round()}%, visitor ${(DemoFinancialSupportPolicy.visitorCoverageRate * 100).round()}%',
    ]);
    rows.add([
      'Demo-estimated patient share (AED)',
      estimatedPatientShareAed.toStringAsFixed(2),
      'Modeled current-plan copay under the local demo assumption only',
    ]);
    rows.add([
      'Settled support records (period)',
      '$settledClaimCount',
      'Shared financial records assessed in the period and marked settled',
    ]);
    rows.add([
      'Settled program value (AED, period)',
      settledProgramValueAed.toStringAsFixed(2),
      'Sum of totalAed on settled shared records assessed in the period',
    ]);
    rows.add([
      'Settled covered amount (AED, period)',
      settledCoverageAed.toStringAsFixed(2),
      'Sum of coveredAed on settled shared records assessed in the period',
    ]);
    rows.add([
      'Assessed value (AED, period; non-cancelled)',
      assessedProgramValueAed.toStringAsFixed(2),
      'Sum of totalAed on non-cancelled shared financial records assessed in the period',
    ]);
    rows.add([
      'Assessed coverage (AED, period; non-cancelled)',
      assessedCoverageAed.toStringAsFixed(2),
      'Sum of coveredAed on non-cancelled shared financial records assessed in the period',
    ]);
    rows.add([
      'Assessed copay (AED, period; non-cancelled)',
      assessedPatientShareAed.toStringAsFixed(2),
      'Sum of copayAed on non-cancelled shared financial records assessed in the period',
    ]);
    rows.add([]);
    rows.add([
      'Emirate',
      'Patients',
      'Eligible',
      'Active plans',
      'Dispensing handovers',
    ]);
    for (final item in emirateSummaries) {
      rows.add([
        item.emirate,
        '${item.patients}',
        '${item.eligiblePatients}',
        '${item.activePlans}',
        '${item.handovers}',
      ]);
    }
    rows.add([]);
    rows.add([
      'Facility',
      'Emirate',
      'Patients linked',
      'Period handovers',
      'Current available units',
      'Below 10-unit threshold',
    ]);
    for (final item in facilitySummaries) {
      rows.add([
        item.center.name,
        item.center.region,
        '${item.patients}',
        '${item.handovers}',
        '${item.center.totalAvailable}',
        item.center.totalAvailable < 10 ? 'Yes' : 'No',
      ]);
    }
    rows.add([]);
    rows.add([
      'Residency',
      'Patients',
      'Active plans',
      'Estimated program value AED (demo)',
      'Estimated coverage AED (demo)',
      'Estimated patient share AED (demo)',
    ]);
    for (final item in financialSummaries) {
      rows.add([
        item.residency.name,
        '${item.patients}',
        '${item.activePlans}',
        item.estimatedProgramValueAed.toStringAsFixed(2),
        item.estimatedCoverageAed.toStringAsFixed(2),
        item.estimatedPatientShareAed.toStringAsFixed(2),
      ]);
    }
    rows.add([]);
    rows.add(['Patient journey stage', 'Patients', 'Definition']);
    const stageNames = [
      'Current roster',
      'Assessed',
      'Eligible',
      'Active plan',
      'Medical review',
      'Approved or later',
      'Ready at pharmacy',
      'Actual period handover',
      'Completed period follow-up',
    ];
    const stageDefinitions = [
      'Current filtered patient roster; no registration date is available',
      'Has at least one medical condition and one lab result',
      'Local eligibility rule for assessed patients',
      'Filtered patients with a current plan',
      'Current latest treatment request is in a medical review state',
      'Current latest treatment request is approved or later in workflow',
      'Current latest treatment and pharmacy requests are ready',
      'Distinct patients with a dated handover inside the period',
      'Distinct patients with completed appointments inside the period',
    ];
    final stages = journeyCounts;
    for (var index = 0; index < stageNames.length; index++) {
      rows.add([
        stageNames[index],
        '${stages[index]}',
        stageDefinitions[index],
      ]);
    }
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert({
    'report': 'program-performance',
    'environment': 'demo',
    'generatedAt': generatedAt.toIso8601String(),
    'period': {
      'start': periodStart.toIso8601String(),
      'end': periodEnd.toIso8601String(),
      'days': filters.periodDays,
    },
    'filters': {
      'emirate': filters.emirate,
      'centerId': filters.centerId,
      'residency': filters.residency?.name,
      'careStatus': filters.careStatus,
      'pharmacyRequestStatus': filters.requestStatus?.name,
      'treatmentRequestStatus': filters.treatmentRequestStatus?.name,
      'doctorId': filters.doctorId,
    },
    'disclaimer': 'Demonstration data; not a ministry submission.',
    'metrics': {
      'patientsInCurrentRoster': patients.length,
      'eligiblePatients': eligiblePatients,
      'activePlans': activePlans,
      'dispensingHandoversInPeriod': handovers.length,
      'uniquePatientsDispensedInPeriod': uniquePatientsDispensed,
      'currentPatientsAwaitingMedicalReview': pendingMedicalReview,
      'lowStockFacilities': lowStockFacilities,
      'availableInventoryUnits': totalAvailableUnits,
      'adherenceRate': adherenceRate,
      'missedDoses': missedDoses,
      'labResultsInPeriod': labResults.length,
      'abnormalLabResultsInPeriod': abnormalLabResults,
      'completedAppointmentsInPeriod': appointments
          .where((item) => item.status == AppointmentStatus.completed)
          .length,
    },
    'dispensingHandoversByMonth': [
      for (final month in monthlyHandovers)
        {
          'month':
              '${month.month.year}-${month.month.month.toString().padLeft(2, '0')}',
          'handovers': month.handovers,
        },
    ],
    'documentedWeightTrends': [
      for (final month in clinicalMonthlyObservations)
        {
          'month':
              '${month.month.year}-${month.month.month.toString().padLeft(2, '0')}',
          'averageWeightKg': month.averageWeight,
          'averageBmi': month.averageBmi,
          'rehabilitationSessionObservations': month.observations,
        },
    ],
    'emirates': [
      for (final item in emirateSummaries)
        {
          'emirate': item.emirate,
          'patients': item.patients,
          'eligiblePatients': item.eligiblePatients,
          'activePlans': item.activePlans,
          'periodHandovers': item.handovers,
        },
    ],
    'facilities': [
      for (final item in facilitySummaries)
        {
          'name': item.center.name,
          'emirate': item.center.region,
          'linkedPatients': item.patients,
          'periodHandovers': item.handovers,
          'availableUnits': item.center.totalAvailable,
          'belowDemoThreshold': item.center.totalAvailable < 10,
        },
    ],
    'financial': {
      'demoPolicy': {
        'label': DemoFinancialSupportPolicy.policyLabel,
        'medicationUnitPriceAed':
            DemoFinancialSupportPolicy.medicationUnitPriceAed,
        'citizenCoverageRate': DemoFinancialSupportPolicy.citizenCoverageRate,
        'residentCoverageRate': DemoFinancialSupportPolicy.residentCoverageRate,
        'visitorCoverageRate': DemoFinancialSupportPolicy.visitorCoverageRate,
        'disclaimer':
            'Local demo assumption; not approved ministry policy or tariff.',
      },
      'estimatedCurrentProgramValueAed': estimatedProgramValueAed,
      'estimatedCurrentCoverageAed': estimatedCoverageAed,
      'estimatedCurrentPatientShareAed': estimatedPatientShareAed,
      'settledClaimsInPeriod': settledClaimCount,
      'settledProgramValueAedInPeriod': settledProgramValueAed,
      'settledCoverageAedInPeriod': settledCoverageAed,
      'byResidency': [
        for (final item in financialSummaries)
          {
            'residency': item.residency.name,
            'patients': item.patients,
            'activePlans': item.activePlans,
            'estimatedProgramValueAed': item.estimatedProgramValueAed,
            'estimatedCoverageAed': item.estimatedCoverageAed,
            'estimatedPatientShareAed': item.estimatedPatientShareAed,
          },
      ],
    },
    'journeyStageCounts': [
      for (var index = 0; index < journeyCounts.length; index++)
        {'stage': index + 1, 'patients': journeyCounts[index]},
    ],
  });

  String toPrintableHtml({bool arabic = false}) {
    const escape = HtmlEscape();
    String e(Object? value) => escape.convert(value?.toString() ?? '—');
    String table(List<String> headers, List<List<Object?>> rows) =>
        '<table><thead><tr>${headers.map((item) => '<th>${e(item)}</th>').join()}</tr></thead><tbody>${rows.map((row) => '<tr>${row.map((item) => '<td>${e(item)}</td>').join()}</tr>').join()}</tbody></table>';
    final labels = arabic
        ? const {
            'title': 'تقرير أداء البرنامج',
            'period': 'الفترة',
            'generated': 'تاريخ الإنشاء',
            'disclaimer':
                'بيانات تجريبية — ليست تقريرًا رسميًا أو إرسالًا للوزارة.',
            'overview': 'مؤشرات البرنامج',
            'metric': 'المؤشر',
            'value': 'القيمة',
            'monthly': 'التسليمات الشهرية',
            'month': 'الشهر',
            'handovers': 'عمليات التسليم',
            'journey': 'مراحل رحلة المريض',
            'stage': 'المرحلة',
            'patients': 'المرضى',
            'regions': 'التوزيع حسب الإمارة',
            'emirate': 'الإمارة',
            'eligible': 'مؤهلون',
            'plans': 'خطط نشطة',
            'facilities': 'المنشآت والمخزون',
            'facility': 'المنشأة',
            'units': 'الوحدات المتاحة',
            'financial': 'ملخص مالي',
            'estimated': 'تقديرات الديمو للخطة الحالية — غير معتمدة',
            'residency': 'الإقامة',
            'programValue': 'قيمة البرنامج التقديرية AED',
            'coverage': 'التغطية التقديرية AED',
            'copay': 'حصة المريض التقديرية AED',
            'settled': 'سجلات مسوّاة في الفترة',
            'settledCoverage': 'تغطية مسوّاة AED',
          }
        : const {
            'title': 'Program performance report',
            'period': 'Reporting period',
            'generated': 'Generated at',
            'disclaimer':
                'Demonstration data — not an official report or ministry submission.',
            'overview': 'Program indicators',
            'metric': 'Metric',
            'value': 'Value',
            'monthly': 'Monthly handovers',
            'month': 'Month',
            'handovers': 'Handovers',
            'journey': 'Patient journey stages',
            'stage': 'Stage',
            'patients': 'Patients',
            'regions': 'Distribution by emirate',
            'emirate': 'Emirate',
            'eligible': 'Eligible',
            'plans': 'Active plans',
            'facilities': 'Facilities & inventory',
            'facility': 'Facility',
            'units': 'Available units',
            'financial': 'Financial summary',
            'estimated':
                'Demo estimates for current plans — not approved policy',
            'residency': 'Residency',
            'programValue': 'Estimated program value AED',
            'coverage': 'Estimated coverage AED',
            'copay': 'Estimated patient share AED',
            'settled': 'Settled records in period',
            'settledCoverage': 'Settled coverage AED',
          };
    const stageEn = [
      'Current roster',
      'Assessed',
      'Eligible',
      'Active plan',
      'Medical review',
      'Approved or later',
      'Ready at pharmacy',
      'Actual period handover',
      'Completed period follow-up',
    ];
    const stageAr = [
      'السجل الحالي',
      'تقييم موثق',
      'مؤهل',
      'خطة نشطة',
      'مراجعة طبية',
      'معتمد أو في مرحلة لاحقة',
      'جاهز بالصيدلية',
      'تسليم فعلي خلال الفترة',
      'متابعة مكتملة خلال الفترة',
    ];
    final stages = journeyCounts;
    final metricRows = <List<Object?>>[
      ['Patients in current roster', patients.length],
      ['Eligible patients', eligiblePatients],
      ['Active treatment plans', activePlans],
      ['Actual handovers in period', handovers.length],
      ['Unique patients dispensed', uniquePatientsDispensed],
      ['Current patients awaiting medical review', pendingMedicalReview],
      ['Low-stock facilities', lowStockFacilities],
      ['Available inventory units', totalAvailableUnits],
      [
        'Recorded adherence',
        adherenceRate == null
            ? 'Not available'
            : '${(adherenceRate! * 100).toStringAsFixed(1)}%',
      ],
      ['Lab results in period', labResults.length],
      ['Abnormal lab results in period', abnormalLabResults],
    ];
    final financeRows = financialSummaries
        .map(
          (item) => [
            item.residency.name,
            item.patients,
            item.activePlans,
            item.estimatedProgramValueAed.toStringAsFixed(2),
            item.estimatedCoverageAed.toStringAsFixed(2),
            item.estimatedPatientShareAed.toStringAsFixed(2),
          ],
        )
        .toList();
    final direction = arabic ? 'rtl' : 'ltr';
    return '''<!doctype html><html lang="${arabic ? 'ar' : 'en'}" dir="$direction"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${e(labels['title'])}</title><style>
      :root{color-scheme:light}body{font:14px Arial,sans-serif;color:#172b3b;margin:32px;line-height:1.45}header{border-bottom:3px solid #16533a;padding-bottom:16px;margin-bottom:22px}h1{font-size:26px;margin:0 0 8px;color:#0a2b3e}h2{font-size:17px;color:#16533a;margin:22px 0 8px}.meta{color:#526271;font-size:12px}.notice{background:#fff7e6;border:1px solid #e5c77e;padding:10px;border-radius:8px;margin-top:12px}table{border-collapse:collapse;width:100%;margin:8px 0 16px;font-size:12px}th,td{border:1px solid #dce3e8;padding:7px 9px;text-align:start}th{background:#edf4f1;color:#0a2b3e}tr:nth-child(even) td{background:#fafcfc}.actions{position:fixed;top:14px;${arabic ? 'left' : 'right'}:18px}button{padding:9px 14px;background:#16533a;color:white;border:0;border-radius:6px;font-size:13px;cursor:pointer}@media print{body{margin:14mm}.actions{display:none}h2{break-after:avoid}table{break-inside:auto}tr{break-inside:avoid;break-after:auto}}
      </style><script>window.addEventListener('load',()=>setTimeout(()=>window.print(),300));</script></head><body><div class="actions"><button onclick="window.print()">${arabic ? 'طباعة / حفظ PDF' : 'Print / Save PDF'}</button></div><header><h1>${e(labels['title'])}</h1><div class="meta">${e(labels['period'])}: ${e(periodStart.toIso8601String().substring(0, 10))} — ${e(periodEnd.toIso8601String().substring(0, 10))}</div><div class="meta">${e(labels['generated'])}: ${e(generatedAt.toIso8601String())}</div><div class="notice">${e(labels['disclaimer'])}</div></header><h2>${e(labels['overview'])}</h2>${table([labels['metric']!, labels['value']!], metricRows)}<h2>${e(labels['monthly'])}</h2>${table([labels['month']!, labels['handovers']!], monthlyHandovers.map((item) => ['${item.month.year}-${item.month.month.toString().padLeft(2, '0')}', item.handovers]).toList())}<h2>${e(labels['journey'])}</h2>${table([labels['stage']!, labels['patients']!], List.generate(stages.length, (index) => [arabic ? stageAr[index] : stageEn[index], stages[index]]))}<h2>${e(labels['regions'])}</h2>${table([labels['emirate']!, labels['patients']!, labels['eligible']!, labels['plans']!, labels['handovers']!], emirateSummaries.map((item) => [item.emirate, item.patients, item.eligiblePatients, item.activePlans, item.handovers]).toList())}<h2>${e(labels['facilities'])}</h2>${table([labels['facility']!, labels['emirate']!, labels['patients']!, labels['handovers']!, labels['units']!], facilitySummaries.map((item) => [item.center.name, item.center.region, item.patients, item.handovers, item.center.totalAvailable]).toList())}<h2>${e(labels['financial'])}</h2><p>${e(labels['estimated'])}. ${e(DemoFinancialSupportPolicy.policyLabel)}. Unit price AED ${DemoFinancialSupportPolicy.medicationUnitPriceAed.toStringAsFixed(0)}; citizen ${(DemoFinancialSupportPolicy.citizenCoverageRate * 100).round()}%, resident ${(DemoFinancialSupportPolicy.residentCoverageRate * 100).round()}%, visitor ${(DemoFinancialSupportPolicy.visitorCoverageRate * 100).round()}. Not ministry policy.</p>${table([labels['residency']!, labels['patients']!, labels['plans']!, labels['programValue']!, labels['coverage']!, labels['copay']!], financeRows)}<p>${e(labels['settled'])}: $settledClaimCount · ${e(labels['settledCoverage'])}: AED ${settledCoverageAed.toStringAsFixed(2)}.</p></body></html>''';
  }

  String _activeFilterDescription() {
    final values = <String>['${filters.periodDays}-day window'];
    if (filters.emirate != null) values.add('Emirate=${filters.emirate}');
    if (filters.centerId != null) values.add('Facility=${filters.centerId}');
    if (filters.residency != null) {
      values.add('Residency=${filters.residency!.name}');
    }
    if (filters.careStatus != null) {
      values.add('Plan status=${filters.careStatus}');
    }
    if (filters.requestStatus != null) {
      values.add('Request=${filters.requestStatus!.name}');
    }
    if (filters.treatmentRequestStatus != null) {
      values.add('Treatment workflow=${filters.treatmentRequestStatus!.name}');
    }
    if (filters.doctorId != null) values.add('Doctor=${filters.doctorId}');
    if (filters.treatmentRequestStatus != null) {
      values.add('Treatment workflow=${filters.treatmentRequestStatus!.name}');
    }
    return values.join('; ');
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
