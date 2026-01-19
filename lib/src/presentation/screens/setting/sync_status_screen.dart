import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/sync_provider.dart';
import '../../../data/local/app_database.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  List<Map<String, dynamic>> _conflicts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('conflicts', orderBy: 'created_at DESC');
    if (!mounted) return;
    setState(() {
      _conflicts = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F6F6);
    final syncState = ref.watch(syncProvider);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('وضعیت همگام‌سازی', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncProvider.notifier).refreshPending();
          await _loadConflicts();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusCard(syncState),
            const SizedBox(height: 12),
            const Text('تعارض‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_conflicts.isEmpty)
              const Text('تعارضی وجود ندارد', style: TextStyle(color: Colors.grey))
            else
              ..._conflicts.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text('${c['entity']} / ${c['entity_id']}'),
                    subtitle: Text(c['created_at']?.toString() ?? ''),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(syncProvider.notifier).syncNow();
          await _loadConflicts();
        },
        child: syncState.isSyncing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.sync),
      ),
    );
  }

  Widget _statusCard(SyncState syncState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('وضعیت فعلی', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('عملیات در انتظار: ${syncState.pendingOps}'),
          if (syncState.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('خطا: ${syncState.lastError}', style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

