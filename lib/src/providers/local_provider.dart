import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/prefrence_services.dart';

class LocaleState {
  final Locale locale;
  final bool isLoading;

  const LocaleState({
    required this.locale,
    this.isLoading = false,
  });

  LocaleState copyWith({
    Locale? locale,
    bool? isLoading,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  final Ref ref;

  LocaleNotifier(this.ref)
      : super(const LocaleState(locale: Locale('fa'))) {
    // بارگذاری زبان ذخیره شده
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await ref.read(preferencesServiceProvider.future);
      state = state.copyWith(locale: prefs.locale);
    } catch (e) {
      // در صورت خطا، زبان پیش‌فرض فارسی
      state = state.copyWith(locale: const Locale('fa'));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    state = state.copyWith(isLoading: true);

    try {
      // ذخیره زبان جدید
      final prefs = await ref.read(preferencesServiceProvider.future);
      await prefs.saveLanguage(languageCode);

      state = state.copyWith(
        locale: Locale(languageCode),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        locale: const Locale('fa'),
      );
    }
  }

  String get currentLanguage => state.locale.languageCode;
}

// Provider اصلی
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier(ref);
});