// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // راه‌اندازی Firebase با گزینه‌های مشخص
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyYOUR_API_KEY", // از google-services.json بگیرید
          appId: "1:YOUR_APP_ID:android:YOUR_PACKAGE_NAME",
          messagingSenderId: "YOUR_SENDER_ID",
          projectId: "YOUR_PROJECT_ID",
          storageBucket: "YOUR_STORAGE_BUCKET",
        ),
      );

      // تست اتصال
      await _testConnection();

    } catch (e) {
      debugPrint('خطا در راه‌اندازی Firebase: $e');
      // در صورت شکست، اپلیکیشن را با حالت آفلاین راه‌اندازی کن
    }
  }

  static Future<bool> _testConnection() async {
    try {
      // تست ساده برای بررسی اتصال
      await FirebaseFirestore.instance
          .collection('test')
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));
      return true;
    } on FirebaseException catch (e) {
      debugPrint('خطای Firebase در تست اتصال: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('خطای عمومی در تست اتصال: $e');
      return false;
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('خطا در دریافت کاربر جاری: $e');
      return null;
    }
  }
}