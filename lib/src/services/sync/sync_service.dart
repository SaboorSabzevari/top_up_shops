import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/local/app_database.dart';
import '../../data/remote/firestore_service.dart';
import '../session_service.dart';

class SyncEntity {
  final String name;
  final String table;
  final String remoteIdColumn;
  final bool isTopLevel;

  const SyncEntity({
    required this.name,
    required this.table,
    required this.remoteIdColumn,
    this.isTopLevel = false,
  });
}

class SyncService {
  SyncService({FirestoreService? firestoreService})
      : _fs = firestoreService ?? FirestoreService();

  final FirestoreService _fs;
  final DatabaseHelper _db = DatabaseHelper.instance;

  static const List<SyncEntity> _entities = [
    SyncEntity(name: 'customers', table: 'customers', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'providers', table: 'providers', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'units', table: 'units', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'transactions', table: 'transactions', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'paper_card_batches', table: 'paper_card_batches', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'suppliers', table: 'suppliers', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'assets', table: 'assets', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'salary_contracts', table: 'salary_contracts', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'salary_payments', table: 'salary_payments', remoteIdColumn: 'remote_id'),
    SyncEntity(name: 'employees', table: 'employees', remoteIdColumn: 'uid'),
    SyncEntity(name: 'roles', table: 'roles', remoteIdColumn: 'id'),
    SyncEntity(name: 'audit_logs', table: 'audit_logs', remoteIdColumn: 'remote_id'),
  ];

  bool _isSyncing = false;

