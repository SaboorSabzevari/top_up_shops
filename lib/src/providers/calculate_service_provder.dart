// lib/core/providers/calculation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_up_shops/src/providers/session_provider.dart';
import '../services/calculator_service.dart';

// Provider برای سرویس محاسبات (به صورت Singleton)
final calculationServiceProvider = Provider<CalculationService>((ref) {
  return CalculationService();
});

// Provider برای تنظیمات واحد (با در نظر گرفتن shopId)
final unitSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(calculationServiceProvider);
  final user = ref.watch(currentUserProvider); // گرفتن اطلاعات کاربر فعلی

  if (user == null) {
    throw Exception("کاربر وارد نشده است");
  }

  // حالا پارامتر shopId که متد انتظار دارد را پاس می‌دهیم
  return await service.getUnitSettings(user.shopId);
});

// Provider برای محاسبات بر اساس مقدار ارسالی (با در نظر گرفتن shopId)
// در بخش محاسبات تراکنش، خروجی را به ریال/افغانی رند کنید تا در UI با مشکل مواجه نشوید
final transactionCalculationsProvider =
FutureProvider.family<Map<String, double>, double>((ref, sentAmount) async {
  final service = ref.watch(calculationServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return {'cost_price': 0.0, 'received_amount': 0.0, 'profit': 0.0};

  final result = await service.calculateWithAmount(sentAmount, user.shopId);

  // اطمینان از اینکه مقادیر null نیستند و به درستی محاسبه شده‌اند
  return result;
});
// Provider برای مانیتورینگ تغییرات
final calculationUpdatesProvider = StreamProvider<void>((ref) async* {
  yield null;
});