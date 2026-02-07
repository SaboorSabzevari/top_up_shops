import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../data/local/app_database.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // متد اصلی همگام‌سازی
  Future<void> syncAll(String shopId) async {
    // ۱. ابتدا آپلود داده‌های محلی (تراکنش‌های جدیدی که در گوشی ثبت شده)
    await _uploadAll(shopId);

    // ۲. سپس دانلود تمام داده‌ها از فایربیس به گوشی (برای بازیابی بعد از نصب مجدد)
    await _downloadAll(shopId);
  }

  // ---------------------------------------------------------
  // بخش اول: آپلود (گوشی به سرور)
  // ---------------------------------------------------------
  Future<void> _uploadAll(String shopId) async {
    final db = await DatabaseHelper.instance.database;

    // لیست جداولی که باید آپلود شوند
    final syncMap = {
      'customers': 'customers',
      'customer_phones': 'customer_phones',
      'transactions': 'transactions',
      'purchases': 'purchases',
      'units': 'units',
      'paper_stock': 'paper_stock',
      'provider_balances': 'provider_balances',
      'providers': 'providers',  // اضافه شد
    };
    for (var entry in syncMap.entries) {
      final localTable = entry.value;
      final remoteCol = entry.key;

      // فقط ردیف‌هایی که هنوز سینک نشده‌اند (اگر ستون is_synced دارید) یا همه
      // نکته: برای سادگی فعلا همه را آپلود می‌کنیم، اما بهتر است ستون is_synced اضافه کنید
      final List<Map<String, dynamic>> records = await db.query(localTable,
          where: 'shop_id = ?', whereArgs: [shopId]);

      for (var record in records) {
        // استفاده از ID محلی به عنوان نام داکیومنت در فایربیس برای جلوگیری از تکرار
        await _firestore
            .collection('shops')
            .doc(shopId)
            .collection(remoteCol)
            .doc(record['id'].toString())
            .set(record, SetOptions(merge: true));

        // در صورت داشتن ستون is_synced، اینجا باید آن را در دیتابیس گوشی ۱ کنید
      }
    }
  }

  // ---------------------------------------------------------
  // بخش دوم: دانلود (سرور به گوشی - حل مشکل نصب مجدد)
  // ---------------------------------------------------------
  // در فایل sync_service.dart
  Future<void> _downloadAll(String shopId) async {
    final db = await DatabaseHelper.instance.database;

    // 🔥 ترتیب دانلود بسیار حیاتی است
    // اول مشتری باید دانلود شود تا ID آن در دیتابیس لوکال وجود داشته باشد
    // سپس شماره تماس‌ها که به آن ID وابسته هستند (Foreign Key)
    final List<String> orderedCollections = [
      'customers',         // اول مشتری
      'customer_phones',   // دوم شماره تماس
      'units',
      'providers',
      'provider_balances',
      'purchases',
      'paper_stock',
      'transactions',      // تراکنش‌ها معمولا آخر
    ];

    for (var colName in orderedCollections) {
      // پیدا کردن نام جدول متناظر (اگر متفاوت است، اینجا مپ کنید)
      String localTable = colName;

      final snap = await _firestore
          .collection('shops')
          .doc(shopId)
          .collection(colName)
          .get();

      if (snap.docs.isEmpty) {
        print("ℹ️ مجموعه $colName خالی است.");
        continue;
      }

      final List<String> tableColumns = await _getTableColumns(db, localTable);

      for (var doc in snap.docs) {
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
          if (docId != null) data['id'] = docId;
        }

        // ۳. فیکس کردن کلیدهای خارجی (اگر در فایربیس String هستند)
        // این بخش برای وصل شدن شماره تماس به مشتری حیاتی است
        if (data.containsKey('customer_id')) {
          if (data['customer_id'] is String) {
            data['customer_id'] = int.tryParse(data['customer_id']);
          }
        }

        // ۴. حذف ستون‌های اضافی که در SQLite وجود ندارند
        data.removeWhere((key, value) => !tableColumns.contains(key));

        try {
          await db.insert(
            localTable,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (e) {
          print("❌ خطا در درج جدول $localTable برای داکیومنت ${doc.id}: $e");
        }
      }
      print("✅ دانلود و درج جدول $localTable با موفقیت انجام شد.");
    }
  } // متد کمکی برای خواندن ساختار جدول از SQLite
  Future<List<String>> _getTableColumns(Database db, String tableName) async {
    var result = await db.rawQuery('PRAGMA table_info($tableName)');
    return result.map((row) => row['name'] as String).toList();
  }
}