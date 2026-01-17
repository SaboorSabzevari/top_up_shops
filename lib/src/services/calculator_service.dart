// lib/core/services/calculation_service.dart
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Future<Map<String, dynamic>> getUnitSettings({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedUnitSettings != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < const Duration(minutes: 5)) {
      return _cachedUnitSettings!;
    }

    _cachedUnitSettings = await _dbHelper.getSingleUnit();
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
  Future<Map<String, double>> calculateWithAmount(double sentAmount) async {
    final unitSettings = await getUnitSettings();
    return calculateTransaction(
      sentAmount: sentAmount,
      unitSettings: unitSettings,
    );
  }

  // ریفرش کش
  Future<void> refreshCache() async {
    _cachedUnitSettings = null;
    _lastCacheTime = null;
    await getUnitSettings(forceRefresh: true);
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
  // محاسبه کامل با دریافت نرخ از دیتابیس (برای ذخیره)
  static Future<PriceCalculationResult> calculateFull({
    required double creditAmount,
    required double discountFixed,
    required double discountPercent,
    required DiscountType discountType,
  }) async {
    try {
      final unitSettings = await DatabaseHelper.instance.getSingleUnit();
      final double buyRate = unitSettings['buy_price'] ?? 0.0;
      final double sellRate = unitSettings['sell_price'] ?? 0.0;

      return _calculate(
        creditAmount: creditAmount,
        discountFixed: discountFixed,
        discountPercent: discountPercent,
        discountType: discountType,
        buyRate: buyRate,
        sellRate: sellRate,
      );
    } catch (e) {
      developer.log('خطا در محاسبه کامل: $e', name: 'PriceCalculator');
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

  // محاسبه Real-time (با نرخ‌های کش شده)
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

  // محاسبات اصلی
  static PriceCalculationResult _calculate({
    required double creditAmount,
    required double discountFixed,
    required double discountPercent,
    required DiscountType discountType,
    required double buyRate,
    required double sellRate,
  }) {
    // محاسبه مقدار تخفیف بر اساس نوع
    double discountAmount = 0.0;

    if (discountType == DiscountType.percent) {
      // تخفیف درصدی
      discountAmount = (creditAmount * discountPercent) / 100;
    } else {
      // تخفیف مبلغ ثابت
      discountAmount = discountFixed;
    }

    // اطمینان از اینکه تخفیف بیشتر از مبلغ اعتباری نباشد
    if (discountAmount > creditAmount) {
      discountAmount = creditAmount;
    }

    // محاسبه مبلغ نهایی بعد از تخفیف
    double finalSentAmount = creditAmount - discountAmount;

    // محاسبات قیمت
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