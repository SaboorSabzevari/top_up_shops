import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:top_up_shops/src/presentation/screens/auth/login_screen.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart'; // مسیر را با پروژه خودت هماهنگ کن

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔹 زبان پیش‌فرض
      locale: const Locale('fa'),

      // 🔹 زبان‌های پشتیبانی‌شده
      supportedLocales: AppLocalizations.supportedLocales,

      // 🔹 delegate های کامل (مهم‌ترین اصلاح)
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      home: const LoginPage(),
    );
  }
}
