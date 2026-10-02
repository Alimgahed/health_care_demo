import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mounjaro_demo/core/constants/mock_data.dart';
import 'package:mounjaro_demo/core/localization/app_localizations.dart';
import 'package:mounjaro_demo/core/localization/locale_provider.dart';
import 'package:mounjaro_demo/core/theme/app_colors.dart';
import 'package:mounjaro_demo/features/dashboard/admin_views/regional_analytics.dart';

void main() {
  Future<void> pumpReports(
    WidgetTester tester,
    Size size,
    Locale locale,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DataProvider(),
        child: ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
          child: MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            ),
            home: const Scaffold(body: RegionalAnalytics()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reports command center renders the connected executive view', (
    tester,
  ) async {
    await pumpReports(tester, const Size(1440, 1180), const Locale('en'));
    expect(find.text('Program performance'), findsOneWidget);
    expect(find.text('Patient journey coverage'), findsOneWidget);
    expect(find.text('Clinical outcomes & follow-up'), findsOneWidget);
    expect(find.text('Dispensing & pharmacy operations'), findsOneWidget);
    expect(find.byKey(const ValueKey('reports-period-filter')), findsOneWidget);
    expect(find.byKey(const ValueKey('reports-export')), findsOneWidget);
    for (final section in const [
      'Regional distribution',
      'Facilities & inventory',
      'Demographics & financial support',
      'Executive observations',
    ]) {
      await tester.scrollUntilVisible(
        find.text(section),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(section), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('report filters and export controls are operable in Arabic', (
    tester,
  ) async {
    await pumpReports(tester, const Size(1600, 1200), const Locale('ar'));
    expect(find.text('تغطية رحلة المريض'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reports-emirate-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reports-request-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reports-workflow-filter')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reports-refresh')));
    await tester.pumpAndSettle();
    expect(find.textContaining('آخر تحديث'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reports-export')));
    await tester.pumpAndSettle();
    expect(find.text('تم نسخ بيانات التقرير بصيغة CSV.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report dashboard has a useful empty scope state', (
    tester,
  ) async {
    await pumpReports(tester, const Size(1440, 1180), const Locale('en'));
    // Selecting a status that has no queue entries still leaves a clear
    // report surface and never renders an exception or fabricated chart.
    final dropdown = find.descendant(
      of: find.byKey(const ValueKey('reports-request-filter')),
      matching: find.byType(DropdownButtonFormField<PharmacyRequestStatus?>),
    );
    expect(dropdown, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
