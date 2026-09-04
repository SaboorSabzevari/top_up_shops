// =====================================================================
// app_database.dart  (Firestore-only rewrite)
// مسیر پیشنهادی: lib/src/data/local/app_database.dart
// این فایل دقیقاً همان کلاس/متدهای DatabaseHelper قبلی را با همان نام و
// همان امضا (signature) پیاده‌سازی می‌کند اما به‌جای sqflite از Cloud
// Firestore استفاده می‌کند. به همین دلیل اکثر صفحات UI که
// `DatabaseHelper.instance.xxx(...)` را صدا می‌زنند بدون تغییر کار می‌کنند.
//
// ساختار دیتا در Firestore:
//   shops/{shopId}/customers/{id}
//   shops/{shopId}/transactions/{id}
//   shops/{shopId}/purchases/{id}
//   shops/{shopId}/providers/{id}
//   shops/{shopId}/provider_balances/{providerNameSafe}
//   shops/{shopId}/paper_stock/{operator_faceValue}
//   shops/{shopId}/units/main
//
// نکته‌ی مهم Race Condition:
//   افزایش/کاهش موجودی کارت کاغذی و موجودی شرکت‌ها همیشه داخل
//   FirebaseFirestore.runTransaction انجام می‌شود؛ یعنی اگر دو کارمند
//   همزمان بفروشند، Firestore خودش تراکنش دوم را retry می‌کند و هرگز
//   موجودی منفی یا داده‌ی گم‌شده (lost update) نخواهیم داشت.
// =====================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/customer.dart';
import '../../domain/entity/providers.dart';
import '../../providers/session_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _shopCol(
    String shopId,
    String name,
  ) => _db.collection('shops').doc(shopId).collection(name);

  Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return data;
  }

  String _safeDocId(String raw) =>
      raw.trim().replaceAll(RegExp(r'[\/\.\#\$\[\]\s]+'), '_');

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<Map<String, dynamic>>> _activeDocs(
    Query<Map<String, dynamic>> q,
  ) async {
    final snap = await q.get();
    return snap.docs
        .where((d) => (d.data())['deleted_at'] == null)
        .map((d) => _withId(d))
        .toList();
  }

  // =================================================================
  // TRANSACTIONS (low level - used internally by TransactionRepository)
  // =================================================================

  /// ثبت یک تراکنش خام (بدون کسر موجودی). برای موارد ساده استفاده می‌شود.
  Future<String> addTransaction(Map<String, dynamic> data) async {
    final shopId =
        data['shop_id']?.toString() ?? SessionService.instance.currentShopId;
    final user = SessionService.instance.user;

    final row = Map<String, dynamic>.from(data);
    row['shop_id'] = shopId;
    row['created_by'] ??= user?.uid ?? '';
    row['created_at'] ??= DateTime.now().toIso8601String();
    row['paid_amount'] ??= row['received_amount'];
    row['received_amount'] ??= row['paid_amount'];
    row['customer_remote_id'] ??= row['customer_id'];
    row['deleted_at'] = null;

    final ref = _shopCol(shopId, 'transactions').doc();
    await ref.set(row);
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> ajaxSearch(
    String query,
    String shopId,
  ) async {
    final results = await searchCustomers(query, shopId);
    return results.take(10).map((c) {
      return {
        'id': c['id'],
        'name': c['name'],
        'customer_code': c['customer_code'],
        'type': c['type'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(
    String shopId,
    String date,
  ) async {
    final start = DateTime.parse(date);
    final end = start.add(const Duration(days: 1));
    final q = _shopCol(shopId, 'transactions')
        .where('created_at', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('created_at', isLessThan: end.toIso8601String());
    return _activeDocs(q);
  }

  // =================================================================
  // CUSTOMERS
  // =================================================================

  Future<String> _uniqueCustomerCode(
    String shopId,
    String baseCode, {
    String? excludingId,
  }) async {
    final seed = baseCode.trim().isEmpty
        ? 'CUST-${DateTime.now().millisecondsSinceEpoch}'
        : baseCode.trim();
    var candidate = seed;
    var suffix = 1;
    while (true) {
      final q = await _shopCol(shopId, 'customers')
          .where('customer_code', isEqualTo: candidate)
          .get();
      final clash = q.docs.any(
        (d) => d.id != excludingId && d.data()['deleted_at'] == null,
      );
      if (!clash) return candidate;
      suffix++;
      candidate = '$seed-$suffix';
    }
  }

  Future<String> addCustomer(
    Customer c,
    List<String>? phones,
    List<Map<String, String>>? wholesaleCodes,
    UserModel user,
  ) async {
    final code = await _uniqueCustomerCode(user.shopId, c.customerCode);
    final ref = _shopCol(user.shopId, 'customers').doc();
    final data = <String, dynamic>{
      'name': c.name,
      'customer_code': code,
      'type': c.type,
      'shop_id': user.shopId,
      'created_by': user.uid,
      'address': c.address,
      'profile_image': c.profileImage,
      'tazkira_image': c.tazkiraImage,
      'phones': phones ?? [],
      'wholesale_codes': wholesaleCodes ?? [],
      'created_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
    };
    await ref.set(data);
    return ref.id;
  }

  Future<void> updateCustomer(
    String id,
    Customer c,
    List<String>? phones,
    List<Map<String, String>>? wholesaleCodes,
    UserModel user,
  ) async {
    final code = await _uniqueCustomerCode(
      user.shopId,
      c.customerCode,
      excludingId: id,
    );
    await _shopCol(user.shopId, 'customers').doc(id).set({
      'name': c.name,
      'customer_code': code,
      'type': c.type,
      'shop_id': user.shopId,
      'created_by': user.uid,
      'address': c.address,
      'profile_image': c.profileImage,
      'tazkira_image': c.tazkiraImage,
      'phones': phones ?? [],
      'wholesale_codes': wholesaleCodes ?? [],
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> searchCustomers(
    String query,
    String shopId,
  ) async {
    // Firestore متن‌جستجوی آزاد (LIKE) ندارد، پس همه‌ی مشتریان فعال دکان را
    // می‌گیریم و فیلتر را سمت کلاینت انجام می‌دهیم (برای مقیاس یک دکان کوچک
    // کاملاً کافی است).
    final snap = await _shopCol(shopId, 'customers').get();
    final q = query.trim().toLowerCase();
    final all = snap.docs
        .where((d) => d.data()['deleted_at'] == null)
        .map((d) => _withId(d))
        .toList();
    if (q.isEmpty) return all;
    return all.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final code = (c['customer_code'] ?? '').toString().toLowerCase();
      final phones = (c['phones'] is List)
          ? (c['phones'] as List).join(',').toLowerCase()
          : (c['phones'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q) || phones.contains(q);
    }).toList();
  }

  Future<Map<String, dynamic>> getCustomerFullDetails(
    String id,
    String shopId,
  ) async {
    final doc = await _shopCol(shopId, 'customers').doc(id).get();
    if (!doc.exists) return {};
    final result = _withId(doc);

    // نرمال‌سازی phones
    final rawPhones = result['phones'];
    if (rawPhones is List) {
      result['phones'] = rawPhones.map((p) {
        if (p is Map) return Map<String, dynamic>.from(p);
        return {'phone_number': p.toString()};
      }).toList();
    } else {
      result['phones'] = [];
    }

    // نرمال‌سازی wholesale_codes
    final rawCodes = result['wholesale_codes'];
    if (rawCodes is List) {
      result['wholesale_codes'] = rawCodes.map((c) {
        if (c is Map) {
          return {
            'company_name': c['company'] ?? c['company_name'],
            'company_code': c['code'] ?? c['company_code'],
          };
        }
        return c;
      }).toList();
    } else {
      result['wholesale_codes'] = [];
    }

    return result;
  }

  Future<double> getCustomerTotalBalance(String customerId, String shopId) async {
    final snap = await _shopCol(shopId, 'transactions')
        .where('customer_id', isEqualTo: customerId)
        .get();
    double total = 0, paid = 0;
    for (final d in snap.docs) {
      final data = d.data();
      if (data['deleted_at'] != null) continue;
      total += (data['total_price'] as num? ?? 0).toDouble();
      paid += (data['paid_amount'] as num? ?? 0).toDouble();
    }
    return total - paid;
  }

  // =================================================================
  // PROVIDERS (شرکت‌های سرویس‌دهنده)
  // =================================================================

  static const List<Map<String, dynamic>> _defaultProviders = [
    {
      'name': 'ستارگان متحد',
      'type': 'ستارگان متحد',
      'ordinary_code': '543*2',
      'wholesale_code': '543*6',
    },
    {
      'name': 'اکتیو سرویس',
      'type': 'اکتیو سرویس',
      'ordinary_code': '683',
      'wholesale_code': '683*2',
    },
    {
      'name': 'افغان پی',
      'type': 'افغان پی',
      'ordinary_code': '511',
      'wholesale_code': '511*5',
    },
    {
      'name': 'شاهی ایزیلود',
      'type': 'شاهی ایزیلود',
      'ordinary_code': '545',
      'wholesale_code': '511*5',
    },
  ];

  Future<String> addProvider(Map<String, dynamic> providerMap) async {
    final shopId = providerMap['shop_id']?.toString() ?? '';
    final ref = _shopCol(shopId, 'providers').doc();
    await ref.set({...providerMap, 'shop_id': shopId, 'deleted_at': null});
    return ref.id;
  }

  Future<void> _seedProvidersIfEmpty(String shopId) async {
    final snap = await _shopCol(shopId, 'providers').limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final p in _defaultProviders) {
      final ref = _shopCol(shopId, 'providers').doc();
      batch.set(ref, {
        ...p,
        'shop_id': shopId,
        'created_at': DateTime.now().toIso8601String(),
        'deleted_at': null,
      });
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getProviders([String? shopId]) async {
    if (shopId == null || shopId.isEmpty) return [];
    await _seedProvidersIfEmpty(shopId);
    return _activeDocs(_shopCol(shopId, 'providers'));
  }

  Future<List<ProviderCompany>> getAllProviders(String shopId) async {
    final list = await getProviders(shopId);
    return list.map((e) => ProviderCompany.fromMap(e)).toList();
  }

  // =================================================================
  // UNITS (نرخ خرید/فروش هر دکان)
  // =================================================================

  Future<Map<String, dynamic>> getSingleUnit(String shopId) async {
    final ref = _shopCol(shopId, 'units').doc('main');
    final doc = await ref.get();
    if (doc.exists) return _withId(doc);
    final defaultData = {
      'buy_price': 0.95,
      'sell_price': 0.96,
      'name': 'واحد اصلی',
      'shop_id': shopId,
    };
    await ref.set(defaultData);
    return defaultData;
  }

  Future<void> updateUnitByShop(double buy, double sell, String shopId) async {
    await _shopCol(shopId, 'units').doc('main').set({
      'buy_price': buy,
      'sell_price': sell,
      'shop_id': shopId,
    }, SetOptions(merge: true));
  }

  Future<void> addUnit(double buy, double sell) async {
    final shopId = SessionService.instance.currentShopId;
    await updateUnitByShop(buy, sell, shopId);
  }

  Future<void> updateUnit(String id, double buy, double sell) async {
    final shopId = SessionService.instance.currentShopId;
    await updateUnitByShop(buy, sell, shopId);
  }

  Future<void> deleteUnit(String id) async {
    // هر دکان فقط یک واحد دارد؛ چیزی برای حذف واقعی نیست.
  }

  // =================================================================
  // PAPER STOCK (موجودی کارت کاغذی) — با Firestore transaction
  // =================================================================

  String _paperStockDocId(String operator, int faceValue) =>
      '${_safeDocId(operator.toLowerCase())}_$faceValue';

  Future<int> decreasePaperStock(
    String operator,
    int faceValue,
    int qty,
    String shopId,
  ) async {
    final ref =
        _shopCol(shopId, 'paper_stock').doc(_paperStockDocId(operator, faceValue));
    return _db.runTransaction<int>((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw Exception('این کارت در انبار دکان شما تعریف نشده است.');
      }
      final current = (snap.data()!['quantity'] as num).toInt();
      if (current < qty) {
        throw Exception('موجودی کافی نیست! موجودی فعلی: $current');
      }
      txn.update(ref, {'quantity': current - qty});
      return current - qty;
    });
  }

  Future<void> increasePaperStock(
    String operator,
    int faceValue,
    int qty,
    String shopId,
  ) async {
    final ref =
        _shopCol(shopId, 'paper_stock').doc(_paperStockDocId(operator, faceValue));
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        txn.set(ref, {
          'operator_name': operator,
          'face_value': faceValue,
          'quantity': qty,
          'shop_id': shopId,
          'deleted_at': null,
        });
      } else {
        final current = (snap.data()!['quantity'] as num).toInt();
        txn.update(ref, {'quantity': current + qty});
      }
    });
  }

  Future<int> getPaperStockCount(
    String operator,
    int faceValue,
    String shopId,
  ) async {
    final doc = await _shopCol(shopId, 'paper_stock')
        .doc(_paperStockDocId(operator, faceValue))
        .get();
    if (!doc.exists) return 0;
    return (doc.data()!['quantity'] as num? ?? 0).toInt();
  }

  Future<List<Map<String, dynamic>>> getAllPaperStocks([String? shopId]) async {
    final sid = shopId ?? SessionService.instance.currentShopId;
    if (sid.isEmpty) return [];
    final list = await _activeDocs(_shopCol(sid, 'paper_stock'));
    list.sort((a, b) {
      final byOp = (a['operator_name'] ?? '').toString().compareTo(
        (b['operator_name'] ?? '').toString(),
      );
      if (byOp != 0) return byOp;
      return ((a['face_value'] ?? 0) as num).compareTo(
        (b['face_value'] ?? 0) as num,
      );
    });
    return list;
  }

  // =================================================================
  // PROVIDER BALANCES (موجودی کریدیت دیجیتال) — با Firestore transaction
  // =================================================================

  String _balanceDocId(String providerName) => _safeDocId(providerName);

  Future<void> increaseProviderBalance(
    String providerName,
    double amount,
    String shopId,
  ) async {
    final ref = _shopCol(shopId, 'provider_balances').doc(_balanceDocId(providerName));
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        txn.set(ref, {
          'provider_name': providerName,
          'current_balance': amount,
          'shop_id': shopId,
          'deleted_at': null,
        });
      } else {
        final current = (snap.data()!['current_balance'] as num).toDouble();
        txn.update(ref, {'current_balance': current + amount});
      }
    });
  }

  Future<void> decreaseProviderBalance(
    String providerName,
    double amount,
    String shopId,
  ) async {
    final ref = _shopCol(shopId, 'provider_balances').doc(_balanceDocId(providerName));
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw Exception('موجودی شرکت "$providerName" تعریف نشده است.');
      }
      final current = (snap.data()!['current_balance'] as num).toDouble();
      if (current < amount) {
        throw Exception('موجودی شرکت "$providerName" کافی نیست! موجودی فعلی: $current');
      }
      txn.update(ref, {'current_balance': current - amount});
    });
  }

  Future<double> getProviderBalance(String providerName, String shopId) async {
    final doc =
        await _shopCol(shopId, 'provider_balances').doc(_balanceDocId(providerName)).get();
    if (!doc.exists) return 0.0;
    return (doc.data()!['current_balance'] as num? ?? 0).toDouble();
  }

  Future<List<Map<String, dynamic>>> getAllProviderBalances([String? shopId]) async {
    final sid = shopId ?? SessionService.instance.currentShopId;
    if (sid.isEmpty) return [];
    return _activeDocs(_shopCol(sid, 'provider_balances'));
  }

  // =================================================================
  // PURCHASES (خریدها)
  // =================================================================

  Future<String> insertPurchase(Map<String, dynamic> row, UserModel user) async {
    final ref = _shopCol(user.shopId, 'purchases').doc();
    await ref.set({
      ...row,
      'shop_id': user.shopId,
      'created_by': user.uid,
      'created_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
    });
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getAllPurchases(String shopId) async {
    final list = await _activeDocs(_shopCol(shopId, 'purchases'));
    list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo(
          (a['created_at'] ?? '').toString(),
        ));
    return list;
  }

  Future<String> recordPurchase({
    required Map<String, dynamic> purchaseData,
    required UserModel user,
    String? stockOperator,
    int? stockFaceValue,
    int? stockQuantity,
    String? providerName,
    double? providerCreditAmount,
  }) async {
    final purchaseRef = _shopCol(user.shopId, 'purchases').doc();

    DocumentReference<Map<String, dynamic>>? stockRef;
    DocumentReference<Map<String, dynamic>>? balanceRef;
    if (stockOperator != null && stockFaceValue != null && stockQuantity != null) {
      stockRef = _shopCol(user.shopId, 'paper_stock')
          .doc(_paperStockDocId(stockOperator, stockFaceValue));
    }
    if (providerName != null && providerCreditAmount != null) {
      balanceRef = _shopCol(user.shopId, 'provider_balances').doc(_balanceDocId(providerName));
    }

    await _db.runTransaction((txn) async {
      DocumentSnapshot<Map<String, dynamic>>? stockSnap;
      DocumentSnapshot<Map<String, dynamic>>? balanceSnap;
      if (stockRef != null) stockSnap = await txn.get(stockRef);
      if (balanceRef != null) balanceSnap = await txn.get(balanceRef);

      if (stockRef != null) {
        if (stockSnap != null && stockSnap.exists) {
          final current = (stockSnap.data()!['quantity'] as num).toInt();
          txn.update(stockRef, {'quantity': current + stockQuantity!});
        } else {
          txn.set(stockRef, {
            'operator_name': stockOperator,
            'face_value': stockFaceValue,
            'quantity': stockQuantity,
            'shop_id': user.shopId,
            'deleted_at': null,
          });
        }
      }

      if (balanceRef != null) {
        if (balanceSnap != null && balanceSnap.exists) {
          final current = (balanceSnap.data()!['current_balance'] as num).toDouble();
          txn.update(balanceRef, {'current_balance': current + providerCreditAmount!});
        } else {
          txn.set(balanceRef, {
            'provider_name': providerName,
            'current_balance': providerCreditAmount,
            'shop_id': user.shopId,
            'deleted_at': null,
          });
        }
      }

      txn.set(purchaseRef, {
        ...purchaseData,
        'shop_id': user.shopId,
        'created_by': user.uid,
        'created_at': DateTime.now().toIso8601String(),
        'deleted_at': null,
      });
    });

    return purchaseRef.id;
  }

  // =================================================================
  // TRANSACTIONS (فروش) — سطح بالا
  // =================================================================

  Future<Map<String, dynamic>> _normalizeTransactionData(
    Map<String, dynamic> data,
    UserModel user,
  ) async {
    final row = Map<String, dynamic>.from(data);
    final paid =
        (row['paid_amount'] as num? ?? row['received_amount'] as num? ?? 0).toDouble();
    row['paid_amount'] = paid;
    row['received_amount'] = paid;
    row['customer_remote_id'] ??= row['customer_id'];
    row['shop_id'] = user.shopId;
    row['created_by'] = user.uid;
    row['created_at'] ??= DateTime.now().toIso8601String();
    row['deleted_at'] = null;
    return row;
  }

  Future<String> saveDetailedTransaction(
    Map<String, dynamic> data,
    UserModel user,
  ) async {
    double total = (data['total_price'] ?? 0.0).toDouble();
    double paid = (data['paid_amount'] ?? 0.0).toDouble();
    double remaining = total - paid;

    final normalized = await _normalizeTransactionData({
      'customer_id': data['customer_id'],
      'customer_remote_id': data['customer_remote_id'],
      'customer_name': data['customer_name'] ?? 'مشتری رهگذر',
      'customer_type': data['customer_type'] ?? 'WALK_IN',
      'transaction_type': data['transaction_type'] ?? 'DIGITAL',
      'operator_name': data['operator_name'],
      'phone_number': data['phone_number'],
      'company_code': data['company_code'],
      'sent_amount': data['sent_amount'],
      'quantity': data['quantity'] ?? 1,
      'discount': data['discount'] ?? 0.0,
      'total_price': total,
      'paid_amount': paid,
      'remaining_amount': remaining,
      'received_amount': data['received_amount'] ?? paid,
      'cost_price': data['cost_price'],
      'profit': data['profit'],
      'ussd_command': data['ussd_command'],
    }, user);

    final ref = _shopCol(user.shopId, 'transactions').doc();
    await ref.set(normalized);
    return ref.id;
  }

  Future<String> insertDetailedTransaction(
    Map<String, dynamic> data,
    UserModel user,
  ) async {
    final row = Map<String, dynamic>.from(data);
    row['shop_id'] = user.shopId;
    row['created_by'] = user.uid;
    row['created_at'] = DateTime.now().toIso8601String();
    return addTransaction(row);
  }

  Future<List<Map<String, dynamic>>> getFilteredTransactions(UserModel user) async {
    final list = await _activeDocs(_shopCol(user.shopId, 'transactions'));
    list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo(
          (a['created_at'] ?? '').toString(),
        ));
    return list;
  }

  /// فروش کریدیت دیجیتال: کاهش موجودی شرکت + ثبت تراکنش، اتمیک با Firestore transaction
  Future<String> recordDigitalSale({
    required Map<String, dynamic> transactionData,
    required String providerName,
    required double amount,
    required UserModel user,
  }) async {
    final balanceRef =
        _shopCol(user.shopId, 'provider_balances').doc(_balanceDocId(providerName));
    final txnRef = _shopCol(user.shopId, 'transactions').doc();

    final normalized = await _normalizeTransactionData({
      ...transactionData,
    }, user);

    await _db.runTransaction((txn) async {
      final balanceSnap = await txn.get(balanceRef);
      if (!balanceSnap.exists) {
        throw Exception('موجودی شرکت "$providerName" تعریف نشده است.');
      }
      final current = (balanceSnap.data()!['current_balance'] as num).toDouble();
      if (current < amount) {
        throw Exception('موجودی شرکت "$providerName" کافی نیست! موجودی فعلی: $current');
      }
      txn.update(balanceRef, {'current_balance': current - amount});
      txn.set(txnRef, normalized);
    });

    return txnRef.id;
  }

  /// فروش کارت کاغذی: کاهش موجودی انبار + ثبت تراکنش، اتمیک
  Future<String> recordPaperSale({
    required Map<String, dynamic> transactionData,
    required String operator,
    required int faceValue,
    required int quantity,
    required UserModel user,
  }) async {
    final stockRef =
        _shopCol(user.shopId, 'paper_stock').doc(_paperStockDocId(operator, faceValue));
    final txnRef = _shopCol(user.shopId, 'transactions').doc();

    final normalized = await _normalizeTransactionData({
      ...transactionData,
    }, user);

    await _db.runTransaction((txn) async {
      final stockSnap = await txn.get(stockRef);
      if (!stockSnap.exists) {
        throw Exception('این کارت در انبار دکان شما تعریف نشده است.');
      }
      final current = (stockSnap.data()!['quantity'] as num).toInt();
      if (current < quantity) {
        throw Exception('موجودی کافی نیست! موجودی فعلی: $current');
      }
      txn.update(stockRef, {'quantity': current - quantity});
      txn.set(txnRef, normalized);
    });

    return txnRef.id;
  }
}
