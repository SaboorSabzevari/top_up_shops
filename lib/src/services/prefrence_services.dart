import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keySelectedLanguage = 'selected_language';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyShopId = 'shop_id';
  static const String _keyEmployeeId = 'employee_id';
  static const String _keyRoleId = 'role_id';
  static const String _keyShopName = 'shop_name';
  static const String _keySubscriptionActive = 'subscription_active';
  static const String _keySubscriptionExpiry = 'subscription_expiry';
  static const String _keyAllowViewOnExpired = 'allow_view_on_expired';
  static const String _keyPermissions = 'permissions';

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

  // ==================== Session ====================
  Future<void> saveSession({
    required String shopId,
    required String employeeId,
    required String roleId,
    required String shopName,
    required bool subscriptionActive,
    required DateTime? subscriptionExpiry,
    required bool allowViewOnExpired,
    required String permissionsJson,
  }) async {
    await _prefs.setString(_keyShopId, shopId);
    await _prefs.setString(_keyEmployeeId, employeeId);
    await _prefs.setString(_keyRoleId, roleId);
    await _prefs.setString(_keyShopName, shopName);
    await _prefs.setBool(_keySubscriptionActive, subscriptionActive);
    if (subscriptionExpiry != null) {
      await _prefs.setString(_keySubscriptionExpiry, subscriptionExpiry.toIso8601String());
    } else {
      await _prefs.remove(_keySubscriptionExpiry);
    }
    await _prefs.setBool(_keyAllowViewOnExpired, allowViewOnExpired);
    await _prefs.setString(_keyPermissions, permissionsJson);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyShopId);
    await _prefs.remove(_keyEmployeeId);
    await _prefs.remove(_keyRoleId);
    await _prefs.remove(_keyShopName);
    await _prefs.remove(_keySubscriptionActive);
    await _prefs.remove(_keySubscriptionExpiry);
    await _prefs.remove(_keyAllowViewOnExpired);
    await _prefs.remove(_keyPermissions);
  }

  String? get shopId => _prefs.getString(_keyShopId);
  String? get employeeId => _prefs.getString(_keyEmployeeId);
  String? get roleId => _prefs.getString(_keyRoleId);
  String? get shopName => _prefs.getString(_keyShopName);
  bool get subscriptionActive => _prefs.getBool(_keySubscriptionActive) ?? true;
  DateTime? get subscriptionExpiry {
    final raw = _prefs.getString(_keySubscriptionExpiry);
    return raw != null ? DateTime.tryParse(raw) : null;
  }
  bool get allowViewOnExpired => _prefs.getBool(_keyAllowViewOnExpired) ?? true;
  String get permissionsJson => _prefs.getString(_keyPermissions) ?? '{}';

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

  Future<void> saveSession({
    required String shopId,
    required String employeeId,
    required String roleId,
    required String shopName,
    required bool subscriptionActive,
    required DateTime? subscriptionExpiry,
    required bool allowViewOnExpired,
    required String permissionsJson,
  }) async {
    final service = await future;
    await service.saveSession(
      shopId: shopId,
      employeeId: employeeId,
      roleId: roleId,
      shopName: shopName,
      subscriptionActive: subscriptionActive,
      subscriptionExpiry: subscriptionExpiry,
      allowViewOnExpired: allowViewOnExpired,
      permissionsJson: permissionsJson,
    );
  }

  Future<void> clearSession() async {
    final service = await future;
    await service.clearSession();
  }
}

final preferencesServiceProvider = AsyncNotifierProvider<PreferencesNotifier, PreferencesService>(
  PreferencesNotifier.new,
);
