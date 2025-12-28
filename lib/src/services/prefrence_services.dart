import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keySelectedLanguage = 'selected_language';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyRememberMe = 'remember_me';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // ==================== لاگین ====================
  Future<void> saveLoginData({
    required String email,
    required bool rememberMe,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setBool(_keyRememberMe, rememberMe);
    await _prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
  }

  Future<void> clearLoginData() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyLastLoginTime);
    await _prefs.remove(_keyRememberMe);
  }

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  String? get userEmail => _prefs.getString(_keyUserEmail);
  bool get rememberMe => _prefs.getBool(_keyRememberMe) ?? false;
  DateTime? get lastLoginTime {
    final value = _prefs.getString(_keyLastLoginTime);
    return value != null ? DateTime.parse(value) : null;
  }

  // ==================== زبان ====================
  Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(_keySelectedLanguage, languageCode);
  }

  String get language {
    return _prefs.getString(_keySelectedLanguage) ?? 'fa';
  }

  Locale get locale {
    final lang = language;
    return Locale(lang);
  }

  // ==================== سایر ====================
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

// AsyncNotifierProvider برای PreferencesService
class PreferencesNotifier extends AsyncNotifier<PreferencesService> {
  @override
  Future<PreferencesService> build() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // متدهای کمکی برای دسترسی آسان
  Future<void> saveLogin({
    required String email,
    required bool rememberMe,
  }) async {
    final service = await future;
    await service.saveLoginData(email: email, rememberMe: rememberMe);
  }

  Future<void> clearLogin() async {
    final service = await future;
    await service.clearLoginData();
  }

  Future<void> changeLanguage(String languageCode) async {
    final service = await future;
    await service.saveLanguage(languageCode);
  }
}

final preferencesServiceProvider = AsyncNotifierProvider<PreferencesNotifier, PreferencesService>(
  PreferencesNotifier.new,
);