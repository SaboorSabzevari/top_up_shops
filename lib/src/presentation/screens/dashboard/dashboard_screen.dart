import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ایمپورت‌های پروژه خودتان (آدرس‌ها را بر اساس ساختار پروژه خود چک کنید)
import 'package:top_up_shops/src/presentation/screens/dashboard/invetory.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/sell_paper_card/paper_card_screen.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/send_credit/send_credit_screen.dart';
import '../../../domain/entity/transaction.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/sync_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../services/internet_chek.dart';
import '../../../services/sync_service.dart';
import '../transactions/transaction_screen.dart';
import 'buy_credit/buy_credit_screen.dart';

// --- Constants from Tailwind Config ---
class AppColors {
  static const primary = Color(0xFFEA2A33);
  static const dashboardBg = Color(0xFFF3F4F6); // bg-slate-100 equivalent
  static const cardBg = Colors.white;
  static const textMain = Color(0xFF1E293B); // slate-800
  static const textMuted = Color(0xFF64748B); // slate-500
  static const borderLight = Color(0xFFE2E8F0); // slate-200
}

class AppStyles {
  static final List<BoxShadow> customShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static const TextStyle fontVazir = TextStyle(fontFamily: 'Vazirmatn');
}

// --- Providers ---
final profileInfoProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('store_name') ?? 'فروشگاه من',
    'phone': prefs.getString('store_phone') ?? '---',
    'image': prefs.getString('store_image_path') ?? '',
  };
});


