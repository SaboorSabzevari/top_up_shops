import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../services/session_service.dart';

class SupplierRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    return db.query(
      'suppliers',
      where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [shopId],
      orderBy: 'name COLLATE NOCASE',
    );
  }

  Future<int> addSupplier({
    required String name,
    String? phone,
    String? address,
    double creditLimit = 0,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'remote_id': remoteId,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
      'address': address,
      'credit_limit': creditLimit,
      'balance_cache': 0,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('suppliers', payload);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'suppliers',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    return id;
  }

  Future<void> updateSupplier({
    required int id,
    required String name,
    String? phone,
    String? address,
    double? creditLimit,
    String? status,
  }) async {
    final db = await _db.database;
    final rows = await db.query('suppliers', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'name': name,
      'phone': phone,
      'address': address,
      'credit_limit': creditLimit ?? row['credit_limit'],
      'status': status ?? row['status'],
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('suppliers', payload, where: 'id = ?', whereArgs: [id]);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'suppliers',
      entityId: remoteId,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
  }

  Future<List<Map<String, dynamic>>> getAssets() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    return db.query(
      'assets',
      where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [shopId],
      orderBy: 'purchase_date DESC',
    );
  }

  Future<int> addAsset({
    required String name,
    required String category,
    required double purchasePrice,
    required DateTime purchaseDate,
    int? usefulLifeMonths,
    String? depreciationMethod,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'remote_id': remoteId,
      'shop_id': shopId,
      'name': name,
      'category': category,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'useful_life_months': usefulLifeMonths,
      'depreciation_method': depreciationMethod ?? 'straight_line',
      'current_value': purchasePrice,
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('assets', payload);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'assets',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    return id;
  }

  Future<void> recordPurchase({
    required int supplierId,
    required double amount,
  }) async {
    final db = await _db.database;
    final rows = await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId], limit: 1);
    if (rows.isEmpty) return;
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final newBalance = (row['balance_cache'] as num? ?? 0) + amount;
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'balance_cache': newBalance,
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('suppliers', payload, where: 'id = ?', whereArgs: [supplierId]);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'suppliers',
      entityId: remoteId,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
    await _db.addTransaction({
      'customer_id': null,
      'customer_name': row['name']?.toString() ?? '',
      'customer_type': 'supplier',
      'operator_name': 'supplier_purchase',
      'phone_number': row['phone']?.toString() ?? '',
      'company_code': '',
      'sent_amount': 0,
      'discount': 0,
      'total_price': -amount,
      'paid_amount': -amount,
      'received_amount': -amount,
      'cost_price': 0,
      'profit': 0,
      'transaction_type': 'supplier_purchase',
      'metadata_json': '{"supplier_id":"$supplierId"}',
    });
  }

  Future<void> recordPayment({
    required int supplierId,
    required double amount,
  }) async {
    final db = await _db.database;
    final rows = await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId], limit: 1);
    if (rows.isEmpty) return;
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final newBalance = (row['balance_cache'] as num? ?? 0) - amount;
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'balance_cache': newBalance,
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('suppliers', payload, where: 'id = ?', whereArgs: [supplierId]);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'suppliers',
      entityId: remoteId,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
    await _db.addTransaction({
      'customer_id': null,
      'customer_name': row['name']?.toString() ?? '',
      'customer_type': 'supplier',
      'operator_name': 'supplier_payment',
      'phone_number': row['phone']?.toString() ?? '',
      'company_code': '',
      'sent_amount': 0,
      'discount': 0,
      'total_price': -amount,
      'paid_amount': -amount,
      'received_amount': -amount,
      'cost_price': 0,
      'profit': 0,
      'transaction_type': 'supplier_payment',
      'metadata_json': '{"supplier_id":"$supplierId"}',
    });
  }
}
