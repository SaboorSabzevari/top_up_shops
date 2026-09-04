// مسیر پیشنهادی: lib/src/providers/sync_provider.dart
// چون دیگر outbox محلی نداریم، pendingOps همیشه صفر است. این Provider
// را فقط برای این نگه داشتیم که اگر جایی در UI به آن ارجاع داده شده،
// خطا نگیرید.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:top_up_shops/src/providers/session_provider.dart';
import 'dart:async';
import '../services/sync_service.dart';

class SyncState {
  final bool isSyncing;
  final int pendingOps;
  final String? lastError;

  const SyncState({
    this.isSyncing = false,
    this.pendingOps = 0,
    this.lastError,
  });

  SyncState copyWith({bool? isSyncing, int? pendingOps, String? lastError}) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingOps: pendingOps ?? this.pendingOps,
      lastError: lastError,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final Ref ref;

  SyncNotifier(this.ref) : _syncService = SyncService(), super(const SyncState());

  Future<void> refreshPending() async {
    state = state.copyWith(pendingOps: 0);
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, lastError: null);
    try {
      final shopId = ref.read(currentUserProvider)?.shopId ?? '';
      await _syncService.syncAll(shopId);
      state = state.copyWith(isSyncing: false, pendingOps: 0);
    } catch (e) {
      state = state.copyWith(isSyncing: false, lastError: e.toString());
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});