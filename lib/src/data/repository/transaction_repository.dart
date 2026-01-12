import 'package:top_up_shops/src/data/local/app_database.dart';

import '../../domain/entity/transaction.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// همه تراکنش‌ها
  Future<List<TransactionModel>> getTransactions() async {
    final database = await _db.database;

    final result = await database.query(
      'transactions',
      orderBy: 'created_at DESC',
    );

    return result.map(TransactionModel.fromMap).toList();
  }

  /// سود امروز
  // در فایل transaction_repository.dart متد را به این شکل اصلاح کنید:

  Future<int> todayProfit() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
    SELECT SUM(profit) as total
    FROM transactions
    WHERE date(created_at) = date('now','localtime')
  ''');

    // تبدیل امن num به int برای جلوگیری از خطای نوع داده
    final total = result.first['total'];
    if (total == null) return 0;
    return (total as num).toInt();
  }

/// تعداد تراکنش‌های امروز
Future<int> todayTransactionsCount() async {
  final database = await _db.database;
  final result = await database.rawQuery('''
    SELECT COUNT(*) as count 
    FROM transactions 
    WHERE date(created_at) = date('now','localtime')
  ''');
  return result.first['count'] as int? ?? 0;
}
  /// مجموع فروش امروز (مبلغ دریافتی)
  Future<int> todayTotalSales() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT SUM(received_amount) as total FROM transactions 
      WHERE date(created_at) = date('now','localtime')
    ''');
    return (result.first['total'] as num? ?? 0).toInt();
  }

  /// مجموع تراکنش‌های امروز (مبلغ ارسال شده)
  Future<int> todaySentAmount() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT SUM(sent_amount) as total FROM transactions 
      WHERE date(created_at) = date('now','localtime')
    ''');
    return (result.first['total'] as num? ?? 0).toInt();
  }

  /// محاسبه درصد تغییر نسبت به دیروز
  Future<double> getSalesGrowthPercentage() async {
    final database = await _db.database;

    // فروش امروز
    final todayRes = await database.rawQuery("SELECT SUM(received_amount) as total FROM transactions WHERE date(created_at) = date('now','localtime')");
    double today = (todayRes.first['total'] as num? ?? 0).toDouble();

    // فروش دیروز
    final yesterdayRes = await database.rawQuery("SELECT SUM(received_amount) as total FROM transactions WHERE date(created_at) = date('now', '-1 day', 'localtime')");
    double yesterday = (yesterdayRes.first['total'] as num? ?? 0).toDouble();

    if (yesterday == 0) return today > 0 ? 100.0 : 0.0;
    return ((today - yesterday) / yesterday) * 100;
  }
}


