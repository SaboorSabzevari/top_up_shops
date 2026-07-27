import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import '../data/local/app_database.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> _collections = [
    'providers',
    'units',
    'provider_balances',
    'customers',
    'purchases',
    'paper_stock',
    'transactions',
  ];

  Future<void> syncAll(String shopId) async {
    if (shopId.isEmpty) {
      throw Exception(
        'shopId خالی است؛ ابتدا نشست کاربر باید درست بارگذاری شود.',
      );
    }

    final db = await DatabaseHelper.instance.database;
    await _pushOutbox(db, shopId);
    await _pullIncremental(db, shopId);
  }

  Future<void> _pushOutbox(Database db, String shopId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'outbox',
      where:
          'shop_id = ? AND status IN (?, ?) AND (next_attempt_at_ms IS NULL OR next_attempt_at_ms <= ?)',
      whereArgs: [shopId, 'pending', 'failed', now],
      orderBy: 'created_at_ms ASC',
      limit: 100,
    );

    for (final row in rows) {
      final opId = row['op_id'] as String;
      final entity = row['entity'] as String;
      final entityId = row['entity_id'] as String;
      final opType = row['op_type'] as String;
      final attempts = ((row['attempts'] as num?)?.toInt() ?? 0) + 1;

      await db.update(
        'outbox',
        {'status': 'syncing', 'attempts': attempts},
        where: 'op_id = ?',
        whereArgs: [opId],
      );

      try {
        final payload =
            jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
        final docRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection(entity)
            .doc(entityId);

        final cleanPayload = _cleanForFirestore(payload);
        cleanPayload.remove('created_at_server');
        cleanPayload.remove('updated_at_server');
        cleanPayload['remote_id'] = entityId;
        cleanPayload['shop_id'] = shopId;
        cleanPayload['updated_at_server'] = FieldValue.serverTimestamp();
        cleanPayload['version'] = FieldValue.increment(1);
        cleanPayload['last_op_id'] = opId;

        if (opType == 'increment') {
          await _applyIncrementOperation(
            docRef: docRef,
            opId: opId,
            payload: cleanPayload,
            deltaBalance: (payload['_delta_balance'] as num?)?.toDouble(),
            deltaQuantity: (payload['_delta_quantity'] as num?)?.toInt(),
          );
        } else if (opType == 'delete') {
          cleanPayload['deleted_at'] =
              payload['deleted_at'] ?? DateTime.now().toUtc().toIso8601String();
          await docRef.set(cleanPayload, SetOptions(merge: true));
        } else {
          if (opType == 'create') {
            cleanPayload['created_at_server'] = FieldValue.serverTimestamp();
          }
          await docRef.set(cleanPayload, SetOptions(merge: true));
        }

        await db.delete('outbox', where: 'op_id = ?', whereArgs: [opId]);
      } catch (e) {
        final delayMs = _backoffMs(attempts);
        await db.update(
          'outbox',
          {
            'status': 'failed',
            'next_attempt_at_ms':
                DateTime.now().millisecondsSinceEpoch + delayMs,
          },
          where: 'op_id = ?',
          whereArgs: [opId],
        );
      }
    }
  }

  Future<void> _applyIncrementOperation({
    required DocumentReference<Map<String, dynamic>> docRef,
    required String opId,
    required Map<String, dynamic> payload,
    double? deltaBalance,
    int? deltaQuantity,
  }) {
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      final data = snap.data();
      final appliedOps = data?['applied_ops'];
      if (appliedOps is Map && appliedOps[opId] == true) {
        return;
      }

      final update = Map<String, dynamic>.from(payload)
        ..remove('_delta_balance')
        ..remove('_delta_quantity')
        ..remove('current_balance')
        ..remove('quantity');

      if (deltaBalance != null) {
        update['current_balance'] = FieldValue.increment(deltaBalance);
      }
      if (deltaQuantity != null) {
        update['quantity'] = FieldValue.increment(deltaQuantity);
      }
      if (appliedOps is Map && appliedOps.length >= 200) {
        final keysToPrune = appliedOps.keys.whereType<String>().take(
          appliedOps.length - 199,
        );
        for (final key in keysToPrune) {
          update['applied_ops.$key'] = FieldValue.delete();
        }
      }
      update['applied_ops.$opId'] = true;

      transaction.set(docRef, update, SetOptions(merge: true));
    });
  }

  Future<void> _pullIncremental(Database db, String shopId) async {
    for (final collection in _collections) {
      final columns = await _getTableColumns(db, collection);
      var cursor = await _lastPulledCursor(db, collection);

      for (var page = 0; page < 20; page++) {
        Query<Map<String, dynamic>> query = _firestore
            .collection('shops')
            .doc(shopId)
            .collection(collection)
            .orderBy('updated_at_server')
            .orderBy(FieldPath.documentId)
            .limit(500);

        if (cursor != null) {
          query = query.startAfter([
            Timestamp.fromDate(cursor.timestamp),
            cursor.docId,
          ]);
        }

        final snap = await query.get();
        if (snap.docs.isEmpty) break;

        for (final doc in snap.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['remote_id'] = doc.id;
            data['shop_id'] = shopId;

            final updatedAt = data['updated_at_server'];
            if (updatedAt is! Timestamp) continue;

            final localRow = _toLocalRow(data, columns, collection);
            await db.transaction((txn) async {
              await _upsertByRemoteId(txn, collection, localRow);
            });

            cursor = _SyncCursor(updatedAt.toDate().toUtc(), doc.id);
            await db.insert('sync_state', {
              'entity': collection,
              'last_pulled_at': cursor.timestamp.toIso8601String(),
              'last_pulled_doc_id': cursor.docId,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (_) {
            continue;
          }
        }

        if (snap.docs.length < 500) break;
      }
    }
  }

  Future<_SyncCursor?> _lastPulledCursor(Database db, String entity) async {
    final rows = await db.query(
      'sync_state',
      columns: ['last_pulled_at', 'last_pulled_doc_id'],
      where: 'entity = ?',
      whereArgs: [entity],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['last_pulled_at'] == null) return null;
    final timestamp = DateTime.tryParse(rows.first['last_pulled_at'] as String);
    final docId = rows.first['last_pulled_doc_id'] as String?;
    if (timestamp == null || docId == null || docId.isEmpty) return null;
    return _SyncCursor(timestamp, docId);
  }

  Future<void> _upsertByRemoteId(
    DatabaseExecutor txn,
    String table,
    Map<String, dynamic> row,
  ) async {
    final existing = await txn.query(
      table,
      columns: ['id'],
      where: 'remote_id = ?',
      whereArgs: [row['remote_id']],
      limit: 1,
    );

    if (existing.isEmpty) {
      await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await txn.update(
        table,
        row..remove('id'),
        where: 'remote_id = ?',
        whereArgs: [row['remote_id']],
      );
    }
  }

  Map<String, dynamic> _toLocalRow(
    Map<String, dynamic> data,
    List<String> columns,
    String collection,
  ) {
    final row = Map<String, dynamic>.from(data);
    row.forEach((key, value) {
      if (value is Timestamp) {
        row[key] = value.toDate().toUtc().toIso8601String();
      } else if (value is List || value is Map) {
        row[key] = jsonEncode(value);
      }
    });

    if (collection == 'customers') {
      row['phones'] ??= '[]';
      row['wholesale_codes'] ??= '[]';
    }

    row.removeWhere((key, value) => !columns.contains(key));
    return row;
  }

  Map<String, dynamic> _cleanForFirestore(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);
    cleaned.remove('id');
    cleaned.removeWhere((key, value) => value == null);
    cleaned.updateAll((key, value) {
      if ((key == 'phones' || key == 'wholesale_codes') && value is String) {
        try {
          return jsonDecode(value);
        } catch (_) {
          return [];
        }
      }
      return value;
    });
    return cleaned;
  }

  Future<List<String>> _getTableColumns(Database db, String tableName) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    return result.map((row) => row['name'] as String).toList();
  }

  int _backoffMs(int attempts) {
    final capped = attempts.clamp(1, 6);
    return Duration(seconds: 5 * capped * capped).inMilliseconds;
  }

  Future<bool> checkShopExists(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    return doc.exists;
  }

  Future<int> getPendingOperations(String shopId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as count FROM outbox WHERE shop_id = ?',
      [shopId],
    );
    return (rows.first['count'] as int?) ?? 0;
  }
}

class _SyncCursor {
  final DateTime timestamp;
  final String docId;

  const _SyncCursor(this.timestamp, this.docId);
}
