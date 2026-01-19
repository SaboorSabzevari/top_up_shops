import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import '../services/session_service.dart';


final customerSearchQuery = StateProvider<String>((ref) => "");


final selectedCustomerFullInfo = StateProvider<Map<String, dynamic>?>((ref) => null);

final customerSearchResults = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(customerSearchQuery);

  if (query.isEmpty) {
    // اگر جستجو خالی بود، همه مخاطبان را از دیتابیس بگیر
    final db = await DatabaseHelper.instance.database;
    final shopId = SessionService.instance.currentShopId;
    return await db.query('customers', where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)', whereArgs: [shopId]);
  }

  // در غیر این صورت فیلتر کن
  return await DatabaseHelper.instance.searchCustomers(query);
});

// اضافه کردن یک پروایدر برای مدیریت فیلتر (همه، دکاندار، عادی)
final customerFilterProvider = StateProvider<String>((ref) => 'همه');
