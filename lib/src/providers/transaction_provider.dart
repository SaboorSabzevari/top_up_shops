import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import '../domain/entity/customer.dart';


final companyListProvider = StateNotifierProvider<CompanyNotifier, List<Map<String, dynamic>>>((ref) {
  return CompanyNotifier();
});

class CompanyNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  CompanyNotifier() : super([]) { load(); }

  Future load() async {
    final db = await DatabaseHelper.instance.database;
    state = await db.query('providers');
  }

  Future add(ProviderCompany c) async {
    await DatabaseHelper.instance.insertProvider(c); // متد CRUD که در db_helper مینویسید
    load();
  }
}