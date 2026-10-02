import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/features/dashboard/admin_views/report_analytics_data.dart';
import 'package:mounjaro_demo/features/journey/journey_models.dart';

void main() {
  late DataProvider source;

  setUp(() {
    source = DataProvider();
  });

  test(
    'report snapshot derives roster, plans and eligibility from DataProvider',
    () {
      final report = ReportAnalyticsData.derive(
        source,
        const ReportFilters(periodDays: 365),
        now: DateTime(2027, 1, 1),
      );

      expect(report.patients.length, source.patients.length);
      expect(
        report.eligiblePatients,
        source.patients
            .where((patient) => patient.programEligibility.eligible)
            .length,
      );
      expect(
        report.activePlans,
        source.patients
            .where((patient) => source.getPlanForPatient(patient.id) != null)
            .length,
      );
      expect(
        report.handovers.length,
        source.patients.expand((patient) => patient.dispenseRecords).where((
          record,
        ) {
          final date = DateTime.tryParse(record.date);
          return date != null &&
              !date.isBefore(report.periodStart) &&
              !date.isAfter(report.periodEnd);
        }).length,
      );
    },
  );

  test('filters apply to the shared cohort and regional aggregation', () {
    final report = ReportAnalyticsData.derive(
      source,
      const ReportFilters(periodDays: 365, emirate: 'Abu Dhabi'),
      now: DateTime(2027, 1, 1),
    );

    expect(report.patients, isNotEmpty);
    expect(
      report.patients.every((patient) => patient.emirate == 'Abu Dhabi'),
      isTrue,
    );
    expect(
      report.centers.every((center) => center.region == 'Abu Dhabi'),
      isTrue,
    );
    expect(report.emirateSummaries, hasLength(1));
    expect(report.emirateSummaries.single.emirate, 'Abu Dhabi');
    expect(
      source.patients.any((patient) => patient.emirate == 'Al Ain'),
      isFalse,
    );
    expect(source.centers.any((center) => center.region == 'Al Ain'), isFalse);
  });

  test('dispense series is chronological and uses actual handover records', () {
    final report = ReportAnalyticsData.derive(
      source,
      const ReportFilters(periodDays: 365),
      now: DateTime(2027, 1, 1),
    );
    final monthlyTotal = report.monthlyHandovers.fold<int>(
      0,
      (sum, month) => sum + month.handovers,
    );

    expect(monthlyTotal, report.handovers.length);
    final monthValues = report.monthlyHandovers
        .map((entry) => entry.month)
        .toList();
    expect(monthValues, orderedEquals([...monthValues]..sort()));
  });

  test('estimated coverage is labelled and adherence requires dose events', () {
    final report = ReportAnalyticsData.derive(
      source,
      const ReportFilters(periodDays: 365),
      now: DateTime(2027, 1, 1),
    );

    expect(report.adherenceRate, isNull);
    expect(report.toCsv(), contains('"Demo-estimated coverage (AED)"'));
    expect(report.toCsv(), contains('"Settled support records (period)","0"'));
    expect(report.toJson(), contains('"demoPolicy"'));
    final json = jsonDecode(report.toJson()) as Map<String, dynamic>;
    expect(json['environment'], 'demo');
    expect(
      json['financial']['demoPolicy']['disclaimer'],
      contains('not approved'),
    );
    expect(
      report.pendingMedicalReview,
      report.latestTreatmentRequestByPatient.values
          .where(
            (request) =>
                request.status == RequestStatus.submitted ||
                request.status == RequestStatus.assessing ||
                request.status == RequestStatus.needsInformation ||
                request.status == RequestStatus.underReview,
          )
          .length,
    );

    final plan = source.treatmentPlans.firstWhere(
      (item) => item.patientId == 'P999',
    );
    source.logMedication(plan.id, DateTime(2026, 12, 20));
    final afterCheckIn = ReportAnalyticsData.derive(
      source,
      const ReportFilters(periodDays: 365),
      now: DateTime(2027, 1, 1),
    );
    expect(afterCheckIn.adherenceRate, 1);
  });

  test('treatment workflow filter scopes every patient-linked result', () {
    final status = source.treatmentRequestHistory.values
        .expand((history) => history)
        .first
        .status;
    final report = ReportAnalyticsData.derive(
      source,
      ReportFilters(periodDays: 365, treatmentRequestStatus: status),
      now: DateTime(2027, 1, 1),
    );

    expect(
      report.patients.every(
        (patient) =>
            source.activeTreatmentRequestFor(patient.id)?.status == status,
      ),
      isTrue,
    );
    expect(
      report.requests.every(
        (request) => report.patients.any((p) => p.id == request.patientId),
      ),
      isTrue,
    );
  });
}
