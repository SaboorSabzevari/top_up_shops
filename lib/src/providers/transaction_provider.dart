// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import '../data/repository/transaction_repository.dart';
// import '../domain/entity/transaction.dart';
//
// // ریپازیتوری
// final transactionRepositoryProvider = Provider((ref) => TransactionRepository());
//
// // لیست کل تراکنش‌ها از دیتابیس
// final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
//   return ref.read(transactionRepositoryProvider).getTransactions();
// });
//
// // سود امروز
// final todayProfitProvider = FutureProvider<int>((ref) {
//   return ref.read(transactionRepositoryProvider).todayProfit();
// });
//
// // تعداد تراکنش‌های امروز
// final todayCountProvider = FutureProvider<int>((ref) {
//   return ref.read(transactionRepositoryProvider).todayTransactionsCount();
// });
//
// // وضعیت‌های فیلتر (اصلاح شده)
// final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
// final filterCustomerTypeProvider = StateProvider<String?>((ref) => null);
// final filterOperatorProvider = StateProvider<String?>((ref) => null);
//
// // ۱. اصلاح مهم: تغییر تاریخ تکی به بازه زمانی (DateTimeRange) برای هماهنگی با صفحه آنالیز
// final filterDateProvider = StateProvider<DateTimeRange?>((ref) => null);
//
// // پروایدر مخصوص صفحه آنالیز (گزارش مشتری خاص)
// final reportDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);
// final selectedCustomerNameProvider = StateProvider<String?>((ref) => null);
//
// // --- ۲. پروایدر فیلتر شده برای صفحه "تاریخچه تراکنش‌ها" ---
// final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
//   final transactionsAsync = ref.watch(transactionsProvider);
//   final query = ref.watch(transactionSearchQueryProvider).trim().toLowerCase();
//   final customerType = ref.watch(filterCustomerTypeProvider);
//   final operator = ref.watch(filterOperatorProvider);
//   final dateRange = ref.watch(filterDateProvider); // بازه زمانی
//
//   return transactionsAsync.whenData((list) {
//     return list.where((t) {
//       // فیلتر متنی
//       final matchesQuery = query.isEmpty ||
//           t.customerName.toLowerCase().contains(query) ||
//           t.phoneNumber.contains(query) ||
//           t.companyCode.toLowerCase().contains(query);
//
//       // فیلتر نوع مشتری
//       final matchesType = customerType == null || t.customerType == customerType;
//
//       // فیلتر اپراتور
//       final matchesOperator = operator == null || t.operator == operator;
//
//       // اصلاح فیلتر تاریخ: بررسی قرار گرفتن در بازه
//       bool matchesDate = true;
//       if (dateRange != null) {
//         try {
//           final tDate = DateTime.parse(t.createdAt);
//           final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
//           final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
//           matchesDate = tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
//               tDate.isBefore(end.add(const Duration(seconds: 1)));
//         } catch (e) {
//           matchesDate = false;
//         }
//       }
//
//       return matchesQuery && matchesType && matchesOperator && matchesDate;
//     }).toList();
//   });
// });
//
// // --- ۳. پروایدر فیلتر شده برای صفحه "آنالیز مشتری" ---
// final customerReportTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
//   final transactionsAsync = ref.watch(transactionsProvider);
//   final selectedName = ref.watch(selectedCustomerNameProvider);
//   final dateRange = ref.watch(reportDateRangeProvider);
// // به جای نام، آیدی را نگه دارید
//   final selectedCustomerIdProvider = StateProvider<int?>((ref) => null);
//   if (selectedName == null) return const AsyncValue.data([]);
//
//   return transactionsAsync.whenData((list) {
//     return list.where((t) {
//       // فیلتر دقیق بر اساس نام مشتری
//       final matchesCustomer = t.customerName.trim() == selectedName.trim();
//
//       // فیلتر بازه زمانی
//       bool matchesDate = true;
//       if (dateRange != null) {
//         try {
//           final tDate = DateTime.parse(t.createdAt);
//           final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
//           final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
//           matchesDate = tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
//               tDate.isBefore(end.add(const Duration(seconds: 1)));
//         } catch (e) {
//           matchesDate = false;
//         }
//       }
//       return matchesCustomer && matchesDate;
//     }).toList();
//   });
// });
// final todayTotalSalesProvider = FutureProvider<int>((ref) => ref.read(transactionRepositoryProvider).todayTotalSales());
// final todaySentAmountProvider = FutureProvider<int>((ref) => ref.read(transactionRepositoryProvider).todaySentAmount());
// final salesGrowthProvider = FutureProvider<double>((ref) => ref.read(transactionRepositoryProvider).getSalesGrowthPercentage());
//
// final todaySalesProvider = FutureProvider<int>((ref) => ref.watch(transactionRepositoryProvider).todayTotalSales());
// final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
//   final all = await ref.watch(transactionsProvider.future);
//   return all.take(5).toList(); // فقط ۵ تراکنش آخر
// });
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart';
import 'package:top_up_shops/src/providers/session_provider.dart';
import '../data/repository/transaction_repository.dart';
import '../domain/entity/transaction.dart';

