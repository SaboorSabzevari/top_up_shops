import 'package:flutter/material.dart';
import '../../../data/local/app_database.dart';

class UnitScreen extends StatefulWidget {
  const UnitScreen({super.key});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final TextEditingController buyCtrl = TextEditingController();
  final TextEditingController sellCtrl = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // بارگذاری تنظیمات از دیتابیس
  Future<void> _loadSettings() async {
    final unit = await DatabaseHelper.instance.getSingleUnit();
    setState(() {
      buyCtrl.text = unit['buy_price'].toString();
      sellCtrl.text = unit['sell_price'].toString();
      isLoading = false;
    });
  }

  // ذخیره تغییرات
  Future<void> _save() async {
    double buy = double.tryParse(buyCtrl.text) ?? 0.0;
    double sell = double.tryParse(sellCtrl.text) ?? 0.0;

    await DatabaseHelper.instance.updateSingleUnit(buy, sell);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات واحد با موفقیت ذخیره شد', textAlign: TextAlign.center),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F6F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffF8F6F6),
        title: const Text('تنظیمات واحد',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('تعیین نرخ واحد سیستم',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'این نرخ‌ها برای محاسبه قیمت تمام‌شده و سود شما در تراکنش‌ها استفاده می‌شوند.',
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

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, color: Color(0xffEA2A33)),
              SizedBox(width: 10),
              Text('نرخ‌های خرید و فروش',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildField({required String label, required TextEditingController controller}) {
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade100),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffEEEEEE))),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffEA2A33),
          minimumSize: const Size.fromHeight(55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: _save,
        child: const Text('ذخیره تغییرات',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}