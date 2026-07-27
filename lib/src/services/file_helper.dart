import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

class ImageService {
  static Future<String?> saveAndCompressImage(File file, String prefix) async {
    try {
      // ۱. گرفتن دایرکتوری اسناد اپلیکیشن
      final directory = await getApplicationDocumentsDirectory();

      // ۲. ایجاد نام منحصر به فرد برای فایل
      final String fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = p.join(directory.path, fileName);

      // ۳. فشرده‌سازی تصویر
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // کیفیت ۷۰ درصد برای تعادل بین حجم و وضوح
      );

      return result?.path; // بازگرداندن مسیر کامل برای ذخیره در دیتابیس
    } catch (e) {
      print("خطا در ذخیره تصویر: $e");
      return null;
    }
  }
}
