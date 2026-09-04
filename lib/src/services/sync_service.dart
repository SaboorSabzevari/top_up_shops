// مسیر پیشنهادی: lib/src/services/sync_service.dart
// از آنجا که دیگر هیچ دیتابیس محلی نداریم و Firestore تنها منبع حقیقت
// است، دیگر "sync" به معنای قبلی (push outbox + pull incremental) معنا
// ندارد؛ هر خواندن/نوشتن مستقیماً روی Firestore انجام می‌شود.
//
// این کلاس را فقط برای سازگاری با UI فعلی (مثلاً دکمه‌ی sync در داشبورد)
// نگه داشتیم: دکمه فقط Providerهای صفحه را invalidate می‌کند تا آخرین
// دیتا را از Firestore دوباره بخواند.
class SyncService {
  Future<void> syncAll(String shopId) async {
    // چیزی برای push/pull کردن نیست؛ Firestore خودش منبع اصلی است.
    // این متد فقط برای حفظ سازگاری API نگه داشته شده.
    return;
  }

  Future<int> getPendingOperations(String shopId) async => 0;

  Future<bool> checkShopExists(String shopId) async {
    // در صورت نیاز می‌توانید اینجا واقعاً از Firestore چک کنید:
    // await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
    return true;
  }
}