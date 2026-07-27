import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserId = 'user_id'; // جدید
  static const String _keyUserRole = 'user_role'; // جدید
  static const String _keyShopId = 'shop_id'; // جدید
  static const String _keySelectedLanguage = 'selected_language';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyRememberMe = 'remember_me';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // ==================== لاگین (اصلاح شده) ====================
  Future<void> saveLoginData({
    required String email,
    required String uid, // فیلد جدید
    required String role, // فیلد جدید
    required String shopId, // فیلد جدید
    required bool rememberMe,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserId, uid);
    await _prefs.setString(_keyUserRole, role);
    await _prefs.setString(_keyShopId, shopId);
    await _prefs.setBool(_keyRememberMe, rememberMe);
    await _prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
  }

  Future<void> clearLoginData() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserRole);
    await _prefs.remove(_keyShopId);
    await _prefs.remove(_keyLastLoginTime);
    await _prefs.remove(_keyRememberMe);
  }

  // گیترهای جدید برای بازیابی اطلاعات در استارتاپ
  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  String? get userEmail => _prefs.getString(_keyUserEmail);
  String? get userId => _prefs.getString(_keyUserId);
  String? get userRole => _prefs.getString(_keyUserRole);
  String? get shopId => _prefs.getString(_keyShopId);

  bool get rememberMe => _prefs.getBool(_keyRememberMe) ?? false;
  DateTime? get lastLoginTime {
    final value = _prefs.getString(_keyLastLoginTime);
    return value != null ? DateTime.parse(value) : null;
  }

  // ==================== سایر متدها ====================
  Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(_keySelectedLanguage, languageCode);
  }

  String get language => _prefs.getString(_keySelectedLanguage) ?? 'fa';

  Locale get locale => Locale(language);

  Future<void> clearAll() async => await _prefs.clear();
}

// Notifier اصلاح شده
class PreferencesNotifier extends AsyncNotifier<PreferencesService> {
  @override
  Future<PreferencesService> build() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // متد کمکی برای ذخیره کامل اطلاعات در هنگام لاگین
  Future<void> saveFullLogin({
    required String email,
    required String uid,
    required String role,
    required String shopId,
    required bool rememberMe,
  }) async {
    final service = await future;
    await service.saveLoginData(
      email: email,
      uid: uid,
      role: role,
      shopId: shopId,
      rememberMe: rememberMe,
    );
  }

  Future<void> clearLogin() async {
    final service = await future;
    await service.clearLoginData();
  }
}

final preferencesServiceProvider =
    AsyncNotifierProvider<PreferencesNotifier, PreferencesService>(
      PreferencesNotifier.new,
    );
