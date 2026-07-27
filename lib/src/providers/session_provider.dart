import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String shopId;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.shopId,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'role': role,
    'shopId': shopId,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'STAFF',
      shopId: map['shopId'] ?? '',
    );
  }
}

class SessionService {
  static final SessionService instance = SessionService._internal();
  SessionService._internal();

  UserModel? _currentUser;

  // متد برای دسترسی سریع به shopId که در خطاها دیده میشد
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

    // ذخیره جداگانه برای دسترسی سریع
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    await prefs.setString('shop_id', user.shopId);
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    // اول از JSON اصلی بخوان
    final sessionData = prefs.getString('user_session');
    if (sessionData != null) {
      try {
        state = UserModel.fromMap(jsonDecode(sessionData));
        return;
      } catch (e) {
        print('خطا در decode session: $e');
      }
    }

    // Fallback: از فیلدهای جداگانه بخوان
    final userId = prefs.getString('user_id');
    if (userId != null && prefs.getBool('is_logged_in') == true) {
      state = UserModel(
        uid: userId,
        email: prefs.getString('user_email') ?? '',
        role: prefs.getString('user_role') ?? 'STAFF',
        shopId: prefs.getString('shop_id') ?? '',
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
