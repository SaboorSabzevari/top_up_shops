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
}}
