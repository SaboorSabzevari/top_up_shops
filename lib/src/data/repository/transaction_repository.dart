// =====================================================================
// transaction_repository.dart  (Firestore-only rewrite)
// مسیر پیشنهادی: lib/src/data/repository/transaction_repository.dart
// =====================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:top_up_shops/src/data/local/app_database.dart';
import '../../domain/entity/transaction.dart';
import '../../providers/session_provider.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _txCol(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('transactions');

  Future<int> addTransaction(Map<String, dynamic> data) async {
    await _db.addTransaction(data);
    return 1;
  }

  Future<List<Map<String, dynamic>>> _activeInRange(
      String shopId,
      DateTime start,
      DateTime end,
      ) async {
    final snap = await _txCol(shopId)
        .where('created_at', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('created_at', isLessThan: end.toIso8601String())
        .get();
    return snap.docs
        .where((d) => d.data()['deleted_at'] == null)
        .map((d) => d.data())
        .toList();
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// دریافت مجموع فروش در یک تاریخ خاص برای یک فروشگاه
  Future<double> getSalesByDate(String shopId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _activeInRange(shopId, start, end);
    double total = 0;
    for (final r in rows) {
      total += (r['received_amount'] as num? ?? 0).toDouble();
    }
    return total;
  }

  Future<Map<String, dynamic>> getSalesSummaryData(String shopId) async {
    final today = _startOfToday();
    final yesterday = today.subtract(const Duration(days: 1));

    final todayRows = await _activeInRange(
      shopId,
      today,
      today.add(const Duration(days: 1)),
    );
    final yesterdayRows = await _activeInRange(shopId, yesterday, today);

    double sum(List<Map<String, dynamic>> rows) => rows.fold(
      0.0,
          (s, r) => s + (r['received_amount'] as num? ?? 0).toDouble(),
    );

    final todayTotal = sum(todayRows);
    final yesterdayTotal = sum(yesterdayRows);

    double percentChange = 0;
    if (yesterdayTotal > 0) {
      percentChange = ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100;
    } else if (todayTotal > 0) {
      percentChange = 100;
    }

    return {
      'today': todayTotal.toInt(),
      'yesterday': yesterdayTotal,
      'percent': percentChange,
    };
  }

  /// دریافت تراکنش‌ها برای دکان فعلی (همه‌ی کارمندان یک دکان دیتای مشترک می‌بینند)
  Future<List<TransactionModel>> getTransactions(
      UserModel user, {
        int? limit,
        int? offset,
      }) async {
    Query<Map<String, dynamic>> q = _txCol(user.shopId).orderBy(
      'created_at',
      descending: true,
    );

    final fetchCount = (limit ?? 500) + (offset ?? 0);
    q = q.limit(fetchCount);

    final snap = await q.get();
    var docs = snap.docs.where((d) => d.data()['deleted_at'] == null).toList();

    if (offset != null && offset > 0) {
      docs = docs.length > offset ? docs.sublist(offset) : [];
    }
    if (limit != null && docs.length > limit) {
      docs = docs.sublist(0, limit);
    }

    return docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return TransactionModel.fromMap(map);
    }).toList();
  }

  Future<int> todayProfit(String shopId) async {
    final today = _startOfToday();
    final rows = await _activeInRange(
      shopId,
      today,
      today.add(const Duration(days: 1)),
    );
    double total = 0;
    for (final r in rows) {
      total += (r['profit'] as num? ?? 0).toDouble();
    }
    return total.toInt();
  }

  Future<int> todayTransactionsCount(String shopId) async {
    final today = _startOfToday();
    final rows = await _activeInRange(
      shopId,
      today,
      today.add(const Duration(days: 1)),
    );
    return rows.length;
  }

  Future<int> todayTotalSales(String shopId) async {
    final today = _startOfToday();
    final rows = await _activeInRange(
      shopId,
      today,
      today.add(const Duration(days: 1)),
    );
    double total = 0;
    for (final r in rows) {
      total += (r['received_amount'] as num? ?? 0).toDouble();
    }
    return total.toInt();
  }

  Future<int> todaySentAmount(String shopId) async {
    final today = _startOfToday();
    final rows = await _activeInRange(
      shopId,
      today,
      today.add(const Duration(days: 1)),
    );
    double total = 0;
    for (final r in rows) {
      total += (r['sent_amount'] as num? ?? 0).toDouble();
    }
    return total.toInt();
  }

  Future<double> getSalesGrowthPercentage(String shopId) async {
    final data = await getSalesSummaryData(shopId);
    return (data['percent'] as num).toDouble();
  }
}