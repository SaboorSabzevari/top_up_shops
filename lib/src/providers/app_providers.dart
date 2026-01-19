import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import '../services/session_service.dart';


// برای عملیات AJAX
final searchFieldProvider = StateProvider<String>((ref) => "");

final searchResultsProvider = FutureProvider((ref) async {
  final query = ref.watch(searchFieldProvider);
  if (query.isEmpty) return [];
  return await DatabaseHelper.instance.ajaxSearch(query);
});

// مدیریت شرکت‌های تامین کننده
final providersListProvider = FutureProvider((ref) async {
  final db = await DatabaseHelper.instance.database;
  final shopId = SessionService.instance.currentShopId;
  final res = await db.query('providers', where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)', whereArgs: [shopId]);
  return res;
});
