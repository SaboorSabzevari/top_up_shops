import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:top_up_shops/src/presentation/screens/transactions/transaction_screen.dart';
import '../../../data/local/app_database.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/session_provider.dart'; // اضافه شد
import '../../../services/smart_avatar.dart';
import '../../../utils/colors.dart';
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
        title: Text(
          'لیست مشتریان',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(ref),
              _filterChips(context, ref, false),
              Expanded(
                child: customersAsync.when(
                  data: (customers) {
                    final shopCustomers = customers
                        .where((c) => c['shop_id'] == user?.shopId)
                        .toList();

                    if (shopCustomers.isEmpty) {
                      return const Center(child: Text("مشتری یافت نشد"));
                    }

                    return _customerList(shopCustomers, user?.shopId ?? '');
                  },
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('خطا: $err')),
                ),
              ),
              SizedBox(height: 55.h),
            ],
          ),
          _buildAddButton(context),
        ],
      ),
    );
  }

  Widget _searchBar(WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16, top: 16.0, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kComponentColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              cursorColor: kPrimaryColor,
              onChanged: (value) {
                ref.read(customerSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                hintText: 'جستجوی نام یا کد مشتری...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12.sp),

                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerList(List<Map<String, dynamic>> customers, String shopId) {
    return ListView.separated(
      // پدینگ کل لیست مشابه لیست تراکنش‌ها
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final profileImage = customer['profile_image']?.toString();
        final bool isWholesale = customer['type'] == 'WHOLESALE';

        return InkWell(
          onTap: () async {
            final fullData = await DatabaseHelper.instance
                .getCustomerFullDetails(
              customer['id'].toString(),
              shopId,
            );
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerPage(customerData: fullData),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 45,
                  height: 45,
                  child: _buildCustomerAvatar(customer['name'], profileImage),
                ),

                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "کد: ${customer['customer_code']}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isWholesale
                        ? kPrimaryColor.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isWholesale ? 'عمده' : 'عادی',
                    style: TextStyle(
                      color: isWholesale ? kPrimaryColor : Colors.blue[700],
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerAvatar(String name, String? profileImagePath) {
    return SmartAvatar(
      path: profileImagePath,
      fallbackText: name,
      radius: 20,
      backgroundColor: primary.withOpacity(0.1),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 14,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: primary,
          minimumSize: Size.fromHeight(45),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AddCustomerPage()),
        ),
        child: const Text('مشتری جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _filterChips(BuildContext context, WidgetRef ref, bool isDark) {
    final activeFilter = ref.watch(customerFilterProvider);
    const Color brandRed = Color(0xFFEA2A33);

    Widget buildChip(String label, String? value) {
      final bool isSelected = activeFilter == value;

      return Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: FilterChip(
          label: Text(label, style: TextStyle(fontSize: 12.sp)),
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      child: Row(
        children: [
          buildChip("همه", null),

          buildChip("عادی", 'ORDINARY'),
          buildChip("عمده", 'WHOLESALE'),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}