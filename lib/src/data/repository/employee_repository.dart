import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../services/session_service.dart';

class EmployeeRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    return db.query(
      'employees',
      where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [shopId],
      orderBy: 'full_name COLLATE NOCASE',
    );
  }

  Future<void> addEmployee({
    required String uid,
    required String fullName,
    required String roleId,
    String? phone,
    String? email,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final now = DateTime.now().toIso8601String();
    final opId = _uuid.v4();
    final payload = {
      'uid': uid,
      'shop_id': shopId,
      'full_name': fullName,
      'role_id': roleId,
      'status': 'active',
      'phone': phone,
      'email': email,
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    await db.insert('employees', payload, conflictAlgorithm: ConflictAlgorithm.replace);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'employees',
      entityId: uid,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    await _db.enqueueOutbox(
      db,
      opId: _uuid.v4(),
      entity: 'users',
      entityId: uid,
      opType: 'create',
      payload: {
        'shopId': shopId,
        'employeeId': uid,
        'roleId': roleId,
        'status': 'active',
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      baseVersion: 0,
    );
  }

  Future<void> updateEmployee({
    required String uid,
    required String fullName,
    required String roleId,
    String? phone,
    String? email,
    String? status,
  }) async {
    final db = await _db.database;
    final existing = await db.query('employees', where: 'uid = ?', whereArgs: [uid], limit: 1);
    if (existing.isEmpty) return;
    final row = existing.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'full_name': fullName,
      'role_id': roleId,
      'phone': phone,
      'email': email,
      'status': status ?? row['status'],
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('employees', payload, where: 'uid = ?', whereArgs: [uid]);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'employees',
      entityId: uid,
      opType: 'update',
      payload: payload,
      baseVersion: prevVersion,
    );
    await _db.enqueueOutbox(
      db,
      opId: _uuid.v4(),
      entity: 'users',
      entityId: uid,
      opType: 'update',
      payload: {
        'shopId': payload['shop_id'],
        'employeeId': uid,
        'roleId': roleId,
        'status': status ?? payload['status'],
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      baseVersion: prevVersion,
    );
  }
}
