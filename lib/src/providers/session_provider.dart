// مسیر پیشنهادی: lib/src/providers/session_provider.dart
// تغییر نسبت به نسخه‌ی قبلی: فقط دو فیلد اضافه شد (permissions, active) +
// یک متد کمکی hasPermission(). رفتار SharedPreferences (کلیدهای قبلی،
// ورود خودکار و ...) کاملاً دست‌نخورده ماند؛ فقط دو کلید جدید اضافه شده.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../data/premissions.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String shopId;
  final Map<String, bool> permissions;
  final bool active;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.shopId,
    Map<String, bool>? permissions,
    this.active = true,
  }) : permissions = permissions ??
      (role == 'OWNER' ? kDefaultOwnerPermissions : kDefaultStaffPermissions);

  bool get isOwner => role == 'OWNER';

  /// مدیر همیشه به همه‌چیز دسترسی دارد؛ کارمند فقط اگر پرچمش true باشد.
  bool hasPermission(String key) {
    if (isOwner) return true;
    return permissions[key] == true;
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'role': role,
    'shopId': shopId,
    'permissions': permissions,
    'active': active,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = map['role'] ?? 'STAFF';
    Map<String, bool> perms;
    final rawPerms = map['permissions'];
    if (rawPerms is Map) {
      perms = rawPerms.map((k, v) => MapEntry(k.toString(), v == true));
    } else {
      perms = role == 'OWNER' ? kDefaultOwnerPermissions : kDefaultStaffPermissions;
    }
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: role,
      shopId: map['shopId'] ?? '',
      permissions: perms,
      active: map['active'] == null ? true : map['active'] == true,
    );
  }
}

class SessionService {
  static final SessionService instance = SessionService._internal();
  SessionService._internal();

  UserModel? _currentUser;

  String get currentShopId => _currentUser?.shopId ?? '';
  UserModel? get user => _currentUser;

  void update(UserModel? user) {
    _currentUser = user;
  }
}

class SessionNotifier extends StateNotifier<UserModel?> {
  SessionNotifier() : super(null) {
    _loadSession();
  }

  Future<void> setUser(UserModel user) async {
    state = user;
    SessionService.instance.update(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toMap()));

    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    await prefs.setString('shop_id', user.shopId);
    // 🆕 فیلدهای جدید (فقط برای بازیابی سریع در استارتاپ - additive)
    await prefs.setString('user_permissions', jsonEncode(user.permissions));
    await prefs.setBool('user_active', user.active);
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final sessionData = prefs.getString('user_session');
    if (sessionData != null) {
      try {
        state = UserModel.fromMap(jsonDecode(sessionData));
        SessionService.instance.update(state);
        return;
      } catch (e) {
        print('خطا در decode session: $e');
      }
    }

    final userId = prefs.getString('user_id');
    if (userId != null && prefs.getBool('is_logged_in') == true) {
      Map<String, bool>? perms;
      final rawPerms = prefs.getString('user_permissions');
      if (rawPerms != null) {
        try {
          final decoded = jsonDecode(rawPerms) as Map;
          perms = decoded.map((k, v) => MapEntry(k.toString(), v == true));
        } catch (_) {}
      }
      state = UserModel(
        uid: userId,
        email: prefs.getString('user_email') ?? '',
        role: prefs.getString('user_role') ?? 'STAFF',
        shopId: prefs.getString('shop_id') ?? '',
        permissions: perms,
        active: prefs.getBool('user_active') ?? true,
      );
      SessionService.instance.update(state);
    }
  }
}

final currentUserProvider = StateNotifierProvider<SessionNotifier, UserModel?>((
    ref,
    ) {
  return SessionNotifier();
});