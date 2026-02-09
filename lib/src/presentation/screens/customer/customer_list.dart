import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/local/app_database.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/session_provider.dart'; // اضافه شد
import 'add_customer.dart';

class CustomerListPage extends ConsumerWidget {
  const CustomerListPage({super.key});

  static const Color primary = Color(0xFFEA2A33);
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final customersAsync = ref.watch(customerSearchResults);
    final activeFilter = ref.watch(customerFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'لیست مشتریان',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              _filterChips(context,ref,false),
              Expanded(
                child: customersAsync.when(
                  data: (customers) {
                    // ۲. فیلتر کردن نهایی بر اساس ShopID (لایه دوم امنیتی)
                    final shopCustomers = customers
                        .where((c) => c['shop_id'] == user?.shopId)
                        .toList();

                    if (shopCustomers.isEmpty) {
                      return const Center(child: Text("مشتری یافت نشد"));
                    }

                    return _customerList(shopCustomers);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('خطا: $err')),
                ),
              ),
              const SizedBox(height: 80), // فضا برای دکمه پایین
            ],
          ),
          _buildAddButton(context),
        ],
      ),
    );
  }

  // اصلاح بخش جستجو برای ارسال ShopID
  Widget _searchBar(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          // در اینجا باید پروایدر جستجوی شما shopId را هم در نظر بگیرد
          ref.read(customerSearchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'جستجوی نام یا کد مشتری...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _customerList(List<Map<String, dynamic>> customers) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final customer = customers[index];

        // دریافت مسیر عکس مشتری
        final profileImage = customer['profile_image']?.toString();

        return ListTile(
          leading: _buildCustomerAvatar(customer['name'], profileImage),
          title: Text(
            customer['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "کد: ${customer['customer_code']} | ${customer['type'] == 'WHOLESALE' ? 'عمده' : 'عادی'}",
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            // ۳. دریافت جزئیات با امنیت ShopID
            final fullData = await DatabaseHelper.instance
                .getCustomerFullDetails(customer['id']);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerPage(customerData: fullData),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCustomerAvatar(String name, String? profileImagePath) {
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      try {
        final file = File(profileImagePath);
        if (file.existsSync()) {
          return CircleAvatar(
            backgroundImage: FileImage(file),
            radius: 20,
          );
        }
      } catch (e) {
        // اگر خطایی در خواندن فایل رخ داد، حرف اول را نمایش بده
      }
    }

    // اگر عکس وجود نداشت، حرف اول نام را نمایش بده
    final firstChar = name.isNotEmpty ? name[0] : '?';
    return CircleAvatar(
      backgroundColor: primary.withOpacity(0.1),
      child: Text(
        firstChar,
        style: const TextStyle(color: primary),
      ),
    );
  }  Widget _buildAddButton(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: primary,
          minimumSize: const Size.fromHeight(54),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AddCustomerPage()),
        ),
        child: const Text('مشتری جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // متد فیلترها (فرض بر این است که منطق آن در customerFilterProvider است)
  Widget _filterChips(
      BuildContext context,
      WidgetRef ref,
      bool isDark,
      ) {
    final activeFilter = ref.watch(customerFilterProvider);
    const Color brandRed = Color(0xFFEA2A33);

    Widget buildChip(String label, String? value) {
      final bool isSelected = activeFilter == value;

      return Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(fontSize: 12.sp),
          ),
          selected: isSelected,
          onSelected: (_) =>
          ref.read(customerFilterProvider.notifier).state = value,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12.sp,
          ),
          selectedColor: brandRed,
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade100,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(
              color: isSelected ? brandRed : Colors.transparent,
              width: 1.w,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 4.h,
          ),
          labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      child: Row(
        children: [
          buildChip("همه", null),

          buildChip("عادی", 'ORDINARY'),  buildChip("عمده", 'WHOLESALE'),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}