import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../data/local/app_database.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // متد اصلی برای همگام‌سازی جامع
  Future<void> syncAll(String shopId) async {
    // مرحله اول: ارسال دیتای محلی به سرور
    await _uploadAll(shopId);

    // مرحله دوم: دریافت دیتای جدید از سرور به گوشی
    await _downloadAll(shopId);
  }

  // ---------------------------------------------------------
  // بخش اول: آپلود دیتای گوشی به فایربیس (Upload/Push)
  // ---------------------------------------------------------
  Future<void> _uploadAll(String shopId) async {
    final db = await DatabaseHelper.instance.database;

    // ۱. آپلود مشتریان
    final customers = await db.query('customers', where: 'shop_id = ?', whereArgs: [shopId]);
    for (var c in customers) {
      await _firestore.collection('shops').doc(shopId).collection('customers').doc(c['id'].toString()).set(c);
    }

    // ۲. آپلود تراکنش‌های فروش (فقط آن‌هایی که سینک نشده‌اند)
    final transactions = await db.query('transactions', where: 'shop_id = ? AND is_synced = 0', whereArgs: [shopId]);
    for (var t in transactions) {
      await _firestore.collection('shops').doc(shopId).collection('transactions').doc(t['id'].toString()).set(t);
      await db.update('transactions', {'is_synced': 1}, where: 'id = ?', whereArgs: [t['id']]);
    }

    // ۳. آپلود خریدها
    final purchases = await db.query('purchases', where: 'shop_id = ?', whereArgs: [shopId]);
    for (var p in purchases) {
      await _firestore.collection('shops').doc(shopId).collection('purchases').doc(p['id'].toString()).set(p);
    }

    // ۴. آپلود موجودی پروایدرها
    final balances = await db.query('provider_balances', where: 'shop_id = ?', whereArgs: [shopId]);
    for (var b in balances) {
      await _firestore.collection('shops').doc(shopId).collection('balances').doc(b['provider_name'].toString()).set(b);
    }

    // ۵. آپلود کارت‌های کاغذی
    final stocks = await db.query('paper_stock', where: 'shop_id = ?', whereArgs: [shopId]);
    for (var s in stocks) {
      String docId = "${s['operator']}_${s['face_value']}";
      await _firestore.collection('shops').doc(shopId).collection('paper_stock').doc(docId).set(s);
    }

    // ۶. آپلود نرخ واحدها
    final units = await db.query('units', where: 'shop_id = ?', whereArgs: [shopId]);
    for (var u in units) {
      await _firestore.collection('shops').doc(shopId).collection('units').doc(u['operator_code'].toString()).set(u);
    }
  }

  // ---------------------------------------------------------
  // بخش دوم: دانلود دیتای فایربیس به گوشی (Download/Pull)
  // ---------------------------------------------------------
  Future<void> _downloadAll(String shopId) async {
    final db = await DatabaseHelper.instance.database;

    // ۱. دانلود مشتریان
    final custSnap = await _firestore.collection('shops').doc(shopId).collection('customers').get();
    for (var doc in custSnap.docs) {
      await db.insert('customers', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ۲. دانلود نرخ واحدها (حیاتی برای هماهنگی کارمند و دکان‌دار)
    final unitSnap = await _firestore.collection('shops').doc(shopId).collection('units').get();
    for (var doc in unitSnap.docs) {
      await db.insert('units', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ۳. دانلود موجودی شرکت‌ها (Wallet Balances)
    final balSnap = await _firestore.collection('shops').doc(shopId).collection('balances').get();
    for (var doc in balSnap.docs) {
      await db.insert('provider_balances', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ۴. دانلود موجودی کارت‌های کاغذی
    final paperSnap = await _firestore.collection('shops').doc(shopId).collection('paper_stock').get();
    for (var doc in paperSnap.docs) {
      await db.insert('paper_stock', doc.data(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ۵. دانلود تراکنش‌های اخیر (مثلاً ۵۰ مورد آخر برای جلوگیری از سنگین شدن دیتابیس)
    final transSnap = await _firestore.collection('shops').doc(shopId)
        .collection('transactions').orderBy('created_at', descending: true).limit(50).get();
    for (var doc in transSnap.docs) {
      Map<String, dynamic> data = Map.from(doc.data());
      data['is_synced'] = 1; // دیتایی که دانلود شده قطعاً سینک شده است
      await db.insert('transactions', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}