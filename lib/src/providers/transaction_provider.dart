import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/repository/transaction_repository.dart';
import '../domain/entity/transaction.dart';

// ریپازیتوری
final transactionRepositoryProvider = Provider((ref) => TransactionRepository());

// لیست کل تراکنش‌ها از دیتابیس
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  return ref.read(transactionRepositoryProvider).getTransactions();
});

// سود امروز (خروجی را به double تغییر دادیم برای دقت بیشتر)
final todayProfitProvider = FutureProvider<int>((ref) {
  return ref.read(transactionRepositoryProvider).todayProfit();
});

// تعداد تراکنش‌های امروز
final todayCountProvider = FutureProvider<int>((ref) {
  return ref.read(transactionRepositoryProvider).todayTransactionsCount();
});

// وضعیت‌های فیلتر (StateProviders)
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
final filterCustomerTypeProvider = StateProvider<String?>((ref) => null);
final filterOperatorProvider = StateProvider<String?>((ref) => null);
final filterDateProvider = StateProvider<DateTime?>((ref) => null);

// --- پرووایدر اصلی برای نمایش لیست (این تنها پرووایدر فیلتر است) ---
final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final query = ref.watch(transactionSearchQueryProvider).trim().toLowerCase();
  final customerType = ref.watch(filterCustomerTypeProvider);
  final operator = ref.watch(filterOperatorProvider);
  final selectedDate = ref.watch(filterDateProvider);

  return transactionsAsync.whenData((list) {
    return list.where((t) {
      // ۱. فیلتر متنی
      final matchesQuery = query.isEmpty ||
          t.customerName.toLowerCase().contains(query) ||
          t.phoneNumber.contains(query) ||
          t.companyCode.toLowerCase().contains(query);

      // ۲. فیلتر نوع مشتری
      final matchesType = customerType == null || t.customerType == customerType;

      // ۳. فیلتر اپراتور
      final matchesOperator = operator == null || t.operator == operator;

      // ۴. فیلتر تاریخ
      bool matchesDate = true;
      if (selectedDate != null) {
        try {
          final tDate = DateTime.parse(t.createdAt);
          matchesDate = tDate.year == selectedDate.year &&
              tDate.month == selectedDate.month &&
              tDate.day == selectedDate.day;
        } catch (e) {
          matchesDate = false;
        }
      }

      return matchesQuery && matchesType && matchesOperator && matchesDate;
    }).toList();
  });
});