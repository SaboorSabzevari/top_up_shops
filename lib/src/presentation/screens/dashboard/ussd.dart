import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // برای ارتباط با کاتلین ضروری است
import 'package:permission_handler/permission_handler.dart';

class UssdActionPage extends StatefulWidget {
  const UssdActionPage({super.key});

  @override
  State<UssdActionPage> createState() => _UssdActionPageState();
}

class _UssdActionPageState extends State<UssdActionPage> {
  // این نام باید دقیقاً با CHANNEL در کاتلین یکی باشد
  static const platform = MethodChannel('com.example.top_up_shops/ussd');

  String _response = "در انتظار ارسال کد...";
  bool _isLoading = false;
  final TextEditingController _ussdController = TextEditingController(text: "*141*1#");

  Future<void> _executeUssd() async {
    // ۱. چک کردن مجوز تماس
    var status = await Permission.phone.request();

    if (status.isGranted) {
      setState(() {
        _isLoading = true;
        _response = "در حال برقراری ارتباط با شبکه...";
      });

      try {
        // ۲. فراخوانی متد کاتلین به جای پکیج خارجی
        // مقدار بازگشتی دقیقاً همان متن پاسخ اپراتور است
        final String? res = await platform.invokeMethod('sendUssd', {
          "code": _ussdController.text.trim(),
        });

        setState(() {
          _response = res ?? "پاسخ خالی دریافت شد";
        });

      } on PlatformException catch (e) {
        setState(() {
          _response = "خطای سیستمی: ${e.message}";
        });
      } catch (e) {
        setState(() {
          _response = "خطای نامشخص رخ داد";
        });
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _response = "مجوز تماس توسط کاربر تایید نشد";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تراکنش USSD مستقیم")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _ussdController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: "کد USSD را وارد کنید",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _executeUssd,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ارسال کد و دریافت پاسخ"),
              ),
            ),
            const SizedBox(height: 40),
            const Text("نتیجه دریافت شده:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Text(
                _response,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}