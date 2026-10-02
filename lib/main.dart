import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/mock_data.dart';
import 'core/auth/access_control.dart';
import 'core/demo/demo_session_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/splash_screen.dart';
import 'features/journey/journey_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AccessControlProvider()),
        ChangeNotifierProvider(create: (context) => DemoSessionProvider()),
        ChangeNotifierProvider(
          create: (context) => DataProvider(
            access: context.read<AccessControlProvider>(),
            session: context.read<DemoSessionProvider>(),
          ),
        ),
        ChangeNotifierProxyProvider2<
          DataProvider,
          AccessControlProvider,
          JourneyProvider
        >(
          create: (context) => JourneyProvider(
            dataProvider: context.read<DataProvider>(),
            access: context.read<AccessControlProvider>(),
          ),
          update: (_, data, access, journey) =>
              (journey ?? JourneyProvider())..attach(data, access),
        ),
      ],
      child: const MounjaroApp(),
    ),
  );
}

class MounjaroApp extends StatelessWidget {
  const MounjaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        final locale = localeProvider.locale;
        return MaterialApp(
          title: 'Health System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
