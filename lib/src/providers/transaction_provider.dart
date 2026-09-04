// مسیر پیشنهادی: lib/src/providers/transaction_provider.dart
// تنها تغییر نسبت به نسخه‌ی قبلی: selectedCustomerIdProvider از int? به
// String? تغییر کرد (چون آیدی مشتری در Firestore رشته است).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:top_up_shops/src/providers/session_provider.dart';
import '../data/repository/transaction_repository.dart';
import '../domain/entity/transaction.dart';

final transactionRepositoryProvider = Provider(
      (ref) => TransactionRepository(),
);

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(transactionRepositoryProvider).getTransactions(user);
});

class TransactionsPageRequest {
  final int limit;
  final int offset;

  const TransactionsPageRequest({this.limit = 30, this.offset = 0});
}

final paginatedTransactionsProvider =
FutureProvider.family<List<TransactionModel>, TransactionsPageRequest>((
    ref,
    request,
    ) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref
      .read(transactionRepositoryProvider)
      .getTransactions(user, limit: request.limit, offset: request.offset);
});

final todayProfitProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(transactionRepositoryProvider).todayProfit(user.shopId);
});

final chartDataProvider = FutureProvider<Map<String, List<double>>>((
    ref,
    ) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'current': [], 'prev': []};

  final now = DateTime.now();

  final currentWeekFutures = List.generate(7, (i) {
    final date = now.subtract(Duration(days: 6 - i));
    return repository.getSalesByDate(user.shopId, date);
  });

  final prevWeekFutures = List.generate(7, (i) {
    final date = now.subtract(Duration(days: 13 - i));
    return repository.getSalesByDate(user.shopId, date);
  });

  final results = await Future.wait([
    Future.wait(currentWeekFutures),
    Future.wait(prevWeekFutures),
  ]);

  return {'current': results[0], 'prev': results[1]};
});

final todaySalesProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(transactionRepositoryProvider).todayTotalSales(user.shopId);
});

final salesSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'today': 0, 'yesterday': 0.0, 'percent': 0.0};

  return ref
      .read(transactionRepositoryProvider)
      .getSalesSummaryData(user.shopId);
});

final salesGrowthProvider = FutureProvider<double>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  return ref
      .read(transactionRepositoryProvider)
      .getSalesGrowthPercentage(user.shopId);
});

final todayTotalSalesProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(transactionRepositoryProvider).todayTotalSales(user.shopId);
});

final todaySentAmountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(transactionRepositoryProvider).todaySentAmount(user.shopId);
});

final todayCountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref
      .read(transactionRepositoryProvider)
      .todayTransactionsCount(user.shopId);
});

final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
final filterCustomerTypeProvider = StateProvider<String?>((ref) => null);
final filterOperatorProvider = StateProvider<String?>((ref) => null);
final filterDateProvider = StateProvider<DateTimeRange?>((ref) => null);

final reportDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// ⚠️ تغییر کلیدی: int? -> String?  (آیدی مشتری در Firestore رشته است)
final selectedCustomerIdProvider = StateProvider<String?>((ref) => null);
final selectedCustomerRemoteIdProvider = StateProvider<String?>((ref) => null);

final customerReportTransactionsProvider =
Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  final selectedId = ref.watch(selectedCustomerIdProvider);
  final selectedRemoteId = ref.watch(selectedCustomerRemoteIdProvider);
  final dateRange = ref.watch(reportDateRangeProvider);

  if (selectedId == null && selectedRemoteId == null) {
    return const AsyncValue.data([]);
  }

  return transactionsAsync.whenData((list) {
    return list.where((t) {
      final matchesCustomer = selectedRemoteId != null
          ? t.customerRemoteId == selectedRemoteId
          : t.customerId == selectedId;

      bool matchesDate = true;
      if (dateRange != null) {
        try {
          final tDate = DateTime.parse(t.createdAt);
          final start = DateTime(
            dateRange.start.year,
            dateRange.start.month,
            dateRange.start.day,
          );
          final end = DateTime(
            dateRange.end.year,
            dateRange.end.month,
            dateRange.end.day,
            23,
            59,
            59,
          );
          matchesDate =
              tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                  tDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) {
          matchesDate = false;
        }
      }
      return matchesCustomer && matchesDate;
    }).toList();
  });
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((
    ref,
    ) async {
  final all = await ref.watch(transactionsProvider.future);
  return all.take(5).toList();
});

final filteredTransactionsProvider =
Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final query = ref
      .watch(transactionSearchQueryProvider)
      .trim()
      .toLowerCase();
  final customerType = ref.watch(filterCustomerTypeProvider);
  final operator = ref.watch(filterOperatorProvider);
  final dateRange = ref.watch(filterDateProvider);

  return transactionsAsync.whenData((list) {
    return list.where((t) {
      final matchesQuery =
          query.isEmpty ||
              t.customerName.toLowerCase().contains(query) ||
              t.phoneNumber.contains(query) ||
              t.companyCode.toLowerCase().contains(query);

      final matchesType =
          customerType == null || t.customerType == customerType;
      final matchesOperator = operator == null || t.operator == operator;

      bool matchesDate = true;
      if (dateRange != null) {
        try {
          final tDate = DateTime.parse(t.createdAt);
          final start = DateTime(
            dateRange.start.year,
            dateRange.start.month,
            dateRange.start.day,
          );
          final end = DateTime(
            dateRange.end.year,
            dateRange.end.month,
            dateRange.end.day,
            23,
            59,
            59,
          );
          matchesDate =
              tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                  tDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) {
          matchesDate = false;
        }
      }

      return matchesQuery && matchesType && matchesOperator && matchesDate;
    }).toList();
  });
});