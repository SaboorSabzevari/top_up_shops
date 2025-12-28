import 'package:flutter/material.dart';

import 'add_customer.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  // رنگ‌ها دقیقاً مطابق HTML
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF9F9F9);
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      // ---------- Top App Bar ----------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: bgLight,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F1F1)),
              ),
            ),
            child: Row(
              children: [

                const Expanded(
                  child: Text(
                    'لیست مشتریان',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: textMain),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),

      // ---------- Body ----------
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
              _filterChips(),
              Expanded(child: _customerList()),
            ],
          ),

          // ---------- Bottom Sticky Button ----------
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                elevation: 6,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(context,MaterialPageRoute(builder: (contex)=>AddCustomerPage()));
              },
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'مشتری جدید',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Search Bar ----------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search, color: textSecondary),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'جستجو با نام یا شماره...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Filter Chips ----------
  Widget _filterChips() {
    final filters = ['همه', 'بدهکاران', 'فعال', 'غیرفعال'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? primary : surfaceLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive ? primary : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              filters[index],
              style: TextStyle(
                color: isActive ? Colors.white : textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Customer List ----------
  Widget _customerList() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _customerItem(
          name: 'احمد ولی',
          phone: '0799 123 456',
          amount: '-۲۰۰ ؋',
          amountColor: primary,
          statusDot: Colors.green,
          time: '۱ دقیقه پیش',
        ),
        _customerItem(
          name: 'محمد خان',
          phone: '0700 987 654',
          amount: '۵۰۰ ؋',
        ),
        _pendingItem(),
        _failedItem(),
        _customerItem(
          name: 'حاجی ظاهر',
          phone: '0744 333 111',
          amount: '۱,۲۰۰ ؋',
        ),
        _customerItem(
          name: 'فرید احمد',
          phone: '0766 222 888',
          amount: '۴۵۰ ؋',
        ),
      ],
    );
  }

  // ---------- Customer Tile ----------
  Widget _customerItem({
    required String name,
    required String phone,
    required String amount,
    Color amountColor = textMain,
    Color? statusDot,
    String? time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  name.characters.first,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
              ),
              if (statusDot != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusDot,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textMain,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      phone,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (time != null)
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Pending ----------
  Widget _pendingItem() {
    return _customerItem(
      name: 'سارا جان',
      phone: '0777 111 222',
      amount: '۱۰۰ ؋',
      amountColor: Colors.amber,
      time: 'در انتظار',
    );
  }

  // ---------- Failed ----------
  Widget _failedItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFE5E7EB),
            child: Text('ک'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'کمال‌الدین',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '0788 555 999',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            children: const [
              Icon(Icons.error, color: Colors.red, size: 18),
              SizedBox(width: 4),
              Text('ناموفق', style: TextStyle(color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}
