import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../providers/customer_provider.dart';
import 'add_customer.dart';

class CustomerListPage extends ConsumerWidget {
  const CustomerListPage({super.key});

  static const Color primary = Color(0xFFEA2A33);
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerSearchResults);
    final activeFilter = ref.watch(customerFilterProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('لیست مشتریان', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: textMain,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _searchBar(ref),
                _filterChips(ref), // اصلاح شده برای کارکرد فیلتر
                Expanded(
                  child: customersAsync.when(
                    data: (customers) {
                      // اعمال فیلتر دکان‌دار/عادی روی لیست دریافتی
                      final filteredList = customers.where((c) {
                        if (activeFilter == 'همه') return true;
                        if (activeFilter == 'دکان‌دار') return c['type'] == 'WHOLESALE';
                        if (activeFilter == 'عادی') return c['type'] == 'ORDINARY';
                        return true;
                      }).toList();

                      return _buildCustomerList(filteredList, ref);
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: primary)),
                    error: (err, _) => Center(child: Text('خطا: $err')),
                  ),
                ),
              ],
            ),
            _buildAddButton(context),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (v) => ref.read(customerSearchQuery.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'جستجو با نام یا کد...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _filterChips(WidgetRef ref) {
    final filters = ['همه', 'دکان‌دار', 'عادی'];
    final activeFilter = ref.watch(customerFilterProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final label = filters[index];
          final isSelected = activeFilter == label;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,

              selectedColor: primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : textSecondary),
              onSelected: (selected) {
                if (selected) ref.read(customerFilterProvider.notifier).state = label;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerList(List<dynamic> customers, WidgetRef ref) {
    if (customers.isEmpty) return const Center(child: Text('موردی یافت نشد'));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index] as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: customer['profile_image'] != null
                ? FileImage(File(customer['profile_image'])) : null,
            child: customer['profile_image'] == null
                ? Text(customer['name'][0], style: const TextStyle(color: textMain)) : null,
          ),
          title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("کد: ${customer['customer_code']} | ${customer['type'] == 'WHOLESALE' ? 'دکان‌دار' : 'عادی'}"),
          trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // ۱. گرفتن دیتای کامل از دیتابیس
              final fullData = await DatabaseHelper.instance.getCustomerFullDetails(customer['id']);

              // ۲. رفتن به صفحه با دیتای موجود
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerPage(customerData: fullData),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Positioned(
      left: 16, right: 16, bottom: 24,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primary, minimumSize: const Size.fromHeight(54)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddCustomerPage())),
        child: const Text('مشتری جدید', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}