import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/prefrence_services.dart';
import 'auth_provider.dart';
import 'session_provider.dart';
import '../data/local/app_database.dart';

class StartupState {
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const StartupState({
    this.isLoading = true,
    this.isInitialized = false,
    this.error,
  });

  StartupState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return StartupState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

class StartupNotifier extends StateNotifier<StartupState> {
  final Ref ref;

  StartupNotifier(this.ref) : super(const StartupState()) {
    // مقداردهی اولیه اپ
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // ۱. منتظر می‌شویم تا SharedPreferences بارگذاری شود
      await ref.read(preferencesServiceProvider.future);
      await DatabaseHelper.instance.database;

      // ۲. بارگذاری زبان ذخیره شده
      // (خودکار در localeProvider انجام می‌شود)

      // ۳. بارگذاری وضعیت لاگین
      final prefs = await ref.read(preferencesServiceProvider.future);
      if (prefs.isLoggedIn) {
        // اگر کاربر قبلاً لاگین کرده، auto-login
        await ref.read(authProvider.notifier).autoLogin();
      }

      await ref.read(sessionProvider.notifier).initialize();

      // تکمیل مقداردهی اولیه
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطا در راه‌اندازی اپ',
      );
    }
  }

  Future<void> retry() async {
    state = const StartupState(isLoading: true);
    await _initializeApp();
  }
}

final startupProvider = StateNotifierProvider<StartupNotifier, StartupState>(
      (ref) => StartupNotifier(ref),
);
