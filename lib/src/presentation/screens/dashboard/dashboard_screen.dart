import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/invetory.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/sell_paper_card/paper_card_screen.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/send_credit/send_credit_screen.dart';
import '../../../domain/entity/transaction.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../services/internet_chek.dart';
import '../../../services/sync_service.dart';
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

final isSyncingProvider = StateProvider<bool>((ref) => false);
class DashboardScreen extends ConsumerWidget {
   DashboardScreen({super.key});

// در صفحه Home یا Settings
  // در فایل dashboard_screen.dart
  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(isSyncingProvider.notifier).state = true;

    try {
      bool hasInternet = await checkInternetConnection();

      if (hasInternet) {
        final syncService = SyncService();

        // ✅ اصلاح اصلی: به جای دو خط قبلی، فقط این خط را بنویسید
        await syncService.syncAll(user.shopId);

        _showSnackBar(context, "تمام اطلاعات با موفقیت همگام‌سازی شد ✅");
      } else {
        _showSnackBar(context, "اینترنت وصل نیست!", isError: true);
      }
    } catch (e) {
      _showSnackBar(context, "خطا: $e", isError: true);
    } finally {
      ref.read(isSyncingProvider.notifier).state = false;
    }
  }
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Vazir')),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
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
    final isSyncing=ref.watch(isSyncingProvider);
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
                    IconButton(
                      onPressed: isSyncing ? null : () => _handleSync(context, ref),
                      icon: isSyncing
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)
                      )
                          : const Icon(Icons.sync_rounded),
                      tooltip: "هماهنگ‌سازی با سرور",
                    ),
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
                    children: txns.map((t) => _buildRecentItem(t,   brandRed)).toList(),
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
              Navigator.push(context, MaterialPageRoute(builder: (context)=>InventoryScreen()));
              // رفرش دستی با دکمه Sync
              // اینجا چون به ref دسترسی نداریم (مگر اینکه پاس بدیم)، فعلا خالی می‌ماند
              // یا می‌توان یک VoidCallback برای رفرش پاس داد.
            },
            icon: const Icon(Icons.inventory, color: Colors.grey)
        ), IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>PaperTopupSalePage()));
              // رفرش دستی با دکمه Sync
              // اینجا چون به ref دسترسی نداریم (مگر اینکه پاس بدیم)، فعلا خالی می‌ماند
              // یا می‌توان یک VoidCallback برای رفرش پاس داد.
            },
            icon: const Icon(Icons.sell, color: Colors.grey)
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
            icon: const Icon(Icons.store, color: Colors.grey)
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
// ۱. تابع کمکی برای انتخاب آیکون بر اساس اپراتور و نوع تراکنش
// ۱. تابع کمکی برای انتخاب آیکون بر اساس اپراتور و نوع تراکنش

// ۲. اصلاح تابع اصلی ویجت تراکنش
  Widget _buildRecentItem(TransactionModel t, Color red) {
    // ۱. منطق انتخاب آیکون بر اساس اپراتور و نوع تراکنش
    Widget transactionIcon;

    // تبدیل نام اپراتور به حروف کوچک برای مقایسه دقیق‌تر
    String op = t.operator.toLowerCase();
    String assetPath = '';

    // تشخیص مسیر فایل SVG بر اساس نام اپراتور
    if (op.contains('awcc')) {
      assetPath = 'assets/svg/awcc.svg';
    } else if (op.contains('roshan')) {
      assetPath = 'assets/svg/roshan.svg';
    } else if (op.contains('etisalat')) {
      assetPath = 'assets/svg/etisalat.svg';
    } else if (op.contains('mtn') || op.contains('atoma')) {
      assetPath = 'assets/svg/atoma.svg';
    } else if (op.contains('salaam')) {
      assetPath = 'assets/svg/salaam.svg';
    }

    // انتخاب آیکون بر اساس نوع تراکنش
    if (t.transactionType == 'DIGITAL' && assetPath.isNotEmpty) {
      // برای تراکنش دیجیتال: لوگوی اپراتور
      transactionIcon = SvgPicture.asset(
        assetPath,
        width: 34,
        height: 34,
      );
    } else if (t.transactionType == 'PAPER' && assetPath.isNotEmpty) {
      // برای تراکنش کاغذی: لوگوی اپراتور
      transactionIcon = SvgPicture.asset(
        assetPath,
        width: 34,
        height: 34,
      );
    } else {
      // برای سایر موارد: آیکون پیش‌فرض رعد
      transactionIcon = Icon(Icons.bolt, color: red);
    }

    // ۲. ساختار ویجت (بقیه کد بدون تغییر)
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
                color: t.transactionType == 'PAPER'?Colors.white:red.withValues(alpha: 0.05),
                shape: BoxShape.circle
            ),
            child: Center(child: transactionIcon), // نمایش آیکون انتخاب شده
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    t.operator,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
                Text(
                    t.phoneNumber,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  "${t.receivedAmount}؋",
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const Text(
                  "موفق",
                  style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)
              ),
            ],
          )
        ],
      ),
    );
  } // Widget _buildRecentItem(TransactionModel t, bool isDark, Color red) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     padding: const  EdgeInsets.all(15),
  //     decoration: BoxDecoration(
  //       color: isDark ? const Color(0xFF2A1D1D) : Colors.white,
  //       borderRadius: BorderRadius.circular(18),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(width: 45, height: 45, decoration: BoxDecoration(color: red.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.bolt, color: red)),
  //         const SizedBox(width: 15),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(t.operator, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  //               Text(t.phoneNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  //             ],
  //           ),
  //         ),
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.end,
  //           children: [
  //             Text("${t.receivedAmount}؋", style: const TextStyle(fontWeight: FontWeight.bold)),
  //             const Text("موفق", style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
  //           ],
  //         )
  //       ],
  //     ),
  //   );
  // }

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