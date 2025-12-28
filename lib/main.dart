import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:top_up_shops/src/presentation/screens/auth/start_up_screen.dart';
import 'package:top_up_shops/src/providers/local_provider.dart';
import 'package:top_up_shops/src/providers/start_up_provider.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'src/providers/auth_provider.dart';

import 'src/presentation/screens/auth/login_screen.dart';
import 'src/presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // وضعیت راه‌اندازی
    final startupState = ref.watch(startupProvider);

    // اگر هنوز در حال راه‌اندازی است
    if (startupState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const StartupScreen(),
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [
          Locale('fa', 'IR'),
          Locale('ps', 'AF'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
    }

    // زبان فعلی
    final localeState = ref.watch(localeProvider);
    final currentLocale = localeState.locale;

    // وضعیت لاگین
    final authState = ref.watch(authProvider);

    // صفحه اصلی بر اساس وضعیت لاگین
    final home = authState.isLoggedIn ? HomeScreen() : const LoginPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // تنظیم locale
      locale: currentLocale,

      // زبان‌های پشتیبانی شده
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('ps', 'AF'),
      ],

      // delegateها
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // اگر زبان پشتو است، از Cupertino انگلیسی استفاده کن
        if (currentLocale.languageCode == 'ps')
          DefaultCupertinoLocalizations.delegate
        else
          GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        // تعیین جهت نوشتار
        final isRTL = currentLocale.languageCode == 'fa' ||
            currentLocale.languageCode == 'ps';

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },

      home: home,
    );
  }
}