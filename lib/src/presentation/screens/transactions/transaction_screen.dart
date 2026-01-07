// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../domain/entity/transaction.dart';
// import '../../../providers/transaction_provider.dart';
//
//
// /// ===============================
// /// MODEL
// /// ===============================
//
// /// ===============================
// /// REPOSITORY
// /// ===============================
//
//
// /// ===============================
// /// PROVIDERS
//
//
// /// ===============================
// /// PAGE
// /// ===============================
// class TransactionsPage extends ConsumerWidget {
//   const TransactionsPage({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final transactions = ref.watch(transactionsProvider);
//     final todayProfit = ref.watch(todayProfitProvider);
//     final walletBalance = ref.watch(walletBalanceProvider);
//
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("تاریخچه تراکنش‌ها"),
//           centerTitle: true,
//         ),
//         body: Column(
//           children: [
//             /// SUMMARY
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   _summaryCard(
//                     title: "سود امروز",
//                     asyncValue: todayProfit,
//                     color: Colors.black,
//                   ),
//                   const SizedBox(width: 12),
//                   _summaryCard(
//                     title: "موجودی صندوق",
//                     asyncValue: walletBalance,
//                     color: Colors.red,
//                   ),
//                 ],
//               ),
//             ),
//
//             /// LIST
//             Expanded(
//               child: transactions.when(
//                 loading: () =>
//                 const Center(child: CircularProgressIndicator()),
//                 error: (e, _) => Center(child: Text(e.toString())),
//                 data: (list) {
//                   if (list.isEmpty) {
//                     return const Center(
//                       child: Text("هیچ تراکنشی وجود ندارد"),
//                     );
//                   }
//
//                   return ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//
//                     itemCount: list.length,
//                     itemBuilder: (context, index) {
//                         final t = list[index];
//                         return _transactionCard(t);
//                       },
//
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// ===============================
//   /// UI PARTS
//   /// ===============================
//   Widget _summaryCard({
//     required String title,
//     required AsyncValue<int> asyncValue,
//     required Color color,
//   }) {
//     return Expanded(
//       child: asyncValue.when(
//         loading: () => _card(title, "...", color),
//         error: (_, __) => _card(title, "خطا", color),
//         data: (value) => _card(title, "$value ؋", color),
//       ),
//     );
//   }
//
//   Widget _card(String title, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style:
//               const TextStyle(color: Colors.white70, fontSize: 12)),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _transactionCard(TransactionModel t) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border:
//         const Border(right: BorderSide(color: Colors.green, width: 4)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(t.customerName,
//               style:
//               const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//           const SizedBox(height: 4),
//           Text(t.phone,
//               style: const TextStyle(fontSize: 12, color: Colors.grey)),
//           const Divider(),
//           _row("اپراتور", t.operator),
//           _row("ارسال شده", "${t.sentAmount} ؋"),
//           _row("دریافت شده", "${t.receivedAmount} ؋"),
//           _row("سود", "+${t.profit} ؋", highlight: true),
//         ],
//       ),
//     );
//   }
//
//   Widget _row(String label, String value, {bool highlight = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: const TextStyle(fontSize: 12, color: Colors.grey)),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: highlight ? Colors.green : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_up_shops/src/presentation/theme/colors.dart';
import '../../../domain/entity/transaction.dart'; // آدرس مدل تراکنش شما
import '../../../providers/transaction_provider.dart'; // آدرس پرووایدرهای شما
import 'package:intl/intl.dart' as intl; // برای فرمت تاریخ

// تعریف رنگ‌ها در صورت عدم دسترسی به فایل colors.dart
const Color kPrimaryColor = Color(0xFFEA2A33);

class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final todayProfitAsync = ref.watch(todayProfitProvider);
    final todayCountAsync = ref.watch(todayCountProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212).withOpacity(0.95) : Colors.white.withOpacity(0.95),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تاریخچه تراکنش‌ها',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle:  true,
        ),
        body: Column(
          children: [
            _buildSummaryCards(todayProfitAsync, todayCountAsync),
            _buildSearchBar(ref, isDark),
            _buildFilterChips(ref, isDark),

            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("خطا در بارگذاری: $err")),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(child: Text("تراکنشی یافت نشد"));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return _buildTransactionCardFromModel(context, t);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AsyncValue<int> profit, AsyncValue<int> count) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: profit.when(
              loading: () => _summaryBox("سود خالص امروز", "...", "",const Color(0xFF1E1E1E), textColor: Colors.white, subTextColor: Colors.red),
              error: (_, __) => _summaryBox("سود خالص امروز", "خطا","", const Color(0xFF1E1E1E), textColor: Colors.white, subTextColor: Colors.red),
              data: (value) => _summaryBox("سود خالص امروز", value.toString(), "افغانی",const Color(0xFF1E1E1E), textColor: Colors.white, subTextColor: const Color(0xFFEA2A33)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: count.when(
              loading: () => _summaryBox("تعداد تراکنش امروز", "...", "",const Color(0xFFEA2A33), textColor: Colors.white, subTextColor: Colors.white70),
              error: (_, __) => _summaryBox("تعداد تراکنش امروز", "خطا", "",const Color(0xFFEA2A33), textColor: Colors.white, subTextColor: Colors.white70),
              data: (value) => _summaryBox("تعداد تراکنش امروز", value.toString(), "تراکنش",const Color(0xFFEA2A33), textColor: Colors.white, subTextColor: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
  Widget _summaryBox(String title, String amount,String amountType, Color bgColor, {required Color textColor, required Color subTextColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            child: Row(
              children: [
                Text(amount, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 4),
                Text(amountType, style: TextStyle(color: subTextColor, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // کارت تراکنش بر اساس مدل داده‌ای
  Widget _buildTransactionCardFromModel(BuildContext context, TransactionModel t) {
    // فرمت تاریخ
    String formattedTime = t.createdAt;
    try {
      final dateTime = DateTime.parse(t.createdAt);
      formattedTime = intl.DateFormat('yyyy-MM-dd – kk:mm').format(dateTime);
    } catch (e) {
      // اگر فرمت تاریخ صحیح نبود، همان رشته اصلی نمایش داده می‌شود
    }

    // تعیین عنوان شناسه (شماره تماس یا کد شرکت)
    String identityLabel;
    String identityValue;
    IconData identityIcon;

    if (t.customerType == 'bulk') {
      identityLabel = "کد شرکت";
      // در متد saveDetailedTransaction، کد شرکت در فیلد company_code ذخیره می‌شود
      identityValue = t.companyCode.isNotEmpty ? t.companyCode : '---';
      identityIcon = Icons.business;
    } else {
      identityLabel = "شماره تماس";
      // در متد saveDetailedTransaction، شماره تماس در فیلد phone_number ذخیره می‌شود
      identityValue = t.phoneNumber;
      identityIcon = Icons.smartphone;
    }

    return _buildTransactionCard(
      context,
      name: t.customerName,
      type: t.customerType == 'bulk' ? "مشتری عمده" : "مشتری عادی",
      identityLabel: identityLabel,
      identityValue: identityValue,
      identityIcon: identityIcon,
      time: formattedTime,
      operator: t.operator,
      profit: t.profit.toString(),
      sent: t.sentAmount.toString(),
      received: t.receivedAmount.toString(),
    );
  }

  // متد UI کارت تراکنش
  Widget _buildTransactionCard(BuildContext context, {
    required String name,
    required String type,
    required String identityLabel, // برچسب (شماره تماس یا کد شرکت)
    required String identityValue, // مقدار (شماره یا کد)
    required IconData identityIcon, // آیکون مرتبط
    required String time,
    required String operator,
    required String profit,
    required String sent,
    required String received,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          // نوار رنگی سمت راست (نشان دهنده وضعیت - فعلا ثابت سبز/قرمز فرض شده)
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: Container(
              width: 5,
              decoration: const BoxDecoration(
                color: kPrimaryColor, // رنگ ثابت، می‌توان بر اساس وضعیت تغییر داد
                borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // هدر کارت: نام، نوع مشتری و زمان
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(type, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        // نمایش شرطی: شماره تماس یا کد شرکت
                        Row(
                          children: [
                            Icon(identityIcon, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "$identityLabel: $identityValue",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textDirection: TextDirection.ltr, // برای نمایش بهتر اعداد
                            ),
                          ],
                        )
                      ],
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // بدنه کارت: جزئیات تراکنش
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem("اپراتور", operator, dotColor: kPrimaryColor),
                          _buildDetailItem("سود تراکنش", "$profit ؋", isLeft: true, textColor: const Color(0xFFEA2A33)),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildRowDetail("مقدار ارسال شده:", "$sent ؋"),
                      _buildRowDetail("مبلغ دریافت شده:", "$received ؋"),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? dotColor, bool isLeft = false, Color? textColor}) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isLeft) Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            if (dotColor != null && !isLeft) const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
          ],
        )
      ],
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) => ref.read(transactionSearchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: "جستجو (نام، شماره، کد شرکت)...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          // ... بقیه استایل‌ها
        ),
      ),
    );
  }
  Widget _buildFilterChips(WidgetRef ref, bool isDark) {
    final currentType = ref.watch(filterCustomerTypeProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text("همه"),
            selected: currentType == null,
            onSelected: (_) => ref.read(filterCustomerTypeProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text("عادی"),
            selected: currentType == 'normal',
            onSelected: (_) => ref.read(filterCustomerTypeProvider.notifier).state = 'normal',
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text("عمده"),
            selected: currentType == 'bulk',
            onSelected: (_) => ref.read(filterCustomerTypeProvider.notifier).state = 'bulk',
          ),
          // می‌توانید فیلتر تاریخ را هم با یک IconButton و showDatePicker اینجا اضافه کنید
        ],
      ),
    );
  }
}