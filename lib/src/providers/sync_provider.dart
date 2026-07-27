import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:top_up_shops/src/providers/session_provider.dart';
import 'dart:async';
import '../data/local/app_database.dart';
import '../services/sync_service.dart';

const kAutoSyncInterval = Duration(seconds: 45);

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
  Timer? _autoSyncTimer;

  SyncNotifier(this.ref)
    : _syncService = SyncService(),
      super(const SyncState()) {
    refreshPending(); // شمارش اولیه عملیات‌های منتظر
    _autoSyncTimer = Timer.periodic(kAutoSyncInterval, (_) => syncNow());
  }

  // متد برای بروزرسانی تعداد عملیات‌های باقی‌مانده در دیتابیس محلی
  Future<void> refreshPending() async {
    final db = await DatabaseHelper.instance.database;
    final user = ref.read(currentUserProvider);
    final rows = user == null
        ? await db.rawQuery("SELECT COUNT(*) as count FROM outbox")
        : await db.rawQuery(
            "SELECT COUNT(*) as count FROM outbox WHERE shop_id = ?",
            [user.shopId],
          );
    final count = (rows.first['count'] as int?) ?? 0;
    state = state.copyWith(pendingOps: count);
  }

  // متد اصلی برای شروع همگام‌سازی که در UI صدا می‌زنید
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final shopId =
          ref.read(currentUserProvider)?.shopId ??
          SessionService.instance.currentShopId;
      await _syncService.syncAll(shopId);
      await refreshPending();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, lastError: e.toString());
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
