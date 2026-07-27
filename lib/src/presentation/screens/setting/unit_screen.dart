import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // اضافه شد
import '../../../data/local/app_database.dart';
import '../../../providers/session_provider.dart'; // اضافه شد

class UnitScreen extends ConsumerStatefulWidget {
  // تغییر به ConsumerStatefulWidget
  const UnitScreen({super.key});

  @override
  ConsumerState<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends ConsumerState<UnitScreen> {
  final TextEditingController buyCtrl = TextEditingController();
  final TextEditingController sellCtrl = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // استفاده از Future.microtask برای اطمینان از آماده بودن ref
    Future.microtask(() => _loadSettings());
  }

  // بارگذاری تنظیمات از دیتابیس (اصلاح شده)
  Future<void> _loadSettings() async {
    final user = ref.read(currentUserProvider); // دریافت کاربر فعلی
    if (user == null) return;

    // پاس دادن shopId به متد (رفع خطای شما)
    final unit = await DatabaseHelper.instance.getSingleUnit(user.shopId);

    setState(() {
      buyCtrl.text = unit['buy_price'].toString();
      sellCtrl.text = unit['sell_price'].toString();
      isLoading = false;
    });
  }

  // ذخیره تغییرات (اصلاح شده)
  Future<void> _save() async {
    final user = ref.read(currentUserProvider); // دریافت کاربر فعلی
    if (user == null) return;

    double buy = double.tryParse(buyCtrl.text) ?? 0.0;
    double sell = double.tryParse(sellCtrl.text) ?? 0.0;

    // استفاده از متد اصلاح شده در دیتابیس که shopId می‌گیرد
    await DatabaseHelper.instance.updateUnitByShop(buy, sell, user.shopId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تنظیمات واحد با موفقیت برای فروشگاه شما ذخیره شد',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // بقیه کد UI بدون تغییر باقی می‌ماند
    return Scaffold(
      backgroundColor: const Color(0xffF8F6F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffF8F6F6),
        title: const Text(
          'تنظیمات واحد',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'تعیین نرخ واحد سیستم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'این نرخ‌ها فقط برای فروشگاه شما و بر اساس واحد پولی شما محاسبه می‌شوند.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _buildSettingsCard(),
                    ],
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
    );
  }

  // متدهای _buildSettingsCard، _buildField و _buildBottomButton دقیقاً مثل قبل هستند
  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, color: Color(0xffEA2A33)),
              SizedBox(width: 10),
              Text(
                'نرخ‌های خرید و فروش',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              _buildField(label: 'نرخ خرید', controller: buyCtrl),
              const SizedBox(width: 16),
              _buildField(label: 'نرخ فروش', controller: sellCtrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'AFN',
              filled: true,
              fillColor: const Color(0xffF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffEA2A33),
          minimumSize: const Size.fromHeight(55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _save,
        child: const Text(
          'ذخیره تغییرات',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
