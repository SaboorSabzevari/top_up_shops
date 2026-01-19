import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../services/session_service.dart';

class SalaryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> getContracts() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    return db.query(
      'salary_contracts',
      where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      whereArgs: [shopId],
      orderBy: 'effective_from DESC',
    );
  }

  Future<int> addContract({
    required String employeeUid,
    required String type,
    required double baseAmount,
    double commissionRate = 0,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'remote_id': remoteId,
      'shop_id': shopId,
      'employee_uid': employeeUid,
      'type': type,
      'base_amount': baseAmount,
      'commission_rate': commissionRate,
      'effective_from': effectiveFrom.toIso8601String(),
      'effective_to': effectiveTo?.toIso8601String(),
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('salary_contracts', payload);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'salary_contracts',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    return id;
  }

  Future<int> addPayment({
    required String employeeUid,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double amount,
    String paymentMethod = 'cash',
  }) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'remote_id': remoteId,
      'shop_id': shopId,
      'employee_uid': employeeUid,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'amount': amount,
      'payment_method': paymentMethod,
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('salary_payments', payload);
    await _db.enqueueOutbox(
      db,
      opId: opId,
      entity: 'salary_payments',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );

    final employee = await db.query('employees', where: 'uid = ?', whereArgs: [employeeUid], limit: 1);
    final name = employee.isNotEmpty ? employee.first['full_name']?.toString() ?? '' : employeeUid;
    await _db.addTransaction({
      'customer_id': null,
      'customer_name': name,
      'customer_type': 'employee',
      'operator_name': 'salary',
      'phone_number': employee.isNotEmpty ? employee.first['phone']?.toString() ?? '' : '',
      'company_code': '',
      'sent_amount': 0,
      'discount': 0,
      'total_price': -amount,
      'paid_amount': -amount,
      'received_amount': -amount,
      'cost_price': 0,
      'profit': 0,
      'transaction_type': 'salary_payment',
      'metadata_json': '{"employee_uid":"$employeeUid"}',
    });

    return id;
  }
}
