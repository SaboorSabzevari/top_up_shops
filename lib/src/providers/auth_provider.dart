import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/prefrence_services.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(user: null, isLoggedIn: false)) {
    // بارگذاری داده‌های ذخیره شده
    _loadSavedData();

    // گوش دادن به تغییرات وضعیت کاربر
    _auth.authStateChanges().listen((user) {
      state = state.copyWith(
        user: user,
        isLoggedIn: user != null,
        error: null,
      );
    });
  }

  Future<void> _loadSavedData() async {
    // منتظر می‌شویم تا PreferencesService آماده شود
    final prefsAsync = await ref.read(preferencesServiceProvider.future);

    // بارگذاری ایمیل ذخیره شده
    final savedEmail = prefsAsync.userEmail;
    final rememberMe = prefsAsync.rememberMe;

    if (savedEmail != null) {
      state = state.copyWith(
        savedEmail: savedEmail,
        rememberMe: rememberMe,
      );
    }
  }

  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // ذخیره اطلاعات لاگین
      final prefs = await ref.read(preferencesServiceProvider.future);
      await prefs.saveLoginData(
        email: email.trim(),
        rememberMe: rememberMe,
      );

      // آپدیت state
      state = state.copyWith(
        savedEmail: rememberMe ? email.trim() : null,
        rememberMe: rememberMe,
        isLoading: false,
      );

    } on FirebaseAuthException catch (e) {
      final errorMessage = _getErrorMessage(e.code);
      state = state.copyWith(error: errorMessage, isLoading: false);
      throw Exception(errorMessage);
    } catch (e) {
      state = state.copyWith(
        error: 'خطای نامشخصی رخ داد',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> autoLogin() async {
    final prefsAsync = await ref.read(preferencesServiceProvider.future);

    if (prefsAsync.isLoggedIn && state.savedEmail != null) {
      try {
        state = state.copyWith(isLoading: true);
        // در اینجا می‌توانید منطق auto-login را اضافه کنید
        await Future.delayed(const Duration(seconds: 1));
        state = state.copyWith(isLoading: false);
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'اتوماتیک لاگین ناموفق بود',
        );
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();

    // حذف اطلاعات لاگین از SharedPreferences
    final prefs = await ref.read(preferencesServiceProvider.future);
    await prefs.clearLoginData();

    state = AuthState(
      user: null,
      isLoggedIn: false,
      rememberMe: false,
    );
  }

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'شما هنوز راجستر نشده‌اید';
      case 'wrong-password':
        return 'رمز عبور اشتباه است';
      case 'invalid-email':
        return 'فرمت ایمیل نادرست است';
      case 'user-disabled':
        return 'این حساب غیرفعال شده است';
      case 'too-many-requests':
        return 'تعداد تلاش زیاد است، بعداً امتحان کنید';
      case 'network-request-failed':
        return 'اتصال اینترنت برقرار نیست';
      default:
        return 'خطای نامشخصی رخ داد';
    }
  }
}

// Provider اصلی Auth
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});