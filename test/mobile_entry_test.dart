import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mounjaro_demo/core/auth/access_control.dart';
import 'package:mounjaro_demo/core/demo/demo_session_provider.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/features/auth/premium_login_screen.dart';

void main() {
  Future<void> pumpMobileLogin(
    WidgetTester tester, {
    required Size size,
    required Locale locale,
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AccessControlProvider()),
          ChangeNotifierProvider(create: (_) => DemoSessionProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
          home: const PremiumLoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile entry shows four branded demo portals in English', (
    tester,
  ) async {
    await pumpMobileLogin(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
    );

    expect(find.text('healthcare'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Pharmacy'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Medical Reviewer'), findsNothing);
    expect(
      find.text('Demo preview • No real sign-in or live sync'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile entry remains scrollable and overflow-free in Arabic', (
    tester,
  ) async {
    await pumpMobileLogin(
      tester,
      size: const Size(320, 700),
      locale: const Locale('ar'),
    );

    expect(find.text('healthcare'), findsOneWidget);
    expect(find.text('النظام'), findsOneWidget);
    expect(find.text('الطبيب'), findsOneWidget);
    expect(find.text('منشأة الصرف'), findsOneWidget);
    expect(find.text('المريض'), findsOneWidget);
    expect(find.text('المراجع الطبي'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
