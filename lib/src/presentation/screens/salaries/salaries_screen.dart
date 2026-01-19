import 'package:flutter/material.dart';

import '../../../data/repository/employee_repository.dart';
import '../../../data/repository/salary_repository.dart';
import '../../theme/colors.dart';

class SalariesScreen extends StatefulWidget {
  const SalariesScreen({super.key});

  @override
  State<SalariesScreen> createState() => _SalariesScreenState();
}

class _SalariesScreenState extends State<SalariesScreen> {
  final SalaryRepository _repo = SalaryRepository();
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contracts = await _repo.getContracts();
    final employees = await _employeeRepo.getEmployees();
    if (!mounted) return;
    setState(() {
      _contracts = contracts;
      _employees = employees;
      _loading = false;
    });
  }

  Future<void> _openContractForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ContractForm(employees: _employees),
    );
    if (result == true) {
      await _load();
    }
  }

  Future<void> _openPaymentForm() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PaymentForm(employees: _employees),
    );
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
        title: const Text('حقوق', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _openPaymentForm,
            icon: const Icon(Icons.payments, color: Colors.black),
          ),
          IconButton(
            onPressed: _openContractForm,
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
                itemCount: _contracts.length,
                itemBuilder: (context, index) {
                  final c = _contracts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade50,
                        child: const Icon(Icons.badge, color: Colors.indigo),
                      ),
                      title: Text(c['employee_uid']?.toString() ?? ''),
                      subtitle: Text('نوع: ${c['type']} - پایه: ${c['base_amount']}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ContractForm extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  const _ContractForm({required this.employees});

  @override
  State<_ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends State<_ContractForm> {
  final SalaryRepository _repo = SalaryRepository();
  final _formKey = GlobalKey<FormState>();
  String? _employeeUid;
  String _type = 'monthly';
  final _baseCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();
  DateTime _effectiveFrom = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.employees.isNotEmpty) {
      _employeeUid = widget.employees.first['uid']?.toString();
    }
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _repo.addContract(
      employeeUid: _employeeUid ?? '',
      type: _type,
      baseAmount: double.tryParse(_baseCtrl.text) ?? 0,
      commissionRate: double.tryParse(_commissionCtrl.text) ?? 0,
      effectiveFrom: _effectiveFrom,
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
              DropdownButtonFormField<String>(
                value: _employeeUid,
                items: widget.employees
                    .map((e) => DropdownMenuItem(value: e['uid']?.toString(), child: Text(e['full_name']?.toString() ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => _employeeUid = value),
                decoration: InputDecoration(
                  labelText: 'کارمند',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('ماهیانه')),
                  DropdownMenuItem(value: 'daily', child: Text('روزانه')),
                  DropdownMenuItem(value: 'commission', child: Text('کمیشن')),
                ],
                onChanged: (value) => setState(() => _type = value ?? 'monthly'),
                decoration: InputDecoration(
                  labelText: 'نوع',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_baseCtrl, 'مبلغ پایه', Icons.payments),
              const SizedBox(height: 12),
              _buildField(_commissionCtrl, 'نرخ کمیشن', Icons.percent),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('شروع قرارداد'),
                subtitle: Text('${_effectiveFrom.toLocal()}'.split(' ')[0]),
                trailing: IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _effectiveFrom,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => _effectiveFrom = picked);
                  },
                  icon: const Icon(Icons.date_range),
                ),
              ),
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

class _PaymentForm extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  const _PaymentForm({required this.employees});

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final SalaryRepository _repo = SalaryRepository();
  final _formKey = GlobalKey<FormState>();
  String? _employeeUid;
  final _amountCtrl = TextEditingController();
  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.employees.isNotEmpty) {
      _employeeUid = widget.employees.first['uid']?.toString();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _repo.addPayment(
      employeeUid: _employeeUid ?? '',
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
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
              DropdownButtonFormField<String>(
                value: _employeeUid,
                items: widget.employees
                    .map((e) => DropdownMenuItem(value: e['uid']?.toString(), child: Text(e['full_name']?.toString() ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => _employeeUid = value),
                decoration: InputDecoration(
                  labelText: 'کارمند',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_amountCtrl, 'مبلغ پرداخت', Icons.payments),
              const SizedBox(height: 12),
              _dateRow('از تاریخ', _periodStart, (d) => setState(() => _periodStart = d)),
              _dateRow('تا تاریخ', _periodEnd, (d) => setState(() => _periodEnd = d)),
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
                  child: const Text('ثبت پرداخت', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _dateRow(String label, DateTime current, ValueChanged<DateTime> onPick) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${current.toLocal()}'.split(' ')[0]),
      trailing: IconButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: current,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 3650)),
          );
          if (picked != null) onPick(picked);
        },
        icon: const Icon(Icons.date_range),
      ),
    );
  }
}

