import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/treatment_plan/web/web_plan_medication_view.dart';

void main() {
  testWidgets(
    'patient medication screen shows canonical dose and saves adherence',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      final data = DataProvider();
      final patient = data.getPatientById('P999')!;
      final plan = data.getPlanForPatient(patient.id)!;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: data),
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
            home: Scaffold(body: WebPlanMedicationView(patient: patient)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mounjaro · ${plan.medicationDose}'), findsOneWidget);
      expect(find.text('No dose events'), findsOneWidget);
      expect(find.text('4/4'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Taken'));
      await tester.pumpAndSettle();

      expect(data.medicationEventsFor(patient.id), hasLength(1));
      expect(
        data.medicationEventsFor(patient.id).single.status,
        MedicationDoseStatus.taken,
      );
      expect(find.text('100%'), findsOneWidget);
    },
  );
}
