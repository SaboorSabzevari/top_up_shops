import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      child: Scaffold(backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212).withOpacity(0.95) : Colors.white.withOpacity(0.95),
          elevation: 0,

          title: Text(
            'تاریخچه تراکنش‌ها',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle:  true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // ۱. ریفرش کردن لیست تراکنش‌ها
            ref.invalidate(transactionsProvider);
            // ۲. ریفرش کردن آمارهای بالای صفحه
            ref.invalidate(todayProfitProvider);
            ref.invalidate(todayCountProvider);

            // منتظر می‌مانیم تا دیتا لود شود (اختیاری اما برای تجربه کاربری بهتر)
            await ref.read(transactionsProvider.future);
          },
          child: Column(
            children: [
              _buildSummaryCards(todayProfitAsync, todayCountAsync),
              _buildSearchBar(ref, isDark),
              _buildFilterChips(context, ref, isDark),
              if (ref.watch(filterDateProvider) != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "گزارش از ${intl.DateFormat('yyyy/MM/dd').format(ref.watch(filterDateProvider)!.start)} تا ${intl.DateFormat('yyyy/MM/dd').format(ref.watch(filterDateProvider)!.end)}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Manrope'),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.read(filterDateProvider.notifier).state = null,
                        child: const Text("لغو فیلتر", style: TextStyle(fontSize: 10, color: Color(0xFFEA2A33))),
                      )
                    ],
                  ),
                ),
              Expanded(
                child: transactionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("خطا در بارگذاری: $err")),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      // نکته مهم: برای اینکه RefreshIndicator کار کند،
                      // حتی در حالت خالی هم باید یک لیست اسکرول‌شونده برگردانید
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text("تراکنشی یافت نشد")),
                        ],
                      );
                    }
                    return ListView.builder(
                      // این پارامتر باعث می‌شود حتی اگر لیست کوتاه باشد، قابلیت کشیدن به پایین کار کند
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      key: ValueKey(transactions.length + (transactions.isNotEmpty ? transactions.first.id : 0)),
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
              loading: () => _summaryBox("سود خالص امروز", "...", "",const Color(0xFF1E1E1E), textColor: Colors.white, subTextColor: Colors.white),
              error: (_, __) => _summaryBox("سود خالص امروز", "خطا","", const Color(0xFF1E1E1E), textColor: Colors.white, subTextColor: Colors.white),
              data: (value) => _summaryBox("سود خالص امروز", value.toString(), "افغانی",const Color(0xFF1E1E1E), textColor: Colors.white, subTextColor: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: count.when(
              loading: () => _summaryBox("تعداد تراکنش امروز", "...", "",const Color(0xFFEA2A33), textColor: Colors.white, subTextColor: Colors.white),
              error: (_, __) => _summaryBox("تعداد تراکنش امروز", "خطا", "",const Color(0xFFEA2A33), textColor: Colors.white, subTextColor:Colors.white),
              data: (value) => _summaryBox("تعداد تراکنش امروز", value.toString(), "تراکنش",const Color(0xFFEA2A33), textColor: Colors.white, subTextColor: Colors.white),
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

    String identityValue;
    IconData identityIcon;

    if (t.customerType == 'bulk') {

      // در متد saveDetailedTransaction، کد شرکت در فیلد company_code ذخیره می‌شود
      identityValue = t.companyCode.isNotEmpty ? t.companyCode : '---';
      identityIcon = Icons.business;
    } else {

      // در متد saveDetailedTransaction، شماره تماس در فیلد phone_number ذخیره می‌شود
      identityValue = t.phoneNumber;
      identityIcon = Icons.smartphone;
    }

    return _buildTransactionCard(
      context,
      name: t.customerName,
      type: t.customerType == 'bulk' ? "مشتری عمده" : "مشتری عادی",

      identityValue: identityValue,
      identityIcon: identityIcon,
      time: formattedTime,
      operator: t.operator,
      sent: t.sentAmount.toString(),
      received: t.receivedAmount.toString(),
    );
  }

  Widget _buildTransactionCard(BuildContext context, {
    required String name,
    required String type,
    required String identityValue,
    required IconData identityIcon,
    required String time,
    required String operator,
    required String sent,
    required String received,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color brandRed = Color(0xFFEA2A33);
    const Color darkCard = Color(0xFF1E1E1E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // فاصله عمودی کمتر
      decoration: BoxDecoration(
        color: isDark ? darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight( // تنظیم ارتفاع بر اساس محتوا
          child: Row(
            children: [
              // نوار رنگی کناری باریک‌تر
              Container(width: 3, color: brandRed),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      // ردیف اصلی: نام و مبلغ دریافتی
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // سایز کمی کوچکتر برای جا شدن بیشتر
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 6),
                                _buildBadge(type, isDark),
                              ],
                            ),
                          ),
                          Row(
                            children: [ _compactInfo(operator, isDark),
                              SizedBox(width: 10,),
                              Text(
                                "$received ؋",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: brandRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ردیف دوم: جزئیات در یک خط (Inline)
                      Row(
                        children: [
                          Icon(identityIcon, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            identityValue,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const Spacer(),
                          // اطلاعات تکمیلی به صورت فشرده

                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ویجت کمکی برای نمایش نوع مشتری (بسیار کوچک)
  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.red.shade500,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text == 'bulk' ? "عمده" : "عادی",
        style: TextStyle(
          fontSize: 8,
          color: isDark ? Colors.white60 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

// نمایش اپراتور به صورت متن ساده و خاکستری برای شلوغ نشدن
  Widget _compactInfo(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      ),
    );
  }
  Widget _buildDetailItem(String label, String value, {Color? dotColor, bool isLeft = false, Color? textColor}) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
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
      child: Container(decoration:BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(12)
      ),


        child: TextField(
          textDirection: TextDirection.ltr,
          cursorColor: kPrimaryColor,
          onChanged: (value) => ref.read(transactionSearchQueryProvider.notifier).state = value,
          decoration: InputDecoration(
            hintText: "جستجو (نام، شماره، کد شرکت)...",
            prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
            // ... بقیه استایل‌ها
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none
            )
          ),
        ),
      ),
    );
  }

  // اضافه کردن BuildContext به ورودی متد
  Widget _buildFilterChips(BuildContext context, WidgetRef ref, bool isDark) {
    final currentType = ref.watch(filterCustomerTypeProvider);
    const Color brandRed = Color(0xFFEA2A33);

    Widget buildChip(String label, String? value) {
      bool isSelected = currentType == value;

      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => ref.read(filterCustomerTypeProvider.notifier).state = value,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
          ),
          selectedColor: brandRed,
          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? brandRed : Colors.transparent),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          buildChip("همه", null),
          buildChip("عادی", 'normal'),
          buildChip("عمده", 'bulk'),
          const SizedBox(width: 8),

          // بخش تقویم
          // در متد _buildFilterBar یا بخشی که آیکون تقویم قرار دارد:
          IconButton(
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                initialDateRange: ref.read(filterDateProvider),
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFFEA2A33),
                        onPrimary: Colors.white,
                        onSurface: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                ref.read(filterDateProvider.notifier).state = picked;
              }
            },
            icon: Icon(
              Icons.date_range_rounded, // تغییر آیکون به بازه زمانی
              color: ref.watch(filterDateProvider) != null ? kPrimaryColor : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}