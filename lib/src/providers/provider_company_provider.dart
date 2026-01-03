import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import '../domain/entity/customer.dart';
import '../domain/entity/providers.dart';


final providerListProvider = StateNotifierProvider<ProviderNotifier, List<ProviderCompany>>((ref) => ProviderNotifier());

class ProviderNotifier extends StateNotifier<List<ProviderCompany>> {
  ProviderNotifier() : super([]) { refresh(); }
  Future refresh() async => state = await DatabaseHelper.instance.getAllProviders();
  Future add(ProviderCompany p) async {
    await DatabaseHelper.instance.addProvider(p);
    refresh();
  }
}