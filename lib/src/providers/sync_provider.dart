import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';

import '../data/local/app_database.dart';
import '../services/sync/sync_service.dart';

class SyncState {
  final bool isSyncing;
  final int pendingOps;
  final String? lastError;

  const SyncState({
    this.isSyncing = false,
    this.pendingOps = 0,
    this.lastError,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingOps,
    String? lastError,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingOps: pendingOps ?? this.pendingOps,
      lastError: lastError,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  Timer? _timer;

  SyncNotifier()
      : _syncService = SyncService(),
        super(const SyncState()) {
    refreshPending();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
  }

  Future<void> refreshPending() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery("SELECT COUNT(*) as count FROM outbox WHERE status = 'pending'");
    final count = (rows.first['count'] as int?) ?? 0;
    state = state.copyWith(pendingOps: count);
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true, lastError: null);
    try {
      await _syncService.syncAll();
      await refreshPending();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, lastError: e.toString());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
