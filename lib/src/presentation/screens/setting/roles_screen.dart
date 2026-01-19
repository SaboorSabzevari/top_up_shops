import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../data/repository/role_repository.dart';
import '../../theme/colors.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final RoleRepository _repo = RoleRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _roles = [];

  static const _permissions = [
    'tx.create',
    'tx.refund',
    'customers.write',
    'reports.view',
    'inventory.write',
    'suppliers.write',
    'salaries.write',
    'employees.write',
    'settings.write',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roles = await _repo.getRoles();
    if (!mounted) return;
    setState(() {
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
      builder: (ctx) => _RoleForm(existing: existing),
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
        title: const Text('نقش‌ها', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final r = _roles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(Icons.security, color: Colors.orange),
                      ),
                      title: Text(r['name']?.toString() ?? ''),
                      subtitle: Text(_formatPermissions(r['permissions_json']?.toString())),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openForm(existing: r),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatPermissions(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.join('، ');
    } catch (_) {
      return '';
    }
  }
}

class _RoleForm extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _RoleForm({this.existing});

  @override
  State<_RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<_RoleForm> {
  final RoleRepository _repo = RoleRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final Map<String, bool> _selected = {
    for (final p in _RolesScreenState._permissions) p: false,
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing['name']?.toString() ?? '';
      final raw = existing['permissions_json']?.toString() ?? '[]';
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        for (final p in list) {
          _selected[p] = true;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final permissions = _selected.entries.where((e) => e.value).map((e) => e.key).toList();
    if (widget.existing == null) {
      await _repo.addRole(name: _nameCtrl.text.trim(), permissions: permissions);
    } else {
      await _repo.updateRole(
        id: widget.existing!['id'].toString(),
        name: _nameCtrl.text.trim(),
        permissions: permissions,
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
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => v == null || v.trim().isEmpty ? 'اجباری است' : null,
                decoration: InputDecoration(
                  labelText: 'نام نقش',
                  prefixIcon: const Icon(Icons.badge, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8F6F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8F6F6), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: _selected.keys.map((perm) {
                    return CheckboxListTile(
                      dense: true,
                      value: _selected[perm],
                      onChanged: (value) => setState(() => _selected[perm] = value ?? false),
                      title: Text(perm),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
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
}

