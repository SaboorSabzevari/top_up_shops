import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
// نوت: استفاده از legacy توصیه نمی‌شود، از نسخه جدید Riverpod استفاده کنید
import '../services/prefrence_services.dart';

@immutable
class LocaleState {
  final Locale locale;
  final bool isLoading;

  const LocaleState({required this.locale, this.isLoading = false});

  LocaleState copyWith({Locale? locale, bool? isLoading}) {
    return LocaleState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  final Ref ref;

  // استفاده از 'fa' به عنوان پیش‌فرض منطقی است، اما بهتر است isLoading در ابتدا true باشد
  LocaleNotifier(this.ref)
    : super(const LocaleState(locale: Locale('fa'), isLoading: true)) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      // استفاده از ref.read برای دریافت سرویس ترجیحات
      final prefs = await ref.read(preferencesServiceProvider.future);
      state = state.copyWith(locale: prefs.locale, isLoading: false);
    } catch (e) {
      state = state.copyWith(locale: const Locale('fa'), isLoading: false);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (state.locale.languageCode == languageCode)
      return; // جلوگیری از اجرای غیرضروری

    state = state.copyWith(isLoading: true);

    try {
      final prefs = await ref.read(preferencesServiceProvider.future);
      await prefs.saveLanguage(languageCode);

      state = state.copyWith(locale: Locale(languageCode), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // متد کمکی برای تشخیص جهت متن در UI
  bool get isRTL =>
      state.locale.languageCode == 'fa' || state.locale.languageCode == 'ps';
}

// تعریف پروایدر به صورت جدید
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((
  ref,
) {
  return LocaleNotifier(ref);
});
