import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/remote/session_repository.dart';
import '../services/prefrence_services.dart';
import '../services/session_service.dart';

class SessionState {
  final SessionInfo session;
  final bool isLoading;
  final String? error;

  const SessionState({
    required this.session,
    this.isLoading = false,
    this.error,
  });

  SessionState copyWith({
    SessionInfo? session,
    bool? isLoading,
    String? error,
  }) {
    return SessionState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref ref;
  final SessionRepository _repo;

  SessionNotifier(this.ref)
      : _repo = SessionRepository(),
        super(SessionState(session: SessionService.instance.session));

  Future<void> initialize() async {
    await loadFromPrefs();
    await refreshFromRemoteIfOnline();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await ref.read(preferencesServiceProvider.future);
    final session = SessionInfo.fromMap({
      'shop_id': prefs.shopId,
      'employee_id': prefs.employeeId,
      'role_id': prefs.roleId,
      'shop_name': prefs.shopName,
      'subscription_active': prefs.subscriptionActive,
      'subscription_expiry': prefs.subscriptionExpiry?.toIso8601String(),
      'allow_view_on_expired': prefs.allowViewOnExpired,
      'permissions': prefs.permissionsJson,
    });
    SessionService.instance.update(session);
    state = state.copyWith(session: session, error: null);
  }

  Future<void> refreshFromRemoteIfOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    await refreshFromRemote();
  }

  Future<void> refreshFromRemote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await _repo.loadSession(user.uid);
      if (session == null) {
        state = state.copyWith(isLoading: false, error: 'حساب کاربر یافت نشد');
        return;
      }
      SessionService.instance.update(session);
      final prefs = await ref.read(preferencesServiceProvider.future);
      await prefs.saveSession(
        shopId: session.shopId,
        employeeId: session.employeeId,
        roleId: session.roleId,
        shopName: session.shopName,
        subscriptionActive: session.subscriptionActive,
        subscriptionExpiry: session.subscriptionExpiry,
        allowViewOnExpired: session.allowViewOnExpired,
        permissionsJson: jsonEncode(session.permissions),
      );
      state = state.copyWith(session: session, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'خطا در دریافت اطلاعات فروشگاه');
    }
  }

  Future<void> clear() async {
    final prefs = await ref.read(preferencesServiceProvider.future);
    await prefs.clearSession();
    SessionService.instance.update(const SessionInfo(
      shopId: 'local_shop',
      employeeId: 'local_owner',
      roleId: 'owner',
      shopName: 'فروشگاه من',
      subscriptionActive: true,
      subscriptionExpiry: null,
      allowViewOnExpired: true,
      permissions: {},
    ));
    state = state.copyWith(session: SessionService.instance.session, error: null);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});

