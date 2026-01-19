import 'package:flutter/material.dart';

import '../../../data/repository/shop_repository.dart';
import '../../../services/session_service.dart';
import '../../theme/colors.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final ShopRepository _repo = ShopRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = true;
  Map<String, dynamic>? _shop;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shop = await _repo.getCurrentShop();
    if (!mounted) return;
    setState(() {
      _shop = shop;
      _nameCtrl.text = shop?['name']?.toString() ?? '';
      _phoneCtrl.text = shop?['phone']?.toString() ?? '';
      _addressCtrl.text = shop?['address']?.toString() ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await _repo.updateShopProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logoPath: _shop?['logo_path']?.toString(),
    );
    await _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF8F6F6);
    final isOwner = SessionService.instance.currentRoleId == 'owner';
    final subscriptionExpiry = _shop?['subscription_expiry']?.toString();
    final subscriptionStatus = _shop?['subscription_status']?.toString() ?? 'active';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('پروفایل فروشگاه', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSubscriptionCard(subscriptionStatus, subscriptionExpiry, isOwner),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildField(_nameCtrl, 'نام فروشگاه', Icons.store),
                          const SizedBox(height: 12),
                          _buildField(_phoneCtrl, 'شماره تماس', Icons.call),
                          const SizedBox(height: 12),
                          _buildField(_addressCtrl, 'آدرس', Icons.location_on, maxLines: 2),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (v) => v == null || v.trim().isEmpty ? 'اجباری است' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF8F6F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubscriptionCard(String status, String? expiry, bool isOwner) {
    final isExpired = status != 'active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('وضعیت اشتراک', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isExpired ? Icons.warning : Icons.verified, color: isExpired ? Colors.orange : Colors.green),
              const SizedBox(width: 8),
              Text(isExpired ? 'منقضی شده' : 'فعال'),
            ],
          ),
          const SizedBox(height: 8),
          Text('تاریخ انقضا: ${expiry ?? '--'}', style: const TextStyle(color: Colors.grey)),
          if (isOwner) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    await _repo.updateSubscription(expiryDate: picked, status: 'active');
                    await _load();
                  }
                },
                child: const Text('تمدید/ویرایش تاریخ انقضا'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

