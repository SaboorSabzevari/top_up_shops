import 'package:top_up_shops/src/data/local/app_database.dart';
import '../../domain/entity/transaction.dart';
import '../../providers/session_provider.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Future<int> addTransaction(Map<String, dynamic> data) async {
    return _db.addTransaction(data);
  }

  Future<Map<String, dynamic>> getSalesSummaryData(String shopId) async {
    final database = await _db.database;

    // فروش امروز
    final todayRes = await database.rawQuery(
      '''
    SELECT SUM(received_amount) as total FROM transactions 
    WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime')
  ''',
      [shopId],
    );
    double today = (todayRes.first['total'] as num? ?? 0).toDouble();

    // فروش دیروز
    final yesterdayRes = await database.rawQuery(
      '''
    SELECT SUM(received_amount) as total FROM transactions 
    WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime', '-1 day')
  ''',
      [shopId],
    );
    double yesterday = (yesterdayRes.first['total'] as num? ?? 0).toDouble();

    // محاسبه درصد تغییر
    double percentChange = 0;
    if (yesterday > 0) {
      percentChange = ((today - yesterday) / yesterday) * 100;
    } else if (today > 0) {
      percentChange = 100; // اگر دیروز صفر بوده و امروز فروش داشتیم
    }

    return {
      'today': today.toInt(),
      'yesterday': yesterday,
      'percent': percentChange,
    };
  }

  /// دریافت تراکنش‌ها بر اساس سطح دسترسی و آیدی دکان
  Future<List<TransactionModel>> getTransactions(
    UserModel user, {
    int? limit,
    int? offset,
  }) async {
    final database = await _db.database;

    // فیلتر کردن بر اساس نقش: OWNER همه دکان را می‌بیند، STAFF فقط تراکنش‌های خودش
    String whereClause = "t.shop_id = ?";
    List<dynamic> whereArgs = [user.shopId];

    final result = await database.rawQuery(
      '''
    SELECT t.*, c.name as current_customer_name 
    FROM transactions t
    LEFT JOIN customers c ON t.customer_remote_id = c.remote_id
    WHERE $whereClause AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC
    ${limit == null ? '' : 'LIMIT ? OFFSET ?'}
  ''',
      [...whereArgs, if (limit != null) limit, if (limit != null) offset ?? 0],
    );

    return result.map((map) {
      final updatedMap = Map<String, dynamic>.from(map);
      if (map['current_customer_name'] != null) {
        updatedMap['customer_name'] = map['current_customer_name'];
      }
      return TransactionModel.fromMap(updatedMap);
    }).toList();
  }

  /// دریافت مجموع فروش در یک تاریخ خاص برای یک فروشگاه
  Future<double> getSalesByDate(String shopId, DateTime date) async {
    final database = await _db.database;
    final dateString = date.toIso8601String().split(
      'T',
    )[0]; // تبدیل به YYYY-MM-DD

    final result = await database.rawQuery(
      '''
      SELECT SUM(received_amount) as total FROM transactions 
      WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at) = date(?)
    ''',
      [shopId, dateString],
    );

    return (result.first['total'] as num? ?? 0).toDouble();
  }

  /// سود امروز دکان
  Future<int> todayProfit(String shopId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
    SELECT SUM(profit) as total
    FROM transactions
    WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime')
  ''',
      [shopId],
    );

    final total = result.first['total'];
    if (total == null) return 0;
    return (total as num).toInt();
  }

  /// تعداد تراکنش‌های امروز دکان
  Future<int> todayTransactionsCount(String shopId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
    SELECT COUNT(*) as count 
    FROM transactions 
    WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime')
  ''',
      [shopId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// مجموع فروش امروز دکان (مبلغ دریافتی)
  Future<int> todayTotalSales(String shopId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT SUM(received_amount) as total FROM transactions 
      WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime')
    ''',
      [shopId],
    );
    return (result.first['total'] as num? ?? 0).toInt();
  }

  /// مجموع تراکنش‌های امروز دکان (مبلغ ارسال شده)
  Future<int> todaySentAmount(String shopId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT SUM(sent_amount) as total FROM transactions 
      WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime')
    ''',
      [shopId],
    );
    return (result.first['total'] as num? ?? 0).toInt();
  }

  /// محاسبه درصد تغییر فروش دکان نسبت به دیروز
  Future<double> getSalesGrowthPercentage(String shopId) async {
    final database = await _db.database;

    // فروش امروز دکان
    final todayRes = await database.rawQuery(
      '''
      SELECT SUM(received_amount) as total FROM transactions 
      WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now','localtime')
    ''',
      [shopId],
    );
    double today = (todayRes.first['total'] as num? ?? 0).toDouble();

    // فروش دیروز دکان
    final yesterdayRes = await database.rawQuery(
      '''
      SELECT SUM(received_amount) as total FROM transactions 
      WHERE shop_id = ? AND deleted_at IS NULL AND date(created_at, 'localtime') = date('now', '-1 day', 'localtime')
    ''',
      [shopId],
    );
    double yesterday = (yesterdayRes.first['total'] as num? ?? 0).toDouble();

    if (yesterday == 0) return today > 0 ? 100.0 : 0.0;
    return ((today - yesterday) / yesterday) * 100;
  }
}
