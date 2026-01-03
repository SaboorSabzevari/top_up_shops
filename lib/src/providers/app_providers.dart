import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';


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
  final res = await db.query('providers');
  return res;
});