  Future<void> syncAll() async {
    if (_isSyncing) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    _isSyncing = true;
    try {
      await pushOutbox();
      await pullShop();
      await pullUpdates();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> pushOutbox() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final ops = await db.query(
      'outbox',
      where: 'status = ? AND (next_attempt_at IS NULL OR next_attempt_at <= ?)',
      whereArgs: ['pending', now],
      orderBy: 'id ASC',
      limit: 50,
    );

    for (final op in ops) {
      final opId = op['op_id'] as String;
      final entity = op['entity'] as String;
      final entityId = op['entity_id'] as String;
      final opType = op['op_type'] as String;
      final baseVersion = (op['base_version'] as int?) ?? 0;
      final payload = jsonDecode(op['payload_json'] as String) as Map<String, dynamic>;
      final shopId = op['shop_id'] as String? ?? SessionService.instance.currentShopId;

      try {
        final docRef = entity == 'shops'
            ? _fs.shopDoc(entityId)
            : entity == 'users'
                ? _fs.userDoc(entityId)
                : _fs.shopSubDoc(shopId, entity, entityId);
        await _fs.db.runTransaction((txn) async {
          final snap = await txn.get(docRef);
          final remoteVersion = (snap.data()?['version'] as int?) ?? 0;
          if (opType != 'create' && snap.exists && remoteVersion != baseVersion) {
            await _recordConflict(entity, entityId, op['payload_json'] as String, snap.data());
            return;
          }
          final data = Map<String, dynamic>.from(payload);
          if (opType == 'delete') {
            data['is_deleted'] = 1;
          }
          txn.set(docRef, data, SetOptions(merge: opType != 'create'));
        });
        await db.update('outbox', {'status': 'done', 'last_error': null}, where: 'op_id = ?', whereArgs: [opId]);
      } catch (e) {
        final attempts = (op['attempts'] as int? ?? 0) + 1;
        final next = _nextAttempt(attempts);
        await db.update(
          'outbox',
          {
            'attempts': attempts,
            'status': attempts >= 8 ? 'failed' : 'pending',
            'next_attempt_at': next?.toIso8601String(),
            'last_error': e.toString(),
          },
          where: 'op_id = ?',
          whereArgs: [opId],
        );
      }
    }
  }

  Future<void> pullUpdates() async {
    final shopId = SessionService.instance.currentShopId;
    final db = await _db.database;
    for (final entity in _entities) {
      final last = await _getLastSync(entity.name);
      Query<Map<String, dynamic>> query = _fs.shopSubCollection(shopId, entity.name)
          .orderBy('updated_at_ms')
          .limit(200);
      if (last.lastUpdatedMs != null) {
        query = query.where('updated_at_ms', isGreaterThan: last.lastUpdatedMs);
      }
      final snaps = await query.get();
      if (snaps.docs.isEmpty) continue;

      int maxUpdatedMs = last.lastUpdatedMs ?? 0;
      for (final doc in snaps.docs) {
        final data = doc.data();
        final updatedMs = _resolveUpdatedMs(data);
        if (updatedMs > maxUpdatedMs) {
          maxUpdatedMs = updatedMs;
        }
        final hasPending = await _hasPendingOutbox(db, entity.name, doc.id);
        if (hasPending) {
          await _recordConflict(entity.name, doc.id, await _pendingPayload(db, entity.name, doc.id), data);
          continue;
        }
        await _applyRemoteDoc(db, entity, data, doc.id);
      }
      await _setLastSync(entity.name, maxUpdatedMs);
    }
  }

  Future<void> pullShop() async {
    final shopId = SessionService.instance.currentShopId;
    final db = await _db.database;
    final doc = await _fs.shopDoc(shopId).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    await _applyRemoteDoc(
      db,
      const SyncEntity(name: 'shops', table: 'shops', remoteIdColumn: 'id', isTopLevel: true),
      data,
      doc.id,
    );
  }

  Future<void> _applyRemoteDoc(Database db, SyncEntity entity, Map<String, dynamic> data, String docId) async {
    final tableColumns = await _getTableColumns(db, entity.table);
    final payload = Map<String, dynamic>.from(data);
    payload[entity.remoteIdColumn] = payload[entity.remoteIdColumn] ?? docId;
    if (entity.name == 'roles' && payload['permissions'] != null) {
      payload['permissions_json'] = jsonEncode(payload['permissions']);
    }
    if (entity.name == 'shops' && payload['subscription'] is Map<String, dynamic>) {
      final sub = payload['subscription'] as Map<String, dynamic>;
      payload['subscription_status'] = sub['status'];
      payload['subscription_plan'] = sub['planId'];
      if (sub['startDate'] is Timestamp) {
        final start = (sub['startDate'] as Timestamp).toDate();
        payload['subscription_start'] = start.toIso8601String();
        payload['subscription_start_ms'] = start.millisecondsSinceEpoch;
      } else if (sub['startDate'] is String) {
        payload['subscription_start'] = sub['startDate'];
      }
      if (sub['expiryDate'] is Timestamp) {
        final exp = (sub['expiryDate'] as Timestamp).toDate();
        payload['subscription_expiry'] = exp.toIso8601String();
        payload['subscription_expiry_ms'] = exp.millisecondsSinceEpoch;
      } else if (sub['expiryDate'] is String) {
        payload['subscription_expiry'] = sub['expiryDate'];
      }
    }
    final filtered = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (tableColumns.contains(entry.key)) {
        filtered[entry.key] = _normalizeValue(entry.value);
      }
    }
    if (filtered.isEmpty) return;

    if (entity.name == 'customers') {
      await _upsertByRemoteId(db, entity.table, entity.remoteIdColumn, filtered);
      await _replaceCustomerExtras(db, filtered, payload);
      return;
    }

    await _upsertByRemoteId(db, entity.table, entity.remoteIdColumn, filtered);
  }

  Future<void> _replaceCustomerExtras(Database db, Map<String, dynamic> customerRow, Map<String, dynamic> payload) async {
    final remoteId = customerRow['remote_id'] as String;
    final local = await db.query('customers', where: 'remote_id = ?', whereArgs: [remoteId], limit: 1);
    if (local.isEmpty) return;
    final customerId = local.first['id'] as int;
    final shopId = customerRow['shop_id'] as String? ?? SessionService.instance.currentShopId;
    await db.delete('customer_phones', where: 'customer_id = ?', whereArgs: [customerId]);
    await db.delete('customer_wholesale_codes', where: 'customer_id = ?', whereArgs: [customerId]);

    final phones = (payload['phones'] as List?)?.cast<dynamic>() ?? [];
    for (final phone in phones) {
      await db.insert('customer_phones', {
        'customer_id': customerId,
        'phone_number': phone.toString(),
        'remote_id': phone is Map && phone['remote_id'] != null ? phone['remote_id'] : null,
        'shop_id': shopId,
        'updated_at': customerRow['updated_at'],
        'version': 0,
        'last_op_id': customerRow['last_op_id'],
      });
    }

    final codes = (payload['wholesale_codes'] as List?)?.cast<dynamic>() ?? [];
    for (final item in codes) {
      if (item is Map<String, dynamic>) {
        await db.insert('customer_wholesale_codes', {
          'customer_id': customerId,
          'company_name': item['company'] ?? item['company_name'],
          'company_code': item['code'] ?? item['company_code'],
          'remote_id': item['remote_id'],
          'shop_id': shopId,
          'updated_at': customerRow['updated_at'],
          'version': 0,
          'last_op_id': customerRow['last_op_id'],
        });
      }
    }
  }

