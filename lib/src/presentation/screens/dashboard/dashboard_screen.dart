import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/sell_paper_card/paper_card_screen.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/send_credit/send_credit_screen.dart';
import '../../../domain/entity/transaction.dart';
import '../../../providers/transaction_provider.dart';
import '../transactions/transaction_screen.dart';
import 'buy_credit/buy_credit_screen.dart';
import 'database_view.dart';

final profileInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('store_name') ?? 'فروشگاه من',
    'image': prefs.getString('store_image_path') ?? '',
  };
});
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandRed = Color(0xFFEA2A33);
    final bgColor = isDark ? const Color(0xFF1A0D0D) : const Color(0xFFF8F6F6);

    // اشتراک در داده‌ها
    final todaySales = ref.watch(todaySalesProvider);
    final todayProfit = ref.watch(todayProfitProvider);
    final todayCount = ref.watch(todayCountProvider);
    final growth = ref.watch(salesGrowthProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);

    final profileAsync = ref.watch(profileInfoProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context,isDark, brandRed,profileAsync),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
            ref.invalidate(todaySalesProvider);
            ref.invalidate(todayProfitProvider);

            ref.refresh(profileInfoProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Row(
                  children: [
                    _buildMiniCard("تعداد امروز", "${todayCount.value ?? 0}", "عدد", isDark, brandRed),
                    const SizedBox(width: 10),
                    _buildMiniCard1("سود امروز", "${todayProfit.value ?? 0}", "افغانی", isDark, brandRed, highlight: true),
                  ],
                ),
                const SizedBox(height: 20),
                // کارت بزرگ فروش کل
                _buildMainSalesCard(todaySales.value ?? 0, growth.value ?? 0, isDark, brandRed),
                const SizedBox(height: 25),
                // دکمه عملیاتی اصلی
                _buildBigActionButton(brandRed,context),
                const SizedBox(height: 30),
                // هدر تراکنش‌های اخیر
                _buildSectionHeader("تراکنش‌های اخیر", brandRed,context),
                const SizedBox(height: 15),
                // لیست تراکنش‌ها
                recentTxns.when(
                  data: (txns) => Column(
                    children: txns.map((t) => _buildRecentItem(t, isDark, brandRed)).toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text("خطا در بارگذاری"),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
       );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context,bool isDark, Color red, AsyncValue<Map<String, String>> profileAsync) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [

          profileAsync.when(
            data: (data) {
              final imagePath = data['image'];
              final hasImage = imagePath != null && imagePath.isNotEmpty;
              return CircleAvatar(
                radius: 20,
                backgroundColor: red.withOpacity(0.1),
                // اگر عکس فایل وجود داشت، نشان بده
                backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
                // اگر عکس نبود، آیکون پیش‌فرض نشان بده
                child: hasImage ? null : Icon(Icons.store, color: red),
              );
            },
            loading: () => CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade200),
            error: (_, __) => CircleAvatar(radius: 20, backgroundColor: red.withOpacity(0.1), child: Icon(Icons.person, color: red)),
          ),

          const SizedBox(width: 12),

          // بخش متن (نام فروشگاه)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("مدیریت فروشگاه", style: TextStyle(fontSize: 10, color: Colors.grey)),

              profileAsync.when(
                data: (data) => Text(
                  data['name']!,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black
                  ),
                ),
                loading: () => Container(width: 80, height: 16, color: Colors.grey.shade200),
                error: (_, __) => Text("کاربر", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              ),
            ],
          )
        ],
      ),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>PaperTopupSalePage()));
              // رفرش دستی با دکمه Sync
              // اینجا چون به ref دسترسی نداریم (مگر اینکه پاس بدیم)، فعلا خالی می‌ماند
              // یا می‌توان یک VoidCallback برای رفرش پاس داد.
            },
            icon: const Icon(Icons.notifications_none, color: Colors.grey)
        ),
        const SizedBox(width: 10),  IconButton(
            onPressed: () {

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const DatabaseViewerScreen(),
                  //   ),
                  // );
              Navigator.push(context, MaterialPageRoute(builder: (context)=>PurchaseScreen()));
              // رفرش دستی با دکمه Sync
              // اینجا چون به ref دسترسی نداریم (مگر اینکه پاس بدیم)، فعلا خالی می‌ماند
              // یا می‌توان یک VoidCallback برای رفرش پاس داد.
            },
            icon: const Icon(Icons.notifications_none, color: Colors.grey)
        ),
      ],
    );
  }
  Widget _buildMiniCard(String title, String val, String unit, bool isDark, Color red, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1D1D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlight ? red.withOpacity(0.3) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: highlight ? red : (isDark ? Colors.white : Colors.black))),
               SizedBox(width: 7,), Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            ],
        ),
      ),
    );
  }
Widget _buildMiniCard1(String title, String val, String unit, bool isDark, Color red, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1D1D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlight ? red.withOpacity(0.3) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: highlight ? Colors.green : (isDark ? Colors.white : Colors.black))),
               SizedBox(width: 7,), Text(unit, style: const TextStyle(fontSize: 14, color: Colors.green)),
              ],
            ),
            ],
        ),
      ),
    );
  }

  Widget _buildMainSalesCard(int total, double growth, bool isDark, Color red) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1D1D) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: red.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text("کل فروش امروز", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 10),
          Text("$total افغانی", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("${growth.toStringAsFixed(1)}% افزایش نسبت به دیروز", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildBigActionButton(Color red,BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> DigitalTopupSalePage()));
      },
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_to_mobile, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text("ارسال کریدیت", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(TransactionModel t, bool isDark, Color red) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const  EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1D1D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(width: 45, height: 45, decoration: BoxDecoration(color: red.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.bolt, color: red)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.operator, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(t.phoneNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${t.receivedAmount}؋", style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text("موفق", style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color red, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>TransactionHistoryPage()));
            },
            child: Text("مشاهده همه", style: TextStyle(color: red, fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }
  
  }