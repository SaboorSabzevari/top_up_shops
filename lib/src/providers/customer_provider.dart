import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import 'session_provider.dart';

// ۱. پروایدر متن جستجو
final customerSearchQueryProvider = StateProvider<String>((ref) => "");

// ۲. پروایدر فیلتر (تغییر به String? برای پذیرش null)
final customerFilterProvider = StateProvider<String?>((ref) => null);

// ۳. پروایدر اصلی که لیست مشتریان را از دیتابیس لوکال می‌گیرد
final customerSearchResults = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(customerSearchQueryProvider);
  final filter = ref.watch(customerFilterProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  // دریافت اطلاعات از دیتابیس با ShopID (امنیت آفلاین)
  List<Map<String, dynamic>> customers =
  await DatabaseHelper.instance.searchCustomers(query, user.shopId);

  // اعمال فیلتر نوع مشتری (عادی/عمده)
  if (filter != null) {
    customers = customers.where((c) => c['type'] == filter).toList();
  }

  return customers;
});