import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // اضافه کردن ScreenUtil
import '../../../domain/entity/transaction.dart';
import '../../../providers/transaction_provider.dart';
import 'package:intl/intl.dart' as intl;

// تعریف رنگ‌ها در صورت عدم دسترسی به فایل colors.dart
const Color kPrimaryColor = Color(0xFFEA2A33);

class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // مقداردهی اولیه ScreenUtil
    ScreenUtil.init(context, designSize: const Size(360, 800));

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final todayProfitAsync = ref.watch(todayProfitProvider);
    final todayCountAsync = ref.watch(todayCountProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF121212).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          elevation: 0,
          title: Text(
            'تاریخچه تراکنش‌ها',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp, // ریسپانسیو کردن فونت
            ),
          ),
          centerTitle: true,
          toolbarHeight: 60.h, // ریسپانسیو کردن ارتفاع appBar
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
            ref.invalidate(todayProfitProvider);
            ref.invalidate(todayCountProvider);
            await ref.read(transactionsProvider.future);
          },
          child: Column(
            children: [
              _buildSummaryCards(todayProfitAsync, todayCountAsync),
              SizedBox(height: 8.h), // فاصله ریسپانسیو
              _buildSearchBar(ref, isDark),
              SizedBox(height: 8.h), // فاصله ریسپانسیو
              _buildFilterChips(context, ref, isDark),
              if (ref.watch(filterDateProvider) != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w, // ریسپانسیو
                    vertical: 8.h, // ریسپانسیو
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_toggle_off,
                          size: 14.sp, // ریسپانسیو
                          color: Colors.grey),
                      SizedBox(width: 4.w), // ریسپانسیو
                      Expanded(
                        child: Text(
                          "گزارش از ${intl.DateFormat('yyyy/MM/dd').format(ref.watch(filterDateProvider)!.start)} تا ${intl.DateFormat('yyyy/MM/dd').format(ref.watch(filterDateProvider)!.end)}",
                          style: TextStyle(
                            fontSize: 10.sp, // ریسپانسیو
                            color: Colors.grey,
                            fontFamily: 'Manrope',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w), // ریسپانسیو
                      GestureDetector(
                        onTap: () => ref.read(filterDateProvider.notifier).state = null,
                        child: Text(
                            "لغو فیلتر",
                            style: TextStyle(
                                fontSize: 10.sp, // ریسپانسیو
                                color: const Color(0xFFEA2A33)
                            )
                        ),
                      )
                    ],
                  ),
                ),
              SizedBox(height: 8.h), // فاصله ریسپانسیو
              Expanded(
                child: transactionsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w, // ریسپانسیو کردن ضخامت
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        "خطا در بارگذاری: $err",
                        style: TextStyle(fontSize: 14.sp), // ریسپانسیو
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 100.h), // ریسپانسیو
                          Center(
                            child: Text(
                              "تراکنشی یافت نشد",
                              style: TextStyle(
                                fontSize: 16.sp, // ریسپانسیو
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 100.h), // ریسپانسیو
                      key: ValueKey(transactions.length +
                          (transactions.isNotEmpty ? transactions.first.id : 0)),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 8.h : 0, // ریسپانسیو
                            bottom: 4.h, // ریسپانسیو
                          ),
                          child: _buildTransactionCardFromModel(context, t),
                        );
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
      padding: EdgeInsets.all(16.w), // ریسپانسیو
      child: Row(
        children: [
          Expanded(
            child: profit.when(
              loading: () => _summaryBox(
                  "سود خالص امروز",
                  "...",
                  "",
                  const Color(0xFF1E1E1E),
                  textColor: Colors.white,
                  subTextColor: Colors.white
              ),
              error: (_, __) => _summaryBox(
                  "سود خالص امروز",
                  "خطا",
                  "",
                  const Color(0xFF1E1E1E),
                  textColor: Colors.white,
                  subTextColor: Colors.white
              ),
              data: (value) => _summaryBox(
                  "سود خالص امروز",
                  value.toString(),
                  "افغانی",
                  const Color(0xFF1E1E1E),
                  textColor: Colors.white,
                  subTextColor: Colors.white
              ),
            ),
          ),
          SizedBox(width: 12.w), // ریسپانسیو
          Expanded(
            child: count.when(
              loading: () => _summaryBox(
                  "تعداد تراکنش امروز",
                  "...",
                  "",
                  const Color(0xFFEA2A33),
                  textColor: Colors.white,
                  subTextColor: Colors.white
              ),
              error: (_, __) => _summaryBox(
                  "تعداد تراکنش امروز",
                  "خطا",
                  "",
                  const Color(0xFFEA2A33),
                  textColor: Colors.white,
                  subTextColor: Colors.white
              ),
              data: (value) => _summaryBox(
                  "تعداد تراکنش امروز",
                  value.toString(),
                  "تراکنش",
                  const Color(0xFFEA2A33),
                  textColor: Colors.white,
                  subTextColor: Colors.white
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String title, String amount, String amountType, Color bgColor,
      {required Color textColor, required Color subTextColor}) {
    return Container(
      padding: EdgeInsets.all(16.w), // ریسپانسیو
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r) // ریسپانسیو
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              title,
              style: TextStyle(
                  color: subTextColor,
                  fontSize: 11.sp // ریسپانسیو
              )
          ),
          SizedBox(height: 4.h), // ریسپانسیو
          FittedBox(
            child: Row(
              children: [
                Text(
                    amount,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp // ریسپانسیو
                    )
                ),
                SizedBox(width: 4.w), // ریسپانسیو
                Text(
                    amountType,
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 10.sp // ریسپانسیو
                    )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionCardFromModel(BuildContext context, TransactionModel t) {
    String formattedTime = t.createdAt;
    try {
      final dateTime = DateTime.parse(t.createdAt);
      formattedTime = intl.DateFormat('yyyy-MM-dd – kk:mm').format(dateTime);
    } catch (e) {
      // اگر فرمت تاریخ صحیح نبود، همان رشته اصلی نمایش داده می‌شود
    }

    String identityValue;
    IconData identityIcon;

    if (t.customerType == 'bulk') {
      identityValue = t.companyCode.isNotEmpty ? t.companyCode : '---';
      identityIcon = Icons.business;
    } else {
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
      margin: EdgeInsets.symmetric(
          horizontal: 16.w, // ریسپانسیو
          vertical: 4.h // ریسپانسیو
      ),
      decoration: BoxDecoration(
        color: isDark ? darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade200,
          width: 0.5.w, // ریسپانسیو
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
        child: IntrinsicHeight(
          child: Row(
            children: [
              // نوار رنگی کناری
              Container(
                width: 3.w, // ریسپانسیو
                color: brandRed,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, // ریسپانسیو
                      vertical: 8.h // ریسپانسیو
                  ),
                  child: Column(
                    children: [
                      // ردیف اصلی: نام و مبلغ دریافتی
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp, // ریسپانسیو
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 6.w), // ریسپانسیو
                                _buildBadge(type, isDark),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w), // ریسپانسیو
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _compactInfo(operator, isDark),
                              SizedBox(height: 4.h), // ریسپانسیو
                              Text(
                                "$received ؋",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.sp, // ریسپانسیو
                                  color: brandRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h), // ریسپانسیو
                      // ردیف دوم: جزئیات
                      Row(
                        children: [
                          Icon(
                              identityIcon,
                              size: 12.sp, // ریسپانسیو
                              color: Colors.grey
                          ),
                          SizedBox(width: 4.w), // ریسپانسیو
                          Expanded(
                            child: Text(
                              identityValue,
                              style: TextStyle(
                                  fontSize: 11.sp, // ریسپانسیو
                                  color: Colors.grey
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w), // ریسپانسیو
                          Text(
                            time,
                            style: TextStyle(
                                fontSize: 10.sp, // ریسپانسیو
                                color: Colors.grey
                            ),
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

  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 4.w, // ریسپانسیو
          vertical: 1.h // ریسپانسیو
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.red.shade500,
        borderRadius: BorderRadius.circular(3.r), // ریسپانسیو
      ),
      child: Text(
        text == 'bulk' ? "عمده" : "عادی",
        style: TextStyle(
          fontSize: 8.sp, // ریسپانسیو
          color: isDark ? Colors.white60 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _compactInfo(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 6.w, // ریسپانسیو
          vertical: 1.h // ریسپانسیو
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.grey.shade200,
          width: 0.5.w, // ریسپانسیو
        ),
        borderRadius: BorderRadius.circular(4.r), // ریسپانسیو
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 9.sp, // ریسپانسیو
            color: Colors.grey
        ),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 16.w, // ریسپانسیو
          vertical: 8.h // ریسپانسیو
      ),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12.r) // ریسپانسیو
        ),
        child: TextField(
          textDirection: TextDirection.ltr,
          cursorColor: kPrimaryColor,
          cursorWidth: 1.5.w, // ریسپانسیو
          onChanged: (value) =>
          ref.read(transactionSearchQueryProvider.notifier).state = value,
          decoration: InputDecoration(
            hintText: "جستجو (نام، شماره، کد شرکت)...",
            hintStyle: TextStyle(
                fontSize: 14.sp, // ریسپانسیو
                color: Colors.grey.shade600
            ),
            prefixIcon: Icon(
              Icons.search,
              color: kPrimaryColor,
              size: 20.sp, // ریسپانسیو
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
                borderSide: BorderSide.none
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w, // ریسپانسیو
                vertical: 14.h // ریسپانسیو
            ),
          ),
          style: TextStyle(
            fontSize: 14.sp, // ریسپانسیو
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, bool isDark) {
    final currentType = ref.watch(filterCustomerTypeProvider);
    const Color brandRed = Color(0xFFEA2A33);

    Widget buildChip(String label, String? value) {
      bool isSelected = currentType == value;

      return Padding(
        padding: EdgeInsets.only(left: 8.w), // ریسپانسیو
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp, // ریسپانسیو
            ),
          ),
          selected: isSelected,
          onSelected: (_) =>
          ref.read(filterCustomerTypeProvider.notifier).state = value,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12.sp, // ریسپانسیو
          ),
          selectedColor: brandRed,
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade100,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
            side: BorderSide(
              color: isSelected ? brandRed : Colors.transparent,
              width: 1.w, // ریسپانسیو
            ),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: 12.w, // ریسپانسیو
              vertical: 4.h // ریسپانسیو
          ),
          labelPadding: EdgeInsets.symmetric(
              horizontal: 4.w // ریسپانسیو
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
          horizontal: 16.w, // ریسپانسیو
          vertical: 8.h // ریسپانسیو
      ),
      child: Row(
        children: [
          buildChip("همه", null),
          buildChip("عادی", 'normal'),
          buildChip("عمده", 'bulk'),
          SizedBox(width: 8.w), // ریسپانسیو
          // بخش تقویم
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
              Icons.date_range_rounded,
              color: ref.watch(filterDateProvider) != null
                  ? kPrimaryColor
                  : Colors.grey,
              size: 20.sp, // ریسپانسیو
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r) // ریسپانسیو
              ),
              padding: EdgeInsets.all(8.w), // ریسپانسیو
            ),
          ),
        ],
      ),
    );
  }
}