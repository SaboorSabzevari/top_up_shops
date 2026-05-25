import 'dart:developer' as developer;



import 'package:path/path.dart';

import '../data/local/app_database.dart';

class CalculationService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // کش برای ذخیره موقت تنظیمات
  Map<String, dynamic>? _cachedUnitSettings;
  DateTime? _lastCacheTime;

  // سینگلتون الگو
  static final CalculationService _instance = CalculationService._internal();
  factory CalculationService() => _instance;
  CalculationService._internal();

  // دریافت تنظیمات واحد از دیتابیس با کش
  Future<Map<String, dynamic>> getUnitSettings(String shopId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedUnitSettings != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < const Duration(minutes: 5)) {
      return _cachedUnitSettings!;
    }

    _cachedUnitSettings = await _dbHelper.getSingleUnit(shopId);
    _lastCacheTime = DateTime.now();
    return _cachedUnitSettings!;


  }

  // محاسبات اصلی
  Map<String, double> calculateTransaction({
    required double sentAmount,
    required Map<String, dynamic> unitSettings,
  }) {
    double buyRate = unitSettings['buy_price'] ?? 0.0;
    double sellRate = unitSettings['sell_price'] ?? 0.0;

    double costPrice = sentAmount * buyRate;
    double receivedAmount = sentAmount * sellRate;
    double profit = receivedAmount - costPrice;

    return {
      'costPrice': costPrice,
      'receivedAmount': receivedAmount,
      'profit': profit,
      'buyRate': buyRate,
      'sellRate': sellRate,
    };
  }

  // محاسبه با sentAmount به صورت مستقیم
// اصلاح شده: دریافت shopId الزامی است
  Future<Map<String, double>> calculateWithAmount(double sentAmount, String shopId) async {
    // تنظیمات را بر اساس آیدی دکان می‌گیریم
    final unitSettings = await getUnitSettings(shopId);

    return calculateTransaction(
      sentAmount: sentAmount,
      unitSettings: unitSettings,
    );
  }

  // ریفرش کش
  Future<void> refreshCache(String shopId) async {
    _cachedUnitSettings = null;
    _lastCacheTime = null;
    await getUnitSettings(shopId,forceRefresh: true);
  }
}


// --- Enum برای نوع تخفیف ---
enum DiscountType { fixed, percent }

// --- مدل برای نتایج محاسبات ---
class PriceCalculationResult {
  final double creditAmount;
  final double discountAmount;
  final double finalSentAmount;
  final double buyRate;
  final double sellRate;
  final double costPrice;
  final double receivedAmount;
  final double profit;
  final DiscountType discountType;
  final double discountPercent;
  final double discountFixed;

  PriceCalculationResult({
    required this.creditAmount,
    required this.discountAmount,
    required this.finalSentAmount,
    required this.buyRate,
    required this.sellRate,
    required this.costPrice,
    required this.receivedAmount,
    required this.profit,
    required this.discountType,
    required this.discountPercent,
    required this.discountFixed,
  });

  @override
  String toString() {
    return '''
    مبلغ اعتباری: ${creditAmount.toStringAsFixed(2)} AFN
    نوع تخفیف: ${discountType == DiscountType.percent ? 'درصدی' : 'ثابت'}
    مقدار تخفیف: ${discountAmount.toStringAsFixed(2)} ${discountType == DiscountType.percent ? '%' : 'AFN'}
    مبلغ پس از تخفیف: ${finalSentAmount.toStringAsFixed(2)} AFN
    نرخ خرید: ${buyRate.toStringAsFixed(4)}
    نرخ فروش: ${sellRate.toStringAsFixed(4)}
    قیمت تمام شده: ${costPrice.toStringAsFixed(2)} AFN
    مبلغ دریافتی: ${receivedAmount.toStringAsFixed(2)} AFN
    سود: ${profit.toStringAsFixed(2)} AFN
    ''';
  }
}

// --- کلاس محاسبات مرکزی ---
class PriceCalculator {

  // محاسبه کامل با دریافت نرخ از دیتابیس (برای زمان ذخیره تراکنش نهایی)
  static Future<PriceCalculationResult> calculateFull({
    required String shopId, // اضافه شد: برای تشخیص دکان
    required double creditAmount,
    required double discountFixed,
    required double discountPercent,
    required DiscountType discountType,
  }) async {
    try {
      // دریافت نرخ‌های مخصوص به این دکان
      final unitSettings = await DatabaseHelper.instance.getSingleUnit(shopId);
      final double buyRate = (unitSettings['buy_price'] as num?)?.toDouble() ?? 0.0;
      final double sellRate = (unitSettings['sell_price'] as num?)?.toDouble() ?? 0.0;

      return _calculate(
        creditAmount: creditAmount,
        discountFixed: discountFixed,
        discountPercent: discountPercent,
        discountType: discountType,
        buyRate: buyRate,
        sellRate: sellRate,
      );
    } catch (e) {
      developer.log('خطا در محاسبه کامل برای دکان $shopId: $e', name: 'PriceCalculator');
      return PriceCalculationResult(
        creditAmount: creditAmount,
        discountAmount: 0,
        finalSentAmount: creditAmount,
        buyRate: 0.0,
        sellRate: 0.0,
        costPrice: 0.0,
        receivedAmount: 0.0,
        profit: 0.0,
        discountType: discountType,
        discountPercent: discountPercent,
        discountFixed: discountFixed,
      );
    }
  }

  // محاسبه Real-time (بدون تغییر - چون نرخ‌ها از قبل توسط UI یا سرویس کش شده‌اند)
  static PriceCalculationResult calculateRealTime({
    required double creditAmount,
    required double discountFixed,
    required double discountPercent,
    required DiscountType discountType,
    required double buyRate,
    required double sellRate,
  }) {
    return _calculate(
      creditAmount: creditAmount,
      discountFixed: discountFixed,
      discountPercent: discountPercent,
      discountType: discountType,
      buyRate: buyRate,
      sellRate: sellRate,
    );
  }

  // متد خصوصی محاسبات ریاضی (بدون تغییر منطق)
  static PriceCalculationResult _calculate({
    required double creditAmount,
    required double discountFixed,
    required double discountPercent,
    required DiscountType discountType,
    required double buyRate,
    required double sellRate,
  }) {
    double discountAmount = 0.0;

    if (discountType == DiscountType.percent) {
      discountAmount = (creditAmount * discountPercent) / 100;
    } else {
      discountAmount = discountFixed;
    }

    if (discountAmount > creditAmount) {
      discountAmount = creditAmount;
    }

    double finalSentAmount = creditAmount - discountAmount;

    // محاسبات حساس مالی
    double costPrice = finalSentAmount * buyRate;
    double receivedAmount = finalSentAmount * sellRate;
    double profit = receivedAmount - costPrice;

    return PriceCalculationResult(
      creditAmount: creditAmount,
      discountAmount: discountAmount,
      finalSentAmount: finalSentAmount,
      buyRate: buyRate,
      sellRate: sellRate,
      costPrice: costPrice,
      receivedAmount: receivedAmount,
      profit: profit,
      discountType: discountType,
      discountPercent: discountPercent,
      discountFixed: discountFixed,
    );
  }
}