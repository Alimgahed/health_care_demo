import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/dispensing/patient_dispensing_details.dart';
import 'package:mounjaro_demo/features/dispensing/dispensing_screen.dart';

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets(
      'mobile dispensing review uses recorded eligibility and coverage in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        final access = AccessControlProvider(initialRole: AppRole.pharmacist);
        final data = DataProvider(access: access);
        final patient = data.getPatientById('P999')!;
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: access),
              ChangeNotifierProvider.value(value: data),
              ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ],
            child: MaterialApp(
              locale: Locale(language),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: PatientDispensingDetails(patient: patient),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('85%'), findsNothing);
        expect(
          find.text(
            language == 'ar'
                ? 'معايير البرنامج مستوفاة'
                : 'Program criteria met',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('mobile pharmacy shows canonical queue without simulated scan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    final access = AccessControlProvider(initialRole: AppRole.pharmacist);
    final data = DataProvider(access: access);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: access),
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DispensingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Ready for review and handover'),
      findsOneWidget,
    );
    expect(find.textContaining('RXQ-TP-P999'), findsOneWidget);
    expect(find.text('Scan QR'), findsNothing);
    await tester.enterText(find.byType(TextField), 'no such patient');
    await tester.pumpAndSettle();
    expect(find.textContaining('No matching requests'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.textContaining('RXQ-TP-P999'), findsOneWidget);
  });
}
