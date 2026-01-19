import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../services/session_service.dart';

class ShopRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<Map<String, dynamic>?> getCurrentShop() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final rows = await db.query('shops', where: 'id = ?', whereArgs: [shopId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> updateShopProfile({
    required String name,
    String? phone,
    String? address,
    String? logoPath,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final existing = await db.query('shops', where: 'id = ?', whereArgs: [shopId], limit: 1);
    if (existing.isEmpty) return;
    final row = existing.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'id': shopId,
      'name': name,
      'phone': phone,
      'address': address,
      'logo_path': logoPath,
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('shops', payload, where: 'id = ?', whereArgs: [shopId]);
    SessionService.instance.updateShopName(name);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'shops',
      entityId: shopId,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
  }

  Future<void> updateSubscription({
    required DateTime expiryDate,
    required String status,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final existing = await db.query('shops', where: 'id = ?', whereArgs: [shopId], limit: 1);
    if (existing.isEmpty) return;
    final row = existing.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'subscription_expiry': expiryDate.toIso8601String(),
      'subscription_expiry_ms': expiryDate.millisecondsSinceEpoch,
      'subscription_status': status,
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('shops', payload, where: 'id = ?', whereArgs: [shopId]);
    final active = status == 'active' && expiryDate.isAfter(DateTime.now());
    SessionService.instance.updateSubscription(active: active, expiry: expiryDate);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'shops',
      entityId: shopId,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
  }
}
