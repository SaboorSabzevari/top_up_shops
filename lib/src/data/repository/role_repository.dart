import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../services/session_service.dart';

class RoleRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> getRoles() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    return db.query(
      'roles',
      where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [shopId],
      orderBy: 'name COLLATE NOCASE',
    );
  }

  Future<void> addRole({
    required String name,
    required List<String> permissions,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final now = DateTime.now().toIso8601String();
    final opId = _uuid.v4();
    final roleId = _uuid.v4();
    final payload = {
      'id': roleId,
      'shop_id': shopId,
      'name': name,
      'permissions_json': jsonEncode(permissions),
      'is_system': 0,
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    await db.insert('roles', payload, conflictAlgorithm: ConflictAlgorithm.replace);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'roles',
      entityId: roleId,
      opType: 'create',
      payload: {
        ...payload,
        'permissions': permissions,
      },
      baseVersion: 0,
    );
  }

  Future<void> updateRole({
    required String id,
    required String name,
    required List<String> permissions,
  }) async {
    final db = await _db.database;
    final existing = await db.query('roles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (existing.isEmpty) return;
    final row = existing.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...row,
      'name': name,
      'permissions_json': jsonEncode(permissions),
      'updated_at': now,
      'version': prevVersion + 1,
      'last_op_id': opId,
    };
    await db.update('roles', payload, where: 'id = ?', whereArgs: [id]);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'roles',
      entityId: id,
      opType: 'update',
      payload: {
        ...payload,
        'permissions': permissions,
      },
      baseVersion: prevVersion,
    );
  }
}

