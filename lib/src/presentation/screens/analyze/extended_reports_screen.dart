import 'package:flutter/material.dart';

import '../../../data/repository/report_repository.dart';

class ExtendedReportsScreen extends StatefulWidget {
  const ExtendedReportsScreen({super.key});

  @override
  State<ExtendedReportsScreen> createState() => _ExtendedReportsScreenState();
}

class _ExtendedReportsScreenState extends State<ExtendedReportsScreen> {
  final ReportRepository _repo = ReportRepository();
  DateTimeRange? _range;
  bool _loading = true;
  num _cashIn = 0;
  num _cashOut = 0;
  num _profit = 0;
  num _inventoryValue = 0;
  num _supplierBalance = 0;
  List<Map<String, dynamic>> _employeePerf = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cashflow = await _repo.getCashflow(
      start: _range?.start,
      end: _range?.end,
    );
    final profit = await _repo.getProfit(
      start: _range?.start,
      end: _range?.end,
    );
    final inventory = await _repo.getInventoryValue();
    final supplier = await _repo.getSupplierBalance();
    final perf = await _repo.getEmployeePerformance(
      start: _range?.start,
      end: _range?.end,
    );
    if (!mounted) return;
    setState(() {
      _cashIn = cashflow['cash_in'] ?? 0;
      _cashOut = cashflow['cash_out'] ?? 0;
      _profit = profit;
      _inventoryValue = inventory;
      _supplierBalance = supplier;
      _employeePerf = perf;
      _loading = false;
    });
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
        title: const Text('گزارش‌های مالی', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) {
                setState(() => _range = picked);
                await _load();
              }
            },
            icon: const Icon(Icons.date_range, color: Colors.black),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _reportCard('نقد ورودی', _cashIn),
                  _reportCard('نقد خروجی', _cashOut),
                  _reportCard('سود خالص', _profit),
                  _reportCard('ارزش موجودی کارت', _inventoryValue),
                  _reportCard('مانده تامین‌کنندگان', _supplierBalance),
                  const SizedBox(height: 8),
                  const Text('عملکرد کارمندان', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_employeePerf.isEmpty)
                    const Text('داده‌ای موجود نیست', style: TextStyle(color: Colors.grey))
                  else
                    ..._employeePerf.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e['employee_name']?.toString() ?? e['employee_id']?.toString() ?? ''),
                            Text('تعداد: ${e['tx_count'] ?? 0}'),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _reportCard(String title, num value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$value', style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