// ریپازیتوری
final transactionRepositoryProvider = Provider((ref) => TransactionRepository());

// لیست کل تراکنش‌ها از دیتابیس
// لیست تراکنش‌ها: فقط دکان فعلی و با رعایت نقش کاربر
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  // متد getTransactions را در ریپازیتوری قبلاً اصلاح کردیم تا یوزر بگیرد
  return ref.read(transactionRepositoryProvider).getTransactions(user);
});

// سود امروز دکان فعلی
final todayProfitProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(transactionRepositoryProvider).todayProfit(user.shopId);
});

// مجموع فروش امروز دکان فعلی
final todaySalesProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(transactionRepositoryProvider).todayTotalSales(user.shopId);
});

// درصد رشد فروش دکان فعلی
final salesGrowthProvider = FutureProvider<double>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  return ref.read(transactionRepositoryProvider).getSalesGrowthPercentage(user.shopId);
});

// سود امروز
// مجموع فروش امروز دکان (مبلغ دریافتی از مشتری)
final todayTotalSalesProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  return ref.read(transactionRepositoryProvider).todayTotalSales(user.shopId);
});

// مجموع مبلغ ارسال شده امروز دکان (مبلغ خام کریدیت)
final todaySentAmountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  return ref.read(transactionRepositoryProvider).todaySentAmount(user.shopId);
});

// تعداد کل تراکنش‌های امروز دکان
final todayCountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  return ref.read(transactionRepositoryProvider).todayTransactionsCount(user.shopId);
});
// تعداد
// وضعیت‌های فیلتر تاریخچه
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');
final filterCustomerTypeProvider = StateProvider<String?>((ref) => null);
final filterOperatorProvider = StateProvider<String?>((ref) => null);
final filterDateProvider = StateProvider<DateTimeRange?>((ref) => null);

// --- اصلاح اصلی برای صفحه آنالیز ---
final reportDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// به جای ذخیره نام، آیدی مشتری انتخاب شده را اینجا نگه می‌داریم
final selectedCustomerIdProvider = StateProvider<int?>((ref) => null);

final customerReportTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  // دریافت آیدی به جای نام
  final selectedId = ref.watch(selectedCustomerIdProvider);
  final dateRange = ref.watch(reportDateRangeProvider);

  if (selectedId == null) return const AsyncValue.data([]);

  return transactionsAsync.whenData((list) {
    return list.where((t) {
      // فیلتر ریشه‌ای بر اساس آیدی مشتری (حتی اگر نام تغییر کند، آیدی ثابت است)
      // نکته: مطمئن شوید در TransactionModel فیلد customerId را دارید
      final matchesCustomer = t.customerId == selectedId;

      bool matchesDate = true;
      if (dateRange != null) {
        try {
          final tDate = DateTime.parse(t.createdAt);
          final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
          final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
          matchesDate = tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              tDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) {
          matchesDate = false;
        }
      }
      return matchesCustomer && matchesDate;
    }).toList();
  });
});
// ۱. اصلاح ارور selectedCustomerNameProvider (تغییر به ID)

// ۲. اصلاح ارور todaySalesProvider (اطمینان از وجود تعریف)
// سایر پروایدرهای آماری
final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final all = await ref.watch(transactionsProvider.future);
  return all.take(5).toList();
});
// ۱. این پروایدر را به این شکل تغییر دهید تا همیشه به آخرین نسخه دیتای تراکنش‌ها گوش دهد
final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  // استفاده از watch به جای read بسیار حیاتی است
  final transactionsAsync = ref.watch(transactionsProvider);
  final query = ref.watch(transactionSearchQueryProvider).trim().toLowerCase();
  final customerType = ref.watch(filterCustomerTypeProvider);
  final operator = ref.watch(filterOperatorProvider);
  final dateRange = ref.watch(filterDateProvider);

  return transactionsAsync.whenData((list) {
    return list.where((t) {
      // فیلتر جستجو بر اساس نام، شماره یا کد شرکت
      final matchesQuery = query.isEmpty ||
          t.customerName.toLowerCase().contains(query) ||
          t.phoneNumber.contains(query) ||
          t.companyCode.toLowerCase().contains(query);

      final matchesType = customerType == null || t.customerType == customerType;
      final matchesOperator = operator == null || t.operator == operator;

      bool matchesDate = true;
      if (dateRange != null) {
        try {
          final tDate = DateTime.parse(t.createdAt);
          final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
          final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
          matchesDate = tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              tDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) { matchesDate = false; }
      }

      return matchesQuery && matchesType && matchesOperator && matchesDate;
    }).toList();
  });
});