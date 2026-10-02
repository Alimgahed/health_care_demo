import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/demo/demo_session_provider.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/patient_app/patient_app_screen.dart';

void main() {
  testWidgets('patient home records dose in shared history once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final data = DataProvider();
    final session = DemoSessionProvider();
    final plan = data.getPlanForPatient(session.patientId)!;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: PatientAppScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(
      find.text('Prescribed dose: ${plan.medicationDose}'),
      findsOneWidget,
    );
    expect(find.textContaining('Next dose in your plan:'), findsOneWidget);
    expect(data.medicationEventsFor(session.patientId), isEmpty);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Record dose taken'));
    await tester.pumpAndSettle();

    expect(data.medicationEventsFor(session.patientId), hasLength(1));
    expect(
      data.medicationEventsFor(session.patientId).single.status,
      MedicationDoseStatus.taken,
    );
    expect(find.text('Current dose recorded'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Dose recorded'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient home fits Arabic at a narrow mobile width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
          ChangeNotifierProvider(create: (_) => DemoSessionProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: PatientAppScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('وثّق جرعتك الحالية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
