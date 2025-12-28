import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entity/customer.dart';
import '../../../domain/entity/enums.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});
  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF9F9F9);
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  CustomerType _type = CustomerType.wholesale;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCodeCtrl = TextEditingController();
  final List<String> _phones = [];

  late final String _customerCode;

  @override
  void initState() {
    super.initState();
    _customerCode = _generateCustomerCode();
  }

  String _generateCustomerCode() {
    final prefix = _type == CustomerType.normal ? 'CUST' : 'WH';
    return '$prefix-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  void _save() {
    final customer = _type == CustomerType.normal
        ? Customer.normal(
            id: const Uuid().v4(),
            name: _nameCtrl.text,
            code: _customerCode,
            phones: _phones,
          )
        : Customer.wholesale(
            id: const Uuid().v4(),
            name: _nameCtrl.text,
            code: _customerCode,
            companyCode: _companyCodeCtrl.text,
          );

    debugPrint(customer.toJson().toString());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgLight,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(child: _content()),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI ----------

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: textMain),
          ),
          const Expanded(
            child: Text(
              'افزودن مشتری جدید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _customerTypeSelector(),
          const SizedBox(height: 24),
          _input(
            controller: _nameCtrl,
            label: 'نام کامل',
            hint: 'نام مشتری را وارد کنید',
            icon: Icons.person,
          ),
          const SizedBox(height: 20),
          if (_type == CustomerType.normal) _phoneSection(),
          if (_type == CustomerType.wholesale)
            _input(
              controller: _companyCodeCtrl,
              label: 'کد شرکت',
              hint: 'کد شرکت را وارد کنید',
              icon: Icons.business,
            ),
          const SizedBox(height: 20),
          _readonlyInput(
            label: 'کد مشتری',
            value: _customerCode,
            icon: Icons.lock,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _customerTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
      ),
      child: Row(
        children: CustomerType.values.map((type) {
          final selected = _type == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = type),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  type == CustomerType.normal ? 'مشتری عادی' : 'مشتری عمده',
                  style: TextStyle(
                    color: selected ? Colors.white : textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _phoneSection() {
    return Column(
      children: [
        _input(
          controller: _phoneCtrl,
          label: 'شماره تماس',
          hint: '7XXXXXXXX',
          icon: Icons.call,
          keyboardType: TextInputType.phone,
          onSubmitted: (_) {
            setState(() {
              _phones.add(_phoneCtrl.text);
              _phoneCtrl.clear();
            });
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _phones
              .map(
                (p) => Chip(
                  label: Text(p),
                  backgroundColor: surfaceLight,
                  deleteIconColor: textSecondary,
                  onDeleted: () => setState(() => _phones.remove(p)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: textMain),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textSecondary),
            hintText: hint,
            hintStyle: const TextStyle(color: textSecondary),
            filled: true,
            fillColor: surfaceLight,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _readonlyInput({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          enabled: false,
          controller: TextEditingController(text: value),
          style: const TextStyle(color: textSecondary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: textSecondary),
            filled: true,
            fillColor: surfaceLight,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.save, color: bgLight,),
          label: const Text(
            'ذخیره کردن مشتری',
            style: TextStyle(
                color: bgLight,
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
