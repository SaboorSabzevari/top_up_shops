import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State برای مدیریت وضعیت لاگین
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    required this.isLoggedIn,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

// Notifier برای مدیریت منطق لاگین
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(AuthState(user: null, isLoggedIn: false)) {
    // گوش دادن به تغییرات وضعیت کاربر
    _auth.authStateChanges().listen((user) {
      state = state.copyWith(
        user: user,
        isLoggedIn: user != null,
        error: null,
      );
    });
  }

  // لاگین با ایمیل و پسورد
  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // شروع loading
      state = state.copyWith(isLoading: true, error: null);

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // موفقیت - state در authStateChanges آپدیت می‌شود
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

  // خروج از سیستم
  Future<void> logout() async {
    await _auth.signOut();
    state = AuthState(user: null, isLoggedIn: false);
  }

  // بررسی آیا کاربر لاگین کرده
  bool get isAuthenticated => state.isLoggedIn;
}

// Provider اصلی
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(),
);

// Provider برای دسترسی آسان به user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

// Provider برای وضعیت لاگین
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});