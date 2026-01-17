// lib/core/providers/calculation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/calculator_service.dart';

// Provider برای سرویس محاسبات
final calculationServiceProvider = Provider<CalculationService>((ref) {
  return CalculationService();
});

// Provider برای تنظیمات واحد (real-time)
final unitSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(calculationServiceProvider);
  return await service.getUnitSettings();
});

// Provider برای محاسبات real-time بر اساس مقدار ارسالی
final transactionCalculationsProvider =
FutureProvider.family<Map<String, double>, double>((ref, sentAmount) async {
  final service = ref.watch(calculationServiceProvider);
  return await service.calculateWithAmount(sentAmount);
});

// Provider برای مانیتورینگ تغییرات (برای صفحات مختلف)
final calculationUpdatesProvider = StreamProvider<void>((ref) async* {
  // این استریم می‌تواند با رویدادهای مختلف (مثل تغییر نرخ) به‌روز شود
  yield null;
});