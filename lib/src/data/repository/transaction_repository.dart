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
  Future<int> todayProfit() async {
    final database = await _db.database;

    final result = await database.rawQuery('''
      SELECT SUM(profit) as total
      FROM transactions
      WHERE date(created_at) = date('now','localtime')
    ''');

    return result.first['total'] as int? ?? 0;
  }

  /// موجودی صندوق
  Future<int> walletBalance() async {
    final database = await _db.database;

    final result = await database.rawQuery('''
      SELECT SUM(received_amount) as total
      FROM transactions
    ''');

    return result.first['total'] as int? ?? 0;
  }
}
