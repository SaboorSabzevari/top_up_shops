import 'package:flutter/material.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repository/paper_card_repository.dart';
import '../../../services/session_service.dart';
import '../../theme/colors.dart';

class PaperCardInventoryScreen extends StatefulWidget {
  const PaperCardInventoryScreen({super.key});

  @override
  State<PaperCardInventoryScreen> createState() => _PaperCardInventoryScreenState();
}

class _PaperCardInventoryScreenState extends State<PaperCardInventoryScreen> {
  final PaperCardRepository _repo = PaperCardRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final batches = await _repo.getBatches();
    if (!mounted) return;
    setState(() {
      _batches = batches;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _BatchForm(),
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
        title: const Text('کارت‌های کاغذی', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _openAdd,
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
                itemCount: _batches.length,
                itemBuilder: (context, index) {
                  final b = _batches[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: const Icon(Icons.inventory, color: Colors.green),
                      ),
                      title: Text('بچ #${b['id']} - ${b['face_value']}'),
                      subtitle: Text('باقی: ${b['remaining_qty']} / ${b['quantity']}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _BatchForm extends StatefulWidget {
  const _BatchForm();

  @override
  State<_BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<_BatchForm> {
  final PaperCardRepository _repo = PaperCardRepository();
  final _formKey = GlobalKey<FormState>();
  final _faceValueCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  int? _providerId;
  int? _unitId;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  Future<void> _loadRefs() async {
    final db = await DatabaseHelper.instance.database;
    final shopId = SessionService.instance.currentShopId;
    final providers = await db.query('providers', where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)', whereArgs: [shopId]);
    final units = await db.query('units', where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)', whereArgs: [shopId]);
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _units = units;
      _providerId = providers.isNotEmpty ? providers.first['id'] as int : null;
      _unitId = units.isNotEmpty ? units.first['id'] as int : null;
    });
  }

  @override
  void dispose() {
    _faceValueCtrl.dispose();
    _buyCtrl.dispose();
    _sellCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _repo.addBatch(
      providerId: _providerId ?? 1,
      unitId: _unitId ?? 1,
      faceValue: double.tryParse(_faceValueCtrl.text) ?? 0,
      buyPrice: double.tryParse(_buyCtrl.text) ?? 0,
      sellPrice: double.tryParse(_sellCtrl.text) ?? 0,
      quantity: int.tryParse(_qtyCtrl.text) ?? 0,
    );
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
              DropdownButtonFormField<int>(
                value: _providerId,
                items: _providers
                    .map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['name']?.toString() ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => _providerId = value),
                decoration: InputDecoration(
                  labelText: 'اپراتور',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _unitId,
                items: _units
                    .map((u) => DropdownMenuItem(value: u['id'] as int, child: Text(u['name']?.toString() ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => _unitId = value),
                decoration: InputDecoration(
                  labelText: 'واحد',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_faceValueCtrl, 'مقدار کارت', Icons.credit_card),
              const SizedBox(height: 12),
              _buildField(_buyCtrl, 'قیمت خرید', Icons.shopping_cart),
              const SizedBox(height: 12),
              _buildField(_sellCtrl, 'قیمت فروش', Icons.sell),
              const SizedBox(height: 12),
              _buildField(_qtyCtrl, 'تعداد', Icons.numbers),
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
                  child: const Text('ثبت بچ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
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
