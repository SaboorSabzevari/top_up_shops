import 'package:flutter/material.dart';

import '../../../data/repository/supplier_repository.dart';
import '../../theme/colors.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SupplierRepository _repo = SupplierRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final suppliers = await _repo.getSuppliers();
    if (!mounted) return;
    setState(() {
      _suppliers = suppliers;
      _loading = false;
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SupplierForm(existing: existing),
    );
    if (result == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F6F6);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('تامین‌کنندگان', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _suppliers.length,
                itemBuilder: (context, index) {
                  final s = _suppliers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade50,
                        child: const Icon(Icons.local_shipping, color: Colors.purple),
                      ),
                      title: Text(s['name']?.toString() ?? ''),
                      subtitle: Text('مانده: ${s['balance_cache'] ?? 0}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openForm(existing: s);
                          } else if (value == 'purchase') {
                            await _openAmountDialog(s, isPurchase: true);
                          } else if (value == 'payment') {
                            await _openAmountDialog(s, isPurchase: false);
                          }
                          await _load();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                          const PopupMenuItem(value: 'purchase', child: Text('ثبت خرید')),
                          const PopupMenuItem(value: 'payment', child: Text('ثبت پرداخت')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _openAmountDialog(Map<String, dynamic> supplier, {required bool isPurchase}) async {
    final amountCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isPurchase ? 'ثبت خرید' : 'ثبت پرداخت'),
          content: TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لغو')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
          ],
        );
      },
    );
    if (result != true) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    if (isPurchase) {
      await _repo.recordPurchase(supplierId: supplier['id'] as int, amount: amount);
    } else {
      await _repo.recordPayment(supplierId: supplier['id'] as int, amount: amount);
    }
  }
}

class _SupplierForm extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _SupplierForm({this.existing});

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  final SupplierRepository _repo = SupplierRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing['name']?.toString() ?? '';
      _phoneCtrl.text = existing['phone']?.toString() ?? '';
      _addressCtrl.text = existing['address']?.toString() ?? '';
      _creditCtrl.text = existing['credit_limit']?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _creditCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existing == null) {
      await _repo.addSupplier(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        creditLimit: double.tryParse(_creditCtrl.text) ?? 0,
      );
    } else {
      await _repo.updateSupplier(
        id: widget.existing!['id'] as int,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        creditLimit: double.tryParse(_creditCtrl.text),
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 40, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              _buildField(_nameCtrl, 'نام تامین‌کننده', Icons.store),
              const SizedBox(height: 12),
              _buildField(_phoneCtrl, 'شماره تماس', Icons.call),
              const SizedBox(height: 12),
              _buildField(_addressCtrl, 'آدرس', Icons.location_on),
              const SizedBox(height: 12),
              _buildField(_creditCtrl, 'حد اعتبار', Icons.credit_card, isNumber: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
}