final isSyncingProvider = StateProvider<bool>((ref) => false);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(isSyncingProvider.notifier).state = true;

    try {
      bool hasInternet = await checkInternetConnection();
      if (hasInternet) {
        final syncService = SyncService();
        await syncService.syncAll(user.shopId);
        ref.invalidate(transactionsProvider);
        ref.invalidate(todaySalesProvider);
        ref.invalidate(todayProfitProvider);
        ref.invalidate(chartDataProvider);
        _showSnackBar(context, "همگام‌سازی موفق بود ✅");
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
        content: Text(message, style: AppStyles.fontVazir),
        backgroundColor: isError ? AppColors.primary : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Data Providers
    final summaryAsync = ref.watch(salesSummaryProvider);
    final todaySales = ref.watch(todaySalesProvider);
    final todayCount = ref.watch(todayCountProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);
    final profileAsync = ref.watch(profileInfoProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final double yesterdaySales = 4109285;
    final double percentChange = -53.96;
    final List<double> currentWeekData = [1200, 1000, 1500, 2200, 2600, 1900, 2400];
    final List<double> prevWeekData = [1000, 1400, 1100, 1900, 2100, 1600, 1800];

    final chartDataAsync = ref.watch(chartDataProvider);




    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(preferredSize: const Size.fromHeight(70), child:  Container(
          height: 110,

          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),

            ),),
          child:  _buildHeaderContent(context, ref, profileAsync, isSyncing),)),
        backgroundColor: AppColors.dashboardBg,
        body: Stack(
          children: [

            // 2. Scrollable Content
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(todaySalesProvider);
                  ref.invalidate(todayProfitProvider);
                  ref.refresh(profileInfoProvider);
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    children: [
                      // Header Content

                      const SizedBox(height: 10), // فاصله برای ایجاد افکت روی هم افتادن (-mt-10)

                      // Sales Chart Section
                    chartDataAsync.when(
                      data: (data) => _buildChartSection(data['current']!, data['prev']!),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text("خطا در بارگذاری نمودار"),
                    ),
                      // _buildChartSection(currentWeekData, prevWeekData),

                      const SizedBox(height: 16),
                   summaryAsync.when(
                    data: (data) => _buildSalesSummary(
                data['today'],
                data['yesterday'],
                data['percent'],
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text("خطا در بارگذاری اطلاعات"),
        ),
                      // Sales Summary Stats
                      // _buildSalesSummary(todaySales.value ?? 0, yesterdaySales, percentChange),

                      const SizedBox(height: 14),

                      // Quick Access Menu
                      _buildQuickAccessSection(context),

                      const SizedBox(height: 24),
                      _buildManagementSection(),
                      // Recent Transactions (Styled like Quick Actions/Chart)
                      // _buildTransactionsSection(context, recentTxns),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeaderContent(BuildContext context, WidgetRef ref, AsyncValue<Map<String, String>> profileAsync, bool isSyncing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // بخش آواتار
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: ClipOval(
                  child: profileAsync.when(
                    data: (data) {
                      final imagePath = data['image'];
                      if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
                        return Image.file(File(imagePath), fit: BoxFit.cover);
                      }
                      return const Icon(Icons.store, color: Colors.white, size: 28);
                    },
                    loading: () => const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    error: (_, __) => const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // بخش نام و زیرنویس
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileAsync.when(
                    data: (data) => Text(
                      data['name'] ?? "فروشگاه بدون نام",
                      style: AppStyles.fontVazir.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14
                      ),
                    ),
                    loading: () => Container(width: 80, height: 12, color: Colors.white24),
                    error: (_, __) => const Text("خطا در بارگذاری", style: TextStyle(color: Colors.white)),
                  ),
                  // نمایش دیتای واقعی به جای متن ثابت
                  profileAsync.when(
                    data: (data) => Text(
                      data['phone'] ?? "بدون شماره",
                      style: AppStyles.fontVazir.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
        // بخش سمت راست (Sync & More) که بدون تغییر می‌ماند...
IconButton(onPressed: () => _handleSync(context, ref), icon: isSyncing ? const CircularProgressIndicator(color: Colors.white,padding: EdgeInsets.all(10),): const Icon(Icons.sync, color: Colors.white)),
      ],
    );
  }
  // --- Chart Section ---
  Widget _buildChartSection(
      List<double> currentData,
      List<double> prevData,
      ) {
    const int daysCount = 7;

    List<double> normalize(List<double> data) {
      if (data.length >= daysCount) {
        return data.take(daysCount).toList();
      }
      return [
        ...data,
        ...List.filled(daysCount - data.length, 0),
      ];
    }

    final curr = normalize(currentData);
    final prev = normalize(prevData);
    final allData = [...curr, ...prev];

    double maxVal = 100;
    if (allData.isNotEmpty) {
      final calculatedMax =
      allData.reduce((a, b) => a > b ? a : b);
      if (calculatedMax > 0) {
        maxVal = calculatedMax;
      }
    }

    final double interval =
    (maxVal / 4).clamp(1, double.infinity);

    final today = DateTime.now();
    final lastUpdate = DateTime.now();

    const weekDays = [
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
      'شنبه',
      'یکشنبه',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallDevice = constraints.maxWidth < 360;

        final titleSize = isSmallDevice ? 14.0 : 16.0;
        final labelSize = isSmallDevice ? 8.0 : 10.0;
        final valueSize = isSmallDevice ? 7.0 : 8.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              /// ================= HEADER =================
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        "تحلیل فروش ۷ روز اخیر",
                        style: AppStyles.fontVazir
                            .copyWith(
                          fontSize: titleSize,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),

                      /// آخرین بروزرسانی
                      Text(
                        "آخرین بروزرسانی: "
                            "${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}",
                        style: AppStyles.fontVazir
                            .copyWith(
                          fontSize: labelSize,
                          color:
                          AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildLegendDot(
                            Colors.grey.shade500,
                            "هفته قبل",
                            labelSize,
                          ),
                          const SizedBox(width: 16),
                          _buildLegendDot(
                            AppColors.primary,
                            "هفته فعلی",
                            labelSize,
                          ),
                        ],
                      ),
                    ],
                  ),

                  /// تاریخ امروز
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(
                          12),
                    ),
                    child: Text(
                      "${today.day}/${today.month}/${today.year}",
                      style: AppStyles.fontVazir
                          .copyWith(
                        fontSize: labelSize,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              /// ================= CHART =================
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: maxVal * 1.2,

                    gridData: FlGridData(
                      show: true,
                      horizontalInterval:
                      interval,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                        color: AppColors
                            .textMuted
                            .withOpacity(0.08),
                        strokeWidth: 1,
                      ),
                    ),

                    borderData:
                    FlBorderData(show: false),

                    lineTouchData:
                    LineTouchData(
                      touchTooltipData:
                      LineTouchTooltipData(
                        tooltipBorderRadius:BorderRadius.circular(12),
                        tooltipPadding:
                        const EdgeInsets
                            .all(12),
                        getTooltipItems:
                            (spots) {
                          return spots.map(
                                  (spot) {
                                final isCurrent =
                                    spot.barIndex ==
                                        1;

                                return LineTooltipItem(
                                  "${isCurrent ? "این هفته" : "هفته قبل"}\n"
                                      "${spot.y.toStringAsFixed(0)}",
                                  const TextStyle(
                                    color:
                                    Colors.white,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                );
                              }).toList();
                        },
                      ),
                    ),

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles:
                        SideTitles(
                          showTitles: true,
                          interval:
                          interval,
                          reservedSize:
                          40,
                          getTitlesWidget:
                              (value,
                              meta) =>
                              Text(
                                value
                                    .toInt()
                                    .toString(),
                                style: AppStyles
                                    .fontVazir
                                    .copyWith(
                                  fontSize:
                                  labelSize,
                                  color:
                                  AppColors
                                      .textMuted,
                                ),
                              ),
                        ),
                      ),
                      rightTitles:
                      AxisTitles(
                          sideTitles:
                          SideTitles(
                              showTitles:
                              false)),
                      topTitles:
                      AxisTitles(
                          sideTitles:
                          SideTitles(
                              showTitles:
                              false)),
                      bottomTitles:
                      AxisTitles(
                        sideTitles:
                        SideTitles(
                          showTitles:
                          true,
                          interval: 1,
                          reservedSize:
                          50,
                          getTitlesWidget:
                              (value,
                              meta) {
                            if (value <
                                0 ||
                                value >
                                    6) {
                              return const SizedBox
                                  .shrink();
                            }

                            final date =
                            today.subtract(
                              Duration(
                                  days:
                                  6 -
                                      value
                                          .toInt()),
                            );

                            final isToday =
                                date.day ==
                                    today
                                        .day;

                            final dayName =
                            weekDays[
                            date.weekday -
                                1];

                            return SideTitleWidget(
                              meta: meta,
                              space: 10,
                              child: Column(
                                children: [
                                  Text(
                                    dayName,
                                    style: AppStyles
                                        .fontVazir
                                        .copyWith(
                                      fontSize:
                                      labelSize,
                                      fontWeight:
                                      isToday
                                          ? FontWeight
                                          .bold
                                          : FontWeight
                                          .normal,
                                      color:
                                      isToday
                                          ? AppColors
                                          .primary
                                          : AppColors
                                          .textMuted,
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                      4),
                                  Text(
                                    date.day
                                        .toString(),
                                    style:
                                    AppStyles
                                        .fontVazir
                                        .copyWith(
                                      fontSize:
                                      valueSize,
                                      color:
                                      AppColors
                                          .textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    lineBarsData: [

                      /// هفته قبل
                      LineChartBarData(
                        spots: prev
                            .asMap()
                            .entries
                            .map((e) =>
                            FlSpot(
                              e.key
                                  .toDouble(),
                              e.value,
                            ))
                            .toList(),
                        isCurved: true,
                        color:
                        Colors.grey.shade400,
                        barWidth: 2,
                        dotData:
                        FlDotData(
                            show: false),
                      ),

                      /// هفته فعلی
                      LineChartBarData(
                        spots: curr
                            .asMap()
                            .entries
                            .map((e) =>
                            FlSpot(
                              e.key
                                  .toDouble(),
                              e.value,
                            ))
                            .toList(),
                        isCurved: true,
                        color:
                        AppColors.primary,
                        barWidth: 3,
                        dotData:
                        FlDotData(
                          show: true,
                          getDotPainter:
                              (spot,
                              percent,
                              barData,
                              index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color:
                                Colors.white,
                                strokeWidth:
                                2,
                                strokeColor:
                                AppColors
                                    .primary,
                              ),
                        ),
                        belowBarData:
                        BarAreaData(
                          show: true,
                          color:
                          AppColors
                              .primary
                              .withOpacity(
                              0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(
      Color color,
      String text,
      double fontSize,
      ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppStyles.fontVazir.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: color == AppColors.primary
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }


  // --- Sales Summary Section ---
  Widget _buildSalesSummary(int today, double yesterday, double percentChange) {
    final isNegative = percentChange < 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("فروش امروز (افغانی)",today.toDouble(), )), // Mock decimal
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("فروش دیروز (افغانی)", yesterday,)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isNegative ? Icons.trending_down : Icons.trending_up,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                "${percentChange.abs().toStringAsFixed(2)}% ${isNegative ? 'کاهش' : 'افزایش'} نسبت به دیروز",
                style: AppStyles.fontVazir.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String title, double value) {
    // جدا کردن بخش صحیح و اعشار برای نمایش زیبا
    String mainValue = value.toInt().toString();
    String subValue = (value - value.toInt()).toStringAsFixed(2).substring(1); // گرفتن فقط بخش اعشار مثل .25

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.customShadow,
      ),
      child: Column(
        children: [
          Text(title, style: AppStyles.fontVazir.copyWith(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(mainValue, style: AppStyles.fontVazir.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain, height: 1.2)),
          // نمایش اعشار واقعی اگر بزرگتر از صفر بود، در غیر این صورت 00.
          ],
      ),
    );
  }
  // --- Quick Access Section ---
  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text("منوی دسترسی سریع",
                style: AppStyles.fontVazir.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8, // Adjusted for the card shape
          children: [
            _buildQuickActionCard(
              "فروش جدید",
              "فروش داشتید؟ ثبت کنید",
              Icons.add_shopping_cart,
              AppColors.primary,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalTopupSalePage())),
            ),
            _buildQuickActionCard(
              "خرید جدید",
              "خرید اعتبار برای دکان",
              Icons.input,
              Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())),
            ),
            _buildQuickActionCard(
              "فروش کاغذی",
              "فروش کارت فیزیکی",
              Icons.receipt_long,
              Colors.amber[700]!,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaperTopupSalePage())),
            ),
            _buildQuickActionCard(
              "انبار",
              "مدیریت موجودی",
              Icons.inventory_2_outlined,
              Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppStyles.customShadow,
        ),
        child: Row(
          children: [
            // Right border logic is simulated by Container decoration or Border widget
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: AppStyles.fontVazir.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.fontVazir.copyWith(fontSize: 9, color: AppColors.textMuted, height: 1.1)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            )
          ],
        ),
      ),
    );
  }

  // --- Recent Transactions ---
  Widget _buildTransactionsSection(BuildContext context, AsyncValue<List<TransactionModel>> transactions) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text("تراکنش‌های اخیر",
                    style: AppStyles.fontVazir.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryPage())),
              child: Text("مشاهده همه", style: AppStyles.fontVazir.copyWith(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        transactions.when(
          data: (txns) => ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txns.take(5).length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildTransactionItem(txns[index]);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text("خطا در دریافت اطلاعات", style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    // Logic from original code for icons
    String op = t.operator.toLowerCase();
    String? assetPath;
    Color iconBg = AppColors.primary.withOpacity(0.1);

    if (op.contains('awcc')) assetPath = 'assets/svg/awcc.svg';
    else if (op.contains('roshan')) assetPath = 'assets/svg/roshan.svg';
    else if (op.contains('etisalat')) assetPath = 'assets/svg/etisalat.svg';
    else if (op.contains('mtn') || op.contains('atoma')) assetPath = 'assets/svg/atoma.svg';
    else if (op.contains('salaam')) assetPath = 'assets/svg/salaam.svg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppStyles.customShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: t.transactionType == 'PAPER' ? Colors.grey.shade100 : iconBg,
              shape: BoxShape.circle,
            ),
            child: assetPath != null
                ? SvgPicture.asset(assetPath)
                : const Icon(Icons.bolt, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.operator, style: AppStyles.fontVazir.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                Text(_cleanPhoneNumberDisplay(t.phoneNumber),
                    style: AppStyles.fontVazir.copyWith(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${t.receivedAmount}؋", style: AppStyles.fontVazir.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const Text("موفق", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  String _cleanPhoneNumberDisplay(String rawPhone) {
    if (rawPhone.contains('{') || rawPhone.contains('phone_number')) {
      return rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    }
    return rawPhone;
  }
  // ---------------------------------------------------------------------------
  // بخش مدیریت لیست‌ها (اضافه شده از HTML)
  // ---------------------------------------------------------------------------

  Widget _buildManagementSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر بخش لیست‌ها
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "لیست‌ها",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      // color: از تم خوانده می‌شود
                    ),
                  ),
                  Text(
                    "مدیریت بخش‌های مختلف",
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              // دکمه سرچ کوچک (اختیاری)
            ],
          ),
          SizedBox(height: 15.h),

          // آیتم‌های لیست
          _buildManagementCard(
            title: "فروش‌ها",
            subtitle: "لیست فروش‌های ثبت شده",
            color: Colors.blue,
            onTap: () {
              // نویگیشن به صفحه فروش
            },
          ),
          _buildManagementCard(
            title: "خریدها",
            subtitle: "لیست خریدهای ثبت شده",
            color: Colors.red,
            onTap: () {},
          ),
          _buildManagementCard(
            title: "دریافتی‌ها",
            subtitle: "لیست دریافتی‌های ثبت شده",
            color: Colors.green,
            onTap: () {},
          ),
          _buildManagementCard(
            title: "پرداخت‌ها",
            subtitle: "لیست پرداخت‌های ثبت شده",
            color: Colors.orange,
            onTap: () {},
          ),
          _buildManagementCard(
            title: "پیش فاکتورها",
            subtitle: "لیست پیش‌فاکتورهای ثبت شده",
            color: Colors.grey,
            onTap: () {},
          ),
          _buildManagementCard(
            title: "لیست آخرین تغییرات",
            subtitle: "لیست اطلاعات ثبت/ویرایش شده",
            color: Colors.cyan,
            onTap: () {},
          ),

          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  // ویجت سازنده هر کارت (آیتم لیست)
  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
         elevation: 0,color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w), // کمی پدینگ کمتر نسبت به HTML برای موبایل
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                  color:  Colors.transparent
              ),
            ),
            child: Row(
              children: [
                // نوار رنگی سمت راست
                Container(
                  width: 5.w,
                  height: 35.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(4.r)), // در حالت RTL
                  ),
                ),
                SizedBox(width: 12.w),
                // متن‌ها
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // آیکون فلش
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}