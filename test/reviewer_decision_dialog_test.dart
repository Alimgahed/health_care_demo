import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/clinical/clinical_review_detail_panel.dart';
import 'package:mounjaro_demo/features/dashboard/web/web_doctor_shell.dart';
import 'package:mounjaro_demo/features/journey/journey_models.dart';
import 'package:mounjaro_demo/features/journey/journey_provider.dart';
import 'package:mounjaro_demo/features/journey/journey_screen.dart';
import 'package:mounjaro_demo/features/treatment_plan/models/treatment_plan.dart';

void main() {
  testWidgets('reviewer rejection requires a reason before confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    final journey = JourneyProvider()..loadScenario(DemoScenario.humanOverride);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: journey,
        child: const MaterialApp(home: JourneyScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Treatment Requests'));
    await tester.tap(find.text('Treatment Requests'));
    await tester.pumpAndSettle();
    expect(journey.request.status, RequestStatus.underReview);
    for (var i = 0; i < 3 && find.text('Reject').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(find.text('Reject'), findsOneWidget);
    await tester.ensureVisible(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(
      find.text('A reason is required for this decision.'),
      findsOneWidget,
    );
    final confirm = find.widgetWithText(ElevatedButton, 'Confirm');
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Clinical evidence requires further review',
    );
    await tester.pump();
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(journey.request.status, RequestStatus.rejected);
  });

  testWidgets('review detail requires a reason for a negative decision', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final data = DataProvider();
    final locale = LocaleProvider()..toggleLanguage();
    String? savedReason;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: ClinicalReviewDetailPanel(
              patient: data.getPatientById('P999')!,
              reviewType: 'care_plan',
              onApprove: null,
              onReject: (reason) => savedReason = reason,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(FilledButton, 'Confirm');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Missing supporting evidence',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(savedReason, 'Missing supporting evidence');
  });

  testWidgets('review queue information request updates the shared record', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    final access = AccessControlProvider(initialRole: AppRole.doctor);
    final data = DataProvider(access: access);
    final journey = JourneyProvider(dataProvider: data, access: access);
    final patient = data.getPatientById('P999')!;
    data.createTreatmentPlan(
      TreatmentPlan(
        id: 'TP-REVIEW-WIDGET',
        patientId: patient.id,
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
    journey.bindExistingPatient(patient);
    final requestId = journey.request.id;
    expect(journey.submit().success, isTrue);
    expect(journey.evaluate().success, isTrue);
    expect(
      journey.completeMissingLaboratoryInformation(
        crp: 3.2,
        esr: 12,
        collectedAt: DateTime.now(),
        source: 'Central laboratory',
        physicianReportReference: 'review.pdf',
      ).success,
      isTrue,
    );
    access.setRole(AppRole.medicalReviewer);
    expect(data.pendingClinicalReviews, isNotEmpty);
    final locale = LocaleProvider()..toggleLanguage();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: access),
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider.value(value: journey),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: WebDoctorShell(
            initialPatientId: 'P999',
            initialTabIndex: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Medical Reviewer Portal'), findsWidgets);
    await tester.ensureVisible(find.text('Request information'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request information'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(FilledButton, 'Confirm');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Updated laboratory report needed',
    );
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(
      data.treatmentRequestById(requestId)?.status,
      RequestStatus.needsInformation,
    );
    expect(data.pendingClinicalReviews, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
