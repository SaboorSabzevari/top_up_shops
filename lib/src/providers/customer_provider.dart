import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/local/app_database.dart';


// برای متن جستجو
final searchProvider = StateProvider<String>((ref) => "");

// برای نتایج لحظه‌ای (AJAX)
final customerResultsProvider = FutureProvider((ref) async {
  final query = ref.watch(searchProvider);
  if (query.isEmpty) return [];
  return await DatabaseHelper.instance.searchCustomers(query);
});

// برای جزئیات مشتری انتخاب شده
final selectedCustomerProvider = StateProvider<Map<String, dynamic>?>((ref) => null);