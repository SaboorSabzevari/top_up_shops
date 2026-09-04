// مسیر پیشنهادی: lib/src/services/image_upload_service.dart
//
// چرا Cloudinary به‌جای Firebase Storage؟
//   از اکتبر ۲۰۲۴ فایربیس برای استفاده از Storage (حتی در حد رایگان) به
//   ارتقا به پلن Blaze (نیاز به کارت بانکی/حساب billing) نیاز دارد.
//   Cloudinary یک تیر free (حدود ۲۵ گیگ فضا + ۲۵ گیگ ترافیک ماهانه) دارد
//   که بدون کارت بانکی فعال می‌شود و برای عکس پروفایل/تذکره‌ی یک اپ
//   فروشگاهی کوچک کاملاً کافی است. فقط لینک نهایی عکس (یک رشته‌ی کوتاه)
//   در Firestore ذخیره می‌شود، نه خودِ فایل؛ پس حجم دیتابیس هم اضافه
//   نمی‌شود.
//
// راه‌اندازی یک‌باره (رایگان، بدون کارت بانکی):
//   1) در https://cloudinary.com ثبت‌نام کنید (پلن Free).
//   2) از Dashboard مقدار «Cloud Name» را کپی کنید.
//   3) به Settings -> Upload بروید، در بخش «Upload presets» یک preset
//      جدید بسازید با Signing Mode = "Unsigned" و اسمش را مثلاً
//      top_up_shops_unsigned بگذارید و Save کنید.
//   4) همان دو مقدار را در پایین همین فایل جایگزین کنید.

import 'dart:io';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // 🔧 این دو مقدار را با مقادیر خودتان از Cloudinary جایگزین کنید:
  static const String cloudName = 'ys9hjdrw';
  static const String uploadPreset = 'top_up_shops';

  static Uri get _endpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// آپلود یک فایل عکسِ محلی و برگرداندن URL عمومی و همیشگی آن.
  /// اگر مسیر ورودی از قبل یک URL (http/https) باشد، همان را بدون آپلود
  /// مجدد برمی‌گرداند (یعنی ویرایش یک مشتری بدون تغییر عکس، دوباره آپلود
  /// نمی‌کند).
  static Future<String> uploadIfLocal(String? pathOrUrl, {String folder = 'customers'}) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl; // از قبل آپلود شده
    }

    final file = File(pathOrUrl);
    if (!await file.exists()) return '';

    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('آپلود عکس ناموفق بود (${response.statusCode})');
    }

    final body = response.body;
    // به‌جای اضافه‌کردن پکیج json مجزا، یک استخراج ساده‌ی regex برای
    // secure_url کافی است (تا وابستگی اضافه نداشته باشیم؛ اگر ترجیح
    // می‌دهید، می‌توانید با dart:convert هم jsonDecode کنید).
    final match = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (match == null) {
      throw Exception('پاسخ آپلود عکس نامعتبر بود.');
    }
    return match.group(1)!.replaceAll(r'\/', '/');
  }
}