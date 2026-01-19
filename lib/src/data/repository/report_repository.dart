import '../local/app_database.dart';
import '../../services/session_service.dart';

class ReportRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Map<String, num>> getCashflow({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final where = <String>['shop_id = ?', '(is_deleted IS NULL OR is_deleted = 0)'];
    final args = <Object?>[shopId];
    if (start != null && end != null) {
      where.add('date(created_at) BETWEEN date(?) AND date(?)');
      args.add(start.toIso8601String());
      args.add(end.toIso8601String());
    }
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN received_amount >= 0 THEN received_amount ELSE 0 END) as cash_in,
        SUM(CASE WHEN received_amount < 0 THEN ABS(received_amount) ELSE 0 END) as cash_out
      FROM transactions
      WHERE ${where.join(' AND ')}
    ''', args);
    final row = result.first;
    return {
      'cash_in': (row['cash_in'] as num?) ?? 0,
      'cash_out': (row['cash_out'] as num?) ?? 0,
    };
  }

  Future<num> getProfit({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final where = <String>['shop_id = ?', '(is_deleted IS NULL OR is_deleted = 0)'];
    final args = <Object?>[shopId];
    if (start != null && end != null) {
      where.add('date(created_at) BETWEEN date(?) AND date(?)');
      args.add(start.toIso8601String());
      args.add(end.toIso8601String());
    }
    final result = await db.rawQuery('''
      SELECT SUM(profit) as total
      FROM transactions
      WHERE ${where.join(' AND ')}
    ''', args);
    return (result.first['total'] as num?) ?? 0;
  }

  Future<num> getInventoryValue() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final result = await db.rawQuery('''
      SELECT SUM(remaining_qty * buy_price) as total
      FROM paper_card_batches
      WHERE shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)
    ''', [shopId]);
    return (result.first['total'] as num?) ?? 0;
  }

  Future<num> getSupplierBalance() async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final result = await db.rawQuery('''
      SELECT SUM(balance_cache) as total
      FROM suppliers
      WHERE shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)
    ''', [shopId]);
    return (result.first['total'] as num?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getEmployeePerformance({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    final shopId = SessionService.instance.currentShopId;
    final where = <String>['t.shop_id = ?', '(t.is_deleted IS NULL OR t.is_deleted = 0)'];
    final args = <Object?>[shopId];
    if (start != null && end != null) {
      where.add('date(t.created_at) BETWEEN date(?) AND date(?)');
      args.add(start.toIso8601String());
      args.add(end.toIso8601String());
    }
    final result = await db.rawQuery('''
      SELECT t.created_by_employee_id as employee_id,
             e.full_name as employee_name,
             COUNT(*) as tx_count,
             SUM(t.received_amount) as total_amount,
             SUM(t.profit) as total_profit
      FROM transactions t
      LEFT JOIN employees e ON t.created_by_employee_id = e.uid
      WHERE ${where.join(' AND ')}
      GROUP BY t.created_by_employee_id
      ORDER BY tx_count DESC
      LIMIT 10
    ''', args);
    return result;
  }
}
