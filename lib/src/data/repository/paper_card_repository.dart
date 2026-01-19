import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../services/session_service.dart';

class PaperCardRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> getBatches() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    return db.query(
      'paper_card_batches',
      where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [shopId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> addBatch({
    required int providerId,
    required int unitId,
    required double faceValue,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'remote_id': remoteId,
      'shop_id': shopId,
      'provider_id': providerId,
      'unit_id': unitId,
      'face_value': faceValue,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'quantity': quantity,
      'remaining_qty': quantity,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('paper_card_batches', payload);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'paper_card_batches',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    return id;
  }

  Future<void> adjustBatchQuantity({
    required int batchId,
    required int delta,
  }) async {
    final db = await _db.database;
    final rows = await db.query('paper_card_batches', where: 'id = ?', whereArgs: [batchId], limit: 1);
    if (rows.isEmpty) return;
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remaining = (row['remaining_qty'] as int? ?? 0) + delta;
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'remaining_qty': remaining < 0 ? 0 : remaining,
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('paper_card_batches', payload, where: 'id = ?', whereArgs: [batchId]);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'paper_card_batches',
      entityId: remoteId,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
  }
}

