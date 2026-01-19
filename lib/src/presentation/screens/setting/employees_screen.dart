import 'package:flutter/material.dart';

import '../../../data/repository/employee_repository.dart';
import '../../../data/repository/role_repository.dart';
import '../../theme/colors.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeRepository _repo = EmployeeRepository();
  final RoleRepository _roleRepo = RoleRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employees = await _repo.getEmployees();
    final roles = await _roleRepo.getRoles();
    if (!mounted) return;
    setState(() {
      _employees = employees;
      _roles = roles;
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
      builder: (ctx) => _EmployeeForm(
        roles: _roles,
        existing: existing,
      ),
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
        title: const Text('کارمندان', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  final e = _employees[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(e['full_name']?.toString() ?? ''),
                      subtitle: Text(e['role_id']?.toString() ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openForm(existing: e),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _EmployeeForm extends StatefulWidget {
  final List<Map<String, dynamic>> roles;
  final Map<String, dynamic>? existing;

  const _EmployeeForm({required this.roles, this.existing});

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _repo = EmployeeRepository();
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _roleId;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _uidCtrl.text = existing['uid']?.toString() ?? '';
      _nameCtrl.text = existing['full_name']?.toString() ?? '';
      _phoneCtrl.text = existing['phone']?.toString() ?? '';
      _emailCtrl.text = existing['email']?.toString() ?? '';
      _roleId = existing['role_id']?.toString();
      _status = existing['status']?.toString() ?? 'active';
    } else if (widget.roles.isNotEmpty) {
      _roleId = widget.roles.first['id']?.toString();
    }
  }

  @override
  void dispose() {
    _uidCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.existing != null;
    if (isEdit) {
      await _repo.updateEmployee(
        uid: _uidCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        roleId: _roleId ?? 'cashier',
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        status: _status,
      );
    } else {
      await _repo.addEmployee(
        uid: _uidCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        roleId: _roleId ?? 'cashier',
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
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
              _buildField(_uidCtrl, 'شناسه کارمند (UID)', Icons.badge, enabled: widget.existing == null),
              const SizedBox(height: 12),
              _buildField(_nameCtrl, 'نام کامل', Icons.person),
              const SizedBox(height: 12),
              _buildField(_phoneCtrl, 'شماره تماس', Icons.call),
              const SizedBox(height: 12),
              _buildField(_emailCtrl, 'ایمیل', Icons.email),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _roleId,
                items: widget.roles
                    .map((r) => DropdownMenuItem(value: r['id']?.toString(), child: Text(r['name']?.toString() ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => _roleId = value),
                decoration: InputDecoration(
                  labelText: 'نقش',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('فعال')),
                  DropdownMenuItem(value: 'inactive', child: Text('غیرفعال')),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'active'),
                decoration: InputDecoration(
                  labelText: 'وضعیت',
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
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

