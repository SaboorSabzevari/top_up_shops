import 'package:flutter_riverpod/flutter_riverpod.dart'; // ترجیحاً از نسخه اصلی استفاده کنید
import 'package:flutter_riverpod/legacy.dart';
import '../data/local/app_database.dart';
import '../domain/entity/providers.dart';
import '../providers/session_provider.dart';

// تغییر به StateNotifierProvider که Ref می‌گیرد
final providerListProvider =
    StateNotifierProvider<ProviderNotifier, List<ProviderCompany>>((ref) {
      return ProviderNotifier(ref);
    });

class ProviderNotifier extends StateNotifier<List<ProviderCompany>> {
  final Ref ref;

  ProviderNotifier(this.ref) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = [];
      return;
    }

    // متد getAllProviders باید در DatabaseHelper اصلاح شود تا shopId بگیرد
    final providersData = await DatabaseHelper.instance.getProviders(
      user.shopId,
    );

    // تبدیل Map به Object (فرض بر این است که مدل ProviderCompany متد fromMap دارد)
    state = providersData.map((m) => ProviderCompany.fromMap(m)).toList();
  }

  Future<void> add(ProviderCompany p) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // اضافه کردن shop_id به شیء قبل از ذخیره
    final providerWithShop = p.copyWith(shopId: user.shopId);

    await DatabaseHelper.instance.addProvider(providerWithShop.toMap());
    await refresh();
  }
}
