// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../data/local/app_database.dart';
// import '../domain/entity/transaction.dart';
//
// // پیشنهادی برای اضافه کردن به لایه Provider جهت سهولت در UI
// Future<bool> submitTransaction(WidgetRef ref, Map<String, dynamic> formData) async {
//   // ۱. بررسی اعتبار تراکنش بر اساس نوع مشتری و شرکت (طبق سناریوی شما)
//   bool isValid = isTransactionValid(
//     customerType: formData['customer_type'],
//     selectedCustomerCompanyType: formData['selected_company_type'],
//     selectedProviderType: formData['provider_type'],
//   );
//
//   if (!isValid) {
//     // نمایش پیام خطا در UI که نوع شرکت ها یکی نیست
//     return false;
//   }
//
//   // ۲. ارسال به دیتابیس برای ذخیره دائمی
//   try {
//     await DatabaseHelper.instance.addTransaction(formData);
//     return true; // ذخیره با موفقیت انجام شد
//   } catch (e) {
//     return false; // خطای دیتابیس
//   }
// }
// // منطق تطبیق نوع شرکت (Roshan به Roshan)
// bool isTransactionValid({
//   required String customerType,
//   required String? selectedCustomerCompanyType,
//   required String selectedProviderType,
// }) {
//   if (customerType == 'ORDINARY') return true;
//   return selectedCustomerCompanyType == selectedProviderType;
// }
//
// // سرویس ثبت نهایی
// final transactionServiceProvider = Provider((ref) => TransactionService());
//
// class TransactionService {
//   Future<String?> processAndSave({
//     required Map<String, dynamic> customerFullInfo, // اطلاعاتی که از AJAX گرفتی
//     required dynamic selectedProvider, // پروایدر انتخاب شده
//     required double amount,
//     required double discount,
//     required double paid,
//     required String method,
//     String? selectedCompanyTypeForWholesale, // مخصوص مشتری عمده
//   }) async {
//
//     // ۱. بررسی اعتبار نوع شرکت
//     bool valid = isTransactionValid(
//       customerType: customerFullInfo['type'],
//       selectedCustomerCompanyType: selectedCompanyTypeForWholesale,
//       selectedProviderType: selectedProvider.type,
//     );
//
//     if (!valid) return "نوع شرکت مشتری با پروایدر انتخاب شده همخوانی ندارد!";
//
//     // ۲. محاسبات مالی
//     double total = amount - discount;
//     double currentRemaining = total - paid;
//
//     // ۳. آماده‌سازی تاریخ و زمان
//     DateTime now = DateTime.now();
//     String date = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
//     String time = "${now.hour}:${now.minute}";
//
//     // ۴. تعیین مقصد (شماره یا کد شرکت)
//     String destination = customerFullInfo['type'] == 'ORDINARY'
//         ? "شماره پیش‌فرض" // اینجا باید شماره انتخابی از لیست پاس داده شود
//         : "کد شرکت عمده";
//
//     // ۵. ایجاد آبجکت تراکنش
//     final newTxn = TransactionEntity(
//       customerId: customerFullInfo['id'],
//       customerName: customerFullInfo['name'],
//       customerCode: customerFullInfo['customer_code'],
//       customerType: customerFullInfo['type'],
//       providerId: selectedProvider.id,
//       providerName: selectedProvider.name,
//       targetDestination: destination,
//       providerUsedCode: customerFullInfo['type'] == 'ORDINARY' ? selectedProvider.ordinaryCode : selectedProvider.wholesaleCode,
//       creditAmount: amount,
//       discount: discount,
//       totalAmount: total,
//       paidAmount: paid,
//       remainingAmount: currentRemaining,
//       communicationMethod: method,
//       transactionDate: date,
//       transactionTime: time,
//     );
//
//     // ۶. ذخیره در دیتابیس
//     await DatabaseHelper.instance.insertFullTransaction(newTxn);
//     return null; // یعنی موفقیت‌آمیز بود
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/repository/transaction_repository.dart';
import '../domain/entity/transaction.dart';

final transactionRepositoryProvider =
Provider((ref) => TransactionRepository());

final transactionsProvider =
FutureProvider<List<TransactionModel>>((ref) {
  return ref.read(transactionRepositoryProvider).getTransactions();
});

final todayProfitProvider = FutureProvider<int>((ref) {
  return ref.read(transactionRepositoryProvider).todayProfit();
});

final walletBalanceProvider = FutureProvider<int>((ref) {
  return ref.read(transactionRepositoryProvider).walletBalance();
});
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

// پرووایدر بهینه برای فیلتر کردن لیست
final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  // گوش دادن به لیست اصلی تراکنش‌ها که از دیتابیس می‌آید
  final transactionsAsync = ref.watch(transactionsProvider);

  // گوش دادن به متن جستجو
  final query = ref.watch(transactionSearchQueryProvider).trim().toLowerCase();

  // استفاده از .whenData برای تغییر محتویات بدون خروج از حالت AsyncValue
  return transactionsAsync.whenData((transactions) {
    if (query.isEmpty) return transactions;

    // عملیات فیلتر کردن در حافظه (بسیار سریع)
    return transactions.where((t) {
      final name = t.customerName.toLowerCase();
      final phone = t.phoneNumber;
      final code = t.companyCode.toLowerCase();

      return name.contains(query) ||
          phone.contains(query) ||
          code.contains(query);
    }).toList();
  });
});