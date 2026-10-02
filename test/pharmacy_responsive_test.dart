import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/dispensing/web_pharmacy_dispensing_view.dart';
import 'package:mounjaro_demo/features/dispensing/patient_dispensing_details.dart';
import 'package:mounjaro_demo/features/dispensing/dispensing_screen.dart';

void main() {
  for (final width in [900.0, 390.0, 360.0, 320.0]) {
    for (final language in ['ar', 'en']) {
      testWidgets('pharmacy detail fits $language at ${width.toInt()} px', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        final data = DataProvider();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
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
              home: Scaffold(
                body: WebPharmacyDispensingView(
                  center: data.centers.first,
                  initialPatientId: 'P999',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            language == 'ar' ? 'تفاصيل الوصفة' : 'Prescription details',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            language == 'ar' ? 'المخزون والدفعات' : 'Inventory & Batches',
          ),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('pharmacy search no-results state offers recovery', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    final data = DataProvider();
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
          home: Scaffold(
            body: WebPharmacyDispensingView(center: data.centers.first),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no such patient');
    await tester.pumpAndSettle();
    expect(find.text('No matching requests'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('No matching requests'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

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
