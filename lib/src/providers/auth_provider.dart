import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/prefrence_services.dart';
import 'session_provider.dart';

// ۱. تعریف وضعیت احراز هویت
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;
  final bool rememberMe;
  final String? savedEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    required this.isLoggedIn,
    this.rememberMe = false,
    this.savedEmail,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
    bool? rememberMe,
    String? savedEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      rememberMe: rememberMe ?? this.rememberMe,
      savedEmail: savedEmail ?? this.savedEmail,
    );
  }
}

// ۲. مدیریت منطق احراز هویت
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState(isLoggedIn: false)) {
    _init();
  }
  // داخل کلاس AuthNotifier
  Future<void> autoLogin() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // فراخوانی متد همگام‌سازی که قبلاً با هم نوشتیم
      // این متد shopId و role را از Firestore می‌گیرد
      await _syncUserProfile(currentUser);
    }
  }

  Future<void> _init() async {
    await _loadSavedData();

    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final userModel = await _syncUserProfile(user);

        if (userModel != null) {
          await ref.read(currentUserProvider.notifier).setUser(userModel);
        }

        state = state.copyWith(user: user, isLoggedIn: true, isLoading: false);
      } else {
        ref.read(currentUserProvider.notifier).state = null;
        state = state.copyWith(user: null, isLoggedIn: false, isLoading: false);
      }
    });
  }

  // بارگذاری داده‌ها از SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await ref.read(preferencesServiceProvider.future);
      state = state.copyWith(
        savedEmail: prefs.userEmail,
        rememberMe: prefs.rememberMe,
      );
    } catch (_) {}
  }

  // همگام‌سازی پروفایل کاربر با Firestore (بسیار حیاتی برای Multi-shop)
  // قبل از تغییر: Future<void> _syncUserProfile
  // بعد از تغییر:
  Future<UserModel?> _syncUserProfile(User firebaseUser) async {
    print('🎯 ===== START SYNC USER PROFILE =====');
    print('👤 UID: ${firebaseUser.uid}');
    print('📧 Email: ${firebaseUser.email}');

    try {
      // 1. تست اتصال به Firestore
      print('🔌 تست اتصال به Firestore...');
      final firestore = FirebaseFirestore.instance;

      // 2. بررسی دقیق‌تر مسیر
      print('📍 مسیر مورد جستجو: users/${firebaseUser.uid}');

      // 3. خواندن با source: server (نه cache)
      final doc = await firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      print('📊 وضعیت داکیومنت:');
      print('   - Exists: ${doc.exists}');
      print('   - Has data: ${doc.data() != null}');

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

          print('📋 تعداد فیلدهای پروفایل: ${data.keys.length}');


        // بررسی فیلدهای ضروری
        final hasRole = data.containsKey('role');
        final hasShopId = data.containsKey('shopId');
        final role = data['role']?.toString();
        final shopId = data['shopId']?.toString();


          print('🔍 بررسی فیلدهای حیاتی: role=$hasRole, shopId=$hasShopId');


        if (!hasRole || !hasShopId) {
          print('❌ فیلدهای role یا shopId موجود نیستند!');
          return null;
        }

        if (role == null || role.isEmpty || shopId == null || shopId.isEmpty) {
          print('❌ فیلدهای role یا shopId خالی هستند!');
          return null;
        }

        print('✅ کاربر با موفقیت سینک شد');
        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          role: role,
          shopId: shopId,
        );
      } else {
        print('❌ داکیومنت وجود ندارد یا دیتا ندارد');

        // 4. جستجو در کل کالکشن users
        print('🔎 جستجو در تمام users...');
        final allUsers = await firestore
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email)
            .limit(5)
            .get();

        print('🔎 تعداد کاربران با این ایمیل: ${allUsers.docs.length}');

          for (var doc in allUsers.docs) {
            print('   - ID: ${doc.id}');

        }
      }

      return null;
    } catch (e, stackTrace) {
      print('💥 خطای شدید در syncUserProfile:');
      print('   - Error: $e');
      print('   - StackTrace: $stackTrace');
      return null;
    } finally {
      print('🏁 ===== END SYNC USER PROFILE =====');
    }
  }

  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userModel = await _syncUserProfile(firebaseUser);

        if (userModel != null) {
          // 🔴 اینجا حتماً باید await کنیم
          await ref.read(currentUserProvider.notifier).setUser(userModel);

          // 🔴 تأیید سریع که کاربر ذخیره شده
          print('کاربر ذخیره شد: ${userModel.uid}, Shop: ${userModel.shopId}');

          // 🔴 همین الان وضعیت auth را هم آپدیت کنیم
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: true,
            user: firebaseUser,
            error: null,
          );

          // ذخیره در preferences
          final prefsNotifier = ref.read(preferencesServiceProvider.notifier);
          await prefsNotifier.saveFullLogin(
            email: userModel.email,
            uid: userModel.uid,
            role: userModel.role,
            shopId: userModel.shopId,
            rememberMe: rememberMe,
          );

          // 🔴 تاخیر برای اطمینان از آپدیت state
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          throw Exception("پروفایل کاربری یافت نشد.");
        }
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _getErrorMessage(e.code), isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // خروج از حساب
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await ref.read(preferencesServiceProvider.future);
    await prefs.clearLoginData();
  }

  // تبدیل کدهای خطا به متن فارسی (فیکس ارور قبلی)
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'کاربر یافت نشد';
      case 'wrong-password':
        return 'رمز عبور اشتباه است';
      case 'invalid-email':
        return 'ایمیل نامعتبر است';
      case 'user-disabled':
        return 'حساب کاربری مسدود شده است';
      default:
        return 'خطا در ورود به حساب کاربری ($code)';
    }
  }
  // داخل کلاس AuthNotifier در فایل auth_provider.dart

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }
}

// ۳. تعریف پروایدر نهایی
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