  Future<void> _upsertByRemoteId(Database db, String table, String remoteIdColumn, Map<String, dynamic> data) async {
    final remoteId = data[remoteIdColumn];
    if (remoteId == null) return;
    final existing = await db.query(table, where: '$remoteIdColumn = ?', whereArgs: [remoteId], limit: 1);
    if (existing.isEmpty) {
      await db.insert(table, data);
    } else {
      await db.update(table, data, where: '$remoteIdColumn = ?', whereArgs: [remoteId]);
    }
  }

  Future<List<String>> _getTableColumns(Database db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.map((row) => row['name'] as String).toList();
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    return value;
  }

  Future<bool> _hasPendingOutbox(Database db, String entity, String entityId) async {
    final rows = await db.query(
      'outbox',
      where: 'entity = ? AND entity_id = ? AND status = ?',
      whereArgs: [entity, entityId, 'pending'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String> _pendingPayload(Database db, String entity, String entityId) async {
    final rows = await db.query(
      'outbox',
      where: 'entity = ? AND entity_id = ? AND status = ?',
      whereArgs: [entity, entityId, 'pending'],
      limit: 1,
    );
    if (rows.isEmpty) return '{}';
    return rows.first['payload_json'] as String? ?? '{}';
  }

  Future<void> _recordConflict(String entity, String entityId, String localPayloadJson, Map<String, dynamic>? remote) async {
    final db = await _db.database;
    await db.insert('conflicts', {
      'entity': entity,
      'entity_id': entityId,
      'local_payload': localPayloadJson,
      'remote_payload': remote == null ? null : jsonEncode(remote, toEncodable: _encodeRemote),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  dynamic _encodeRemote(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    return value.toString();
  }

  DateTime? _nextAttempt(int attempts) {
    if (attempts <= 0) return null;
    const delays = [1, 2, 5, 15, 60, 300, 900, 1800];
    final idx = attempts - 1;
    final seconds = idx < delays.length ? delays[idx] : delays.last;
    return DateTime.now().add(Duration(seconds: seconds));
  }

  int _resolveUpdatedMs(Map<String, dynamic> data) {
    final ms = data['updated_at_ms'];
    if (ms is int) return ms;
    if (ms is num) return ms.toInt();
    final raw = data['updated_at'];
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      return parsed?.millisecondsSinceEpoch ?? 0;
    }
    if (raw is Timestamp) {
      return raw.toDate().millisecondsSinceEpoch;
    }
    return 0;
  }

  Future<_SyncCursor> _getLastSync(String entity) async {
    final db = await _db.database;
    final rows = await db.query('sync_state', where: 'entity = ?', whereArgs: [entity], limit: 1);
    if (rows.isEmpty) return const _SyncCursor(null);
    final raw = rows.first['last_pulled_at'] as String?;
    return _SyncCursor(raw != null ? int.tryParse(raw) : null);
  }

  Future<void> _setLastSync(String entity, int lastUpdatedMs) async {
    final db = await _db.database;
    await db.insert(
      'sync_state',
      {'entity': entity, 'last_pulled_at': lastUpdatedMs.toString(), 'last_doc_id': null},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class _SyncCursor {
  final int? lastUpdatedMs;
  const _SyncCursor(this.lastUpdatedMs);
}
