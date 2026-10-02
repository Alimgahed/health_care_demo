import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/features/journey/journey_provider.dart';
import 'package:mounjaro_demo/features/treatment_plan/web/patient_360_view.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/theme/theme_provider.dart';

void main() {
  Future<void> pumpWorkspace(
    WidgetTester tester,
    Size size, {
    int patientIndex = 0,
    int initialTabIndex = 0,
    Locale locale = const Locale('en'),
    AppRole role = AppRole.systemAdmin,
    String? patientId,
  }) async {
    await tester.binding.setSurfaceSize(size);
    final data = DataProvider();
    final access = AccessControlProvider(initialRole: role);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider(
            create: (_) => JourneyProvider(dataProvider: data, access: access),
          ),
          ChangeNotifierProvider.value(value: access),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Patient360View(
              patient: patientId == null
                  ? data.patients[patientIndex]
                  : data.patients.firstWhere((p) => p.id == patientId),
              initialTabIndex: initialTabIndex,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (var patientIndex = 0; patientIndex < 3; patientIndex++) {
    testWidgets('patient 360 renders patient $patientIndex on desktop', (
      tester,
    ) async {
      await pumpWorkspace(
        tester,
        const Size(1440, 1000),
        patientIndex: patientIndex,
      );
      expect(find.byType(Patient360View), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('patient 360 renders on mobile without overflow', (tester) async {
    await pumpWorkspace(tester, const Size(390, 844));
    expect(find.byType(Patient360View), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient 360 renders on tablet without overflow', (tester) async {
    await pumpWorkspace(tester, const Size(820, 1180));
    expect(find.byType(Patient360View), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient journey renders in Arabic RTL on tablet', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      const Size(820, 1180),
      initialTabIndex: 3,
      locale: const Locale('ar'),
    );
    expect(find.byType(Patient360View), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Patient360View))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('medications workspace renders on desktop', (tester) async {
    await pumpWorkspace(tester, const Size(1440, 1100), initialTabIndex: 4);
    expect(find.byType(Patient360View), findsOneWidget);
    expect(find.byType(Patient360View), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('integrated care plan renders connected sections on desktop', (
    tester,
  ) async {
    await pumpWorkspace(tester, const Size(1440, 1100), initialTabIndex: 2);
    expect(find.text('Integrated care plan'), findsWidgets);
    expect(find.text('Medication treatment plan'), findsOneWidget);
    expect(find.text('Rehabilitation plan'), findsOneWidget);
    expect(find.text('Home and self-care programme'), findsOneWidget);
    expect(find.text('Mounjaro'), findsWidgets);
    expect(find.text('Create Treatment Request'), findsOneWidget);
    expect(find.text('Modify'), findsOneWidget);
    expect(find.textContaining('Active Plan'), findsOneWidget);
    for (final progress in find.byType(CircularProgressIndicator).evaluate()) {
      expect(
        tester.getCenter(find.byWidget(progress.widget)).dx,
        lessThan(260),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('integrated care plan is responsive in Arabic on mobile', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      const Size(390, 844),
      initialTabIndex: 2,
      locale: const Locale('ar'),
    );
    expect(find.text('خطة الرعاية المتكاملة'), findsWidgets);
    expect(find.text('خطة العلاج الدوائي'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Patient360View))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('care plan shows an empty state when no exercises are assigned', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      const Size(1440, 1100),
      initialTabIndex: 2,
      patientId: 'P999',
    );
    expect(find.text('No home exercises'), findsOneWidget);
    expect(find.text('None assigned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient role cannot edit or create a treatment request', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      const Size(1440, 1100),
      initialTabIndex: 2,
      role: AppRole.patient,
    );
    expect(find.text('Modify'), findsNothing);
    expect(find.text('Create Treatment Request'), findsNothing);
    expect(find.text('Integrated care plan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medications workspace renders on mobile without overflow', (
    tester,
  ) async {
    await pumpWorkspace(tester, const Size(390, 844), initialTabIndex: 4);
    expect(find.byType(Patient360View), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laboratory workspace renders on desktop', (tester) async {
    await pumpWorkspace(tester, const Size(1440, 1100), initialTabIndex: 5);
    expect(find.byType(Patient360View), findsOneWidget);
    expect(find.text('HbA1c'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laboratory workspace renders on mobile without overflow', (
    tester,
  ) async {
    await pumpWorkspace(tester, const Size(390, 844), initialTabIndex: 5);
    expect(find.byType(Patient360View), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final tabIndex in [1, 6, 10]) {
    testWidgets('responsive patient workspace tab $tabIndex has no overflow', (
      tester,
    ) async {
      await pumpWorkspace(
        tester,
        const Size(390, 844),
        initialTabIndex: tabIndex,
      );
      expect(find.byType(Patient360View), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
