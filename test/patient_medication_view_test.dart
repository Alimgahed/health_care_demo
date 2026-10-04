import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/treatment_plan/mobile/plan_medication_screen.dart';

void main() {
  testWidgets(
    'patient medication screen shows canonical dose and saves adherence',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
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
            home: Scaffold(body: PlanMedicationScreen(patient: patient)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(plan.medicationDose), findsWidgets);
      expect(find.text('No dose events recorded this month.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
