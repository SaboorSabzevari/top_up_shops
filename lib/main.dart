import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // اضافه کردن این import
import 'package:top_up_shops/src/presentation/screens/auth/start_up_screen.dart';
import 'package:top_up_shops/src/providers/local_provider.dart';
import 'package:top_up_shops/src/providers/start_up_provider.dart';
import 'package:top_up_shops/src/services/app_navigation.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'src/providers/auth_provider.dart';

import 'src/presentation/screens/auth/login_screen.dart';
import 'src/presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);

    if (startupState.isLoading) {
      return ScreenUtilInit(
        designSize: const Size(360, 690), // اندازه طراحی را اینجا تنظیم کنید
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            home: const StartupScreen(),
            locale: const Locale('fa', 'IR'),
            supportedLocales: const [Locale('fa', 'IR'), Locale('ps', 'AF')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      );
    }

    final localeState = ref.watch(localeProvider);
    final currentLocale = localeState.locale;

    final authState = ref.watch(authProvider);
    final home = authState.isLoggedIn ? HomeScreen() : const LoginPage();

    return ScreenUtilInit(
      designSize: const Size(360, 690), // اندازه طراحی را اینجا تنظیم کنید
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          supportedLocales: const [Locale('fa', 'IR'), Locale('ps', 'AF')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            if (currentLocale.languageCode == 'ps')
              DefaultCupertinoLocalizations.delegate
            else
              GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final isRTL =
                currentLocale.languageCode == 'fa' ||
                    currentLocale.languageCode == 'ps';

            return Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
          home: home,
        );
      },
    );
  }
}