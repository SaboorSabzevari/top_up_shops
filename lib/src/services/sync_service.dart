import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../data/local/app_database.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // متد اصلی همگام‌سازی
  Future<void> syncAll(String shopId) async {
    try {
      print("🔄 شروع همگام‌سازی برای shopId: $shopId");

      // ۱. ابتدا آپلود داده‌های محلی (گوشی به سرور)
      await _uploadAll(shopId);

      // ۲. سپس دانلود تمام داده‌ها از فایربیس (سرور به گوشی)
      await _downloadAll(shopId);

      print("✅ همگام‌سازی با موفقیت کامل شد");
    } catch (e) {
      print("❌ خطا در همگام‌سازی: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // بخش اول: آپلود (گوشی به سرور)
  // ---------------------------------------------------------
  Future<void> _uploadAll(String shopId) async {
    final db = await DatabaseHelper.instance.database;

    // لیست جداولی که باید آپلود شوند (به‌روزرسانی شده)
    final syncMap = {
      'customers': 'customers',           // ✅ فقط جدول اصلی مشتری
      'transactions': 'transactions',
      'purchases': 'purchases',
      'units': 'units',
      'paper_stock': 'paper_stock',
      'provider_balances': 'provider_balances',
      'providers': 'providers',
    };

    // ❌ جداول قدیمی را حذف کردیم:
    // - 'customer_phones'
    // - 'customer_wholesale_codes'

    for (var entry in syncMap.entries) {
      final localTable = entry.value;
      final remoteCol = entry.key;

      print("📤 در حال آپلود جدول: $localTable به collection: $remoteCol");

      try {
        final List<Map<String, dynamic>> records = await db.query(
          localTable,
          where: 'shop_id = ?',
          whereArgs: [shopId],
        );

        if (records.isEmpty) {
          print("ℹ️ جدول $localTable خالی است، صرف نظر می‌شود");
          continue;
        }

        for (var record in records) {
          // پاکسازی و تبدیل داده‌ها
          final Map<String, dynamic> cleanedData = _cleanDataForUpload(record);

          // استفاده از ID محلی به عنوان نام داکیومنت در فایربیس
          await _firestore
              .collection('shops')
              .doc(shopId)
              .collection(remoteCol)
              .doc(record['id'].toString())
              .set(cleanedData, SetOptions(merge: true));
        }

        print("✅ آپلود جدول $localTable با موفقیت انجام شد. تعداد: ${records.length}");
      } catch (e) {
        print("❌ خطا در آپلود جدول $localTable: $e");
      }
    }
  }

  // پاکسازی داده‌ها قبل از آپلود
  Map<String, dynamic> _cleanDataForUpload(Map<String, dynamic> data) {
    final Map<String, dynamic> cleaned = Map<String, dynamic>.from(data);

    // حذف مقادیر null (برای جلوگیری از خطا در فایربیس)
    cleaned.removeWhere((key, value) => value == null);

    // تبدیل Timestamp اگر وجود دارد (البته در دیتابیس محلی ما Timestamp نداریم)
    cleaned.forEach((key, value) {
      if (value is DateTime) {
        cleaned[key] = value.toIso8601String();
      }
    });

    return cleaned;
  }

  // ---------------------------------------------------------
  // بخش دوم: دانلود (سرور به گوشی)
  // ---------------------------------------------------------
  Future<void> _downloadAll(String shopId) async {
    final db = await DatabaseHelper.instance.database;

    // 🔥 ترتیب دانلود با ساختار جدید
    final List<String> orderedCollections = [
      'providers',           // اول: تامین‌کنندگان
      'units',               // دوم: واحدها
      'provider_balances',   // سوم: موجودی تامین‌کنندگان
      'customers',           // چهارم: مشتریان (با تلفن‌ها و کدها در JSON)
      'purchases',           // پنجم: خریدها
      'paper_stock',         // ششم: موجودی کارت کاغذی
      'transactions',        // هفتم: تراکنش‌ها
    ];

    for (var colName in orderedCollections) {
      print("📥 در حال دانلود collection: $colName");

      try {
        final snap = await _firestore
            .collection('shops')
            .doc(shopId)
            .collection(colName)
            .get();

        if (snap.docs.isEmpty) {
          print("ℹ️ collection $colName خالی است.");
          continue;
        }

        final String localTable = colName;
        final List<String> tableColumns = await _getTableColumns(db, localTable);

        int successCount = 0;
        int errorCount = 0;

        for (var doc in snap.docs) {
          try {
            Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());

            // ۱. تبدیل Timestamp به String
            data.forEach((key, value) {
              if (value is Timestamp) {
                data[key] = value.toDate().toIso8601String();
              }
            });

            // ۲. مدیریت ID (تبدیل آی‌دی داکیومنت به عدد)
            if (tableColumns.contains('id')) {
              int? docId = int.tryParse(doc.id);
              if (docId != null) {
                data['id'] = docId;
              } else {
                // اگر ID عددی نیست، از فیلد id در دیتا استفاده کن
                if (data.containsKey('id') && data['id'] is String) {
                  data['id'] = int.tryParse(data['id'] as String) ?? 0;
                }
              }
            }

            // ۳. پردازش ویژه برای جدول customers (JSON fields)
            if (colName == 'customers') {
              data = _processCustomerData(data);
            }

            // ۴. حذف ستون‌های اضافی که در SQLite وجود ندارند
            data.removeWhere((key, value) => !tableColumns.contains(key));

            // ۵. درج در دیتابیس
            await db.insert(
              localTable,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            successCount++;
          } catch (e) {
            errorCount++;
            print("❌ خطا در پردازش داکیومنت ${doc.id} از $colName: $e");
          }
        }

        print("✅ دانلود $colName: $successCount موفق, $errorCount خطا");
      } catch (e) {
        print("❌ خطا در دانلود collection $colName: $e");
      }
    }
  }

  // پردازش ویژه داده‌های مشتری (JSON fields)
  Map<String, dynamic> _processCustomerData(Map<String, dynamic> data) {
    // اطمینان از وجود فیلدهای JSON
    if (!data.containsKey('phones')) {
      data['phones'] = '[]';
    }

    if (!data.containsKey('wholesale_codes')) {
      data['wholesale_codes'] = '[]';
    }

    // تبدیل JSON string اگر به صورت object است (ممکن است در فایربیس به صورت لیست ذخیره شده باشد)
    try {
      // اگر phones یک List است، آن را به JSON string تبدیل کن
      if (data['phones'] is List) {
        data['phones'] = jsonEncode(data['phones']);
      }

      // اگر wholesale_codes یک List است، آن را به JSON string تبدیل کن
      if (data['wholesale_codes'] is List) {
        data['wholesale_codes'] = jsonEncode(data['wholesale_codes']);
      }
    } catch (e) {
      print("⚠️ خطا در تبدیل JSON fields: $e");
      // در صورت خطا، مقادیر پیش‌فرض قرار بده
      data['phones'] = '[]';
      data['wholesale_codes'] = '[]';
    }

    return data;
  }

  // متد کمکی برای خواندن ساختار جدول از SQLite
  Future<List<String>> _getTableColumns(Database db, String tableName) async {
    try {
      var result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      print("❌ خطا در خواندن ساختار جدول $tableName: $e");
      return [];
    }
  }

  // ---------------------------------------------------------
  // متدهای کمکی اضافی برای مدیریت بهتر
  // ---------------------------------------------------------

  // بررسی وجود shop در فایربیس
  Future<bool> checkShopExists(String shopId) async {
    try {
      final doc = await _firestore.collection('shops').doc(shopId).get();
      return doc.exists;
    } catch (e) {
      print("❌ خطا در بررسی وجود shop: $e");
      return false;
    }
  }

  // دریافت تعداد pending operations
  Future<int> getPendingOperations(String shopId) async {
    try {
      // می‌توانید اینجا منطق خاص خود را پیاده‌سازی کنید
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // پاکسازی داده‌های قدیمی در فایربیس (اختیاری)
  Future<void> cleanupFirestore(String shopId) async {
    try {
      print("🧹 در حال پاکسازی داده‌های قدیمی در فایربیس...");

      // پاکسازی collection‌های قدیمی که دیگر استفاده نمی‌شوند
      final oldCollections = ['customer_phones', 'customer_wholesale_codes'];

      for (var collection in oldCollections) {
        try {
          final snap = await _firestore
              .collection('shops')
              .doc(shopId)
              .collection(collection)
              .get();

          // حذف تمام داکیومنت‌ها
          final batch = _firestore.batch();
          for (var doc in snap.docs) {
            batch.delete(doc.reference);
          }

          if (snap.docs.isNotEmpty) {
            await batch.commit();
            print("✅ collection $collection پاکسازی شد (${snap.docs.length} داکیومنت)");
          }
        } catch (e) {
          print("⚠️ خطا در پاکسازی $collection: $e");
        }
      }
    } catch (e) {
      print("❌ خطا در پاکسازی کلی: $e");
    }
  }
}