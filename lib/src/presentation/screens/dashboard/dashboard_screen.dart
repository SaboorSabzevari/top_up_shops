import 'package:flutter/material.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/send_credit/send_credit_screen.dart';



class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Colors (from HTML)
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Color(0xFFF8F6F6);
  static const Color surfaceLight = Colors.white;
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(child: _content(context)),
          ],
        ),
      ),
    );
  }

  // ---------------- Top Bar ----------------

  Widget _topBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: bgLight,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_forward, color: textMain),
          ),
          const Expanded(
            child: Text(
              'مدیریت کارت‌ها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.filter_list, color: textMain),
          ),
        ],
      ),
    );
  }

  // ---------------- Main Content ----------------

  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('موجودی فعلی'),
          const SizedBox(height: 12),
          _inventoryCards(),
          const SizedBox(height: 28),
          _sectionTitle('اقدامات سریع'),
          const SizedBox(height: 12),
          _quickActions(context),
          const SizedBox(height: 28),
          _sectionTitle('تراکنش‌های اخیر'),
          const SizedBox(height: 12),
          _transactions(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textMain,
      ),
    );
  }

  // ---------------- Inventory ----------------

  Widget _inventoryCards() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _InventoryCard(
            title: 'روشن',
            count: '۱۴۵',
            color: Color(0xFFC1272D),
            trend: '+۱۲',
          ),
          _InventoryCard(
            title: 'اتصالات',
            count: '۸',
            color: Color(0xFF8CB920),
            trend: 'کمبود',
            warning: true,
          ),
          _InventoryCard(
            title: 'ام‌تی‌ان',
            count: '۸۹',
            color: Color(0xFFFFCC00),
            trend: '-۵',
          ),
        ],
      ),
    );
  }

  // ---------------- Quick Actions ----------------

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            title: 'فروش کارت',
            subtitle: 'ثبت فروش تکی',
            icon: Icons.point_of_sale,
            color: primary, onPressed:(){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>DigitalTopupSalePage()));
          },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            title: 'خرید عمده',
            subtitle: 'افزودن موجودی',
            icon: Icons.inventory_2,
            color: const Color(0xFF1F2937), onPressed: (){},
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required final Function onPressed,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap:(){
        onPressed();
      },
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Transactions ----------------

  Widget _transactions() {
    return Column(
      children: const [
        _TransactionItem(
          title: 'فروش کارت ۵۰ افغانی',
          brand: 'روشن',
          time: '۱۰:۳۰',
          amount: '+۵۰ ؋',
          success: true,
        ),
        _TransactionItem(
          title: 'خرید عمده (۱۰۰ عدد)',
          brand: 'ام‌تی‌ان',
          time: '۰۹:۱۵',
          amount: '-۴۵۰۰ ؋',
          pending: true,
        ),
        _TransactionItem(
          title: 'فروش ناموفق',
          brand: 'اتصالات',
          time: 'دیروز',
          amount: '۱۰۰ ؋',
          failed: true,
        ),
      ],
    );
  }

}

// ================= Components =================

class _InventoryCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final String trend;
  final bool warning;

  const _InventoryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.trend,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardPage.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          right: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: DashboardPage.textSecondary,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(count,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: DashboardPage.textMain)),
          const SizedBox(height: 4),
          Text(trend,
              style: TextStyle(
                color: warning ? DashboardPage.primary : Colors.green,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title, brand, time, amount;
  final bool success, pending, failed;

  const _TransactionItem({
    required this.title,
    required this.brand,
    required this.time,
    required this.amount,
    this.success = false,
    this.pending = false,
    this.failed = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = success
        ? Colors.green
        : pending
        ? Colors.orange
        : DashboardPage.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardPage.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(Icons.receipt, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: DashboardPage.textMain)),
                Text('$brand • $time',
                    style: const TextStyle(
                        fontSize: 12,
                        color: DashboardPage.textSecondary)),
              ],
            ),
          ),
          Text(amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }
}
