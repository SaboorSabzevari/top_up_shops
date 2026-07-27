import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../data/local/app_database.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(
          0xfff8f6f6,
        ), // تم خاکستری روشن مشابه صفحه فروش
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "مدیریت موجودی انبار",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- بخش موجودی دیجیتال ---
              _buildSectionHeader(
                Icons.account_balance_wallet_rounded,
                "موجودی کریدیت دیجیتال",
              ),
              _buildDigitalBalanceList(),

              const SizedBox(height: 10),

              // --- بخش موجودی کارت های کاغذی ---
              _buildSectionHeader(Icons.style_rounded, "موجودی کارت‌های کاغذی"),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.getAllPaperStocks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  // گروه‌بندی داده‌ها بر اساس اپراتور (۵ اپراتور)
                  Map<String, List<Map<String, dynamic>>> groupedData = {};
                  for (var item in snapshot.data!) {
                    String op = item['operator_name'].toString().toLowerCase();
                    if (!groupedData.containsKey(op)) groupedData[op] = [];
                    groupedData[op]!.add(item);
                  }

                  // نمایش لیست اپراتورها به صورت عمودی
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groupedData.length,
                    itemBuilder: (context, index) {
                      String opName = groupedData.keys.elementAt(index);
                      return _buildOperatorGroup(opName, groupedData[opName]!);
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // هدر زیبای بخش‌ها
  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // موجودی دیجیتال (کارت‌های افقی)
  Widget _buildDigitalBalanceList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getAllProviderBalances(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, i) {
              final item = snapshot.data![i];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['provider_name'],
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${item['current_balance']} AFN",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // باکس مخصوص هر اپراتور (شامل گرید مبالغ)
  Widget _buildOperatorGroup(String opId, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          // هدر اپراتور
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _getOpIcon(opId),
                const SizedBox(width: 12),
                Text(
                  opId.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // نمایش مبالغ به صورت گرید ۳ تایی
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final card = items[index];
                int qty = card['quantity'] ?? 0;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff8f6f6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${card['face_value']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "؋ ",
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$qty عدد",
                        style: TextStyle(
                          fontSize: 11,
                          color: qty < 5 ? Colors.orange.shade700 : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getOpIcon(String op) {
    String path = 'assets/svg/awcc.svg';
    if (op.contains('roshan'))
      path = 'assets/svg/roshan.svg';
    else if (op.contains('etisalat'))
      path = 'assets/svg/etisalat.svg';
    else if (op.contains('mtn'))
      path = 'assets/svg/atoma.svg';
    else if (op.contains('salaam'))
      path = 'assets/svg/salaam.svg';
    return SvgPicture.asset(path, width: 28, height: 28);
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Text(
          "هیچ کارتی در انبار موجود نیست",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
