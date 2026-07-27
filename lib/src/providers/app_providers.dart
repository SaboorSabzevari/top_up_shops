import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import '../providers/session_provider.dart';

// برای عملیات AJAX
final searchFieldProvider = StateProvider<String>((ref) => "");

final searchResultsProvider = FutureProvider((ref) async {
  final query = ref.watch(searchFieldProvider);
  final user = ref.watch(currentUserProvider); // دسترسی به کاربر فعلی
  if (query.isEmpty || user == null) return [];
  return await DatabaseHelper.instance.ajaxSearch(query, user.shopId);
});

final providersListProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await DatabaseHelper.instance.getProviders(user.shopId);
});
