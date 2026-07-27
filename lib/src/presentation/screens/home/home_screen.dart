import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:top_up_shops/src/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:top_up_shops/src/presentation/theme/colors.dart'
    hide kPrimaryColor;

import '../analyze/analyze_screen.dart';
import '../customer/customer_list.dart';
import '../setting/setting_screen.dart';
import '../transactions/transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  // لیست صفحات اصلی
  List<Widget> _buildScreens() {
    return [
      DashboardScreen(),
      CustomerListPage(),
      TransactionHistoryPage(),
      CustomerReportScreen(),
      SettingsScreen(),
    ];
  }

  // آیتم‌های نویگیشن بار
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.dashboard),
        title: "داشبورد",
        activeColorPrimary: kPrimaryColor,
        inactiveColorPrimary: Colors.grey,

        iconSize: 26,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.people),
        title: "مشتریان",
        activeColorPrimary: kPrimaryColor,
        inactiveColorPrimary: Colors.grey,

        iconSize: 26,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.currency_exchange_outlined),
        title: "تراکنش‌ها",
        activeColorPrimary: kPrimaryColor,
        inactiveColorPrimary: Colors.grey,
        activeColorSecondary: Colors.white,

        iconSize: 26,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.bar_chart_outlined),
        title: "گزارش‌ها",
        activeColorPrimary: kPrimaryColor,
        inactiveColorPrimary: Colors.grey,

        iconSize: 26,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings),
        title: "تنظیمات",
        activeColorPrimary: kPrimaryColor,
        inactiveColorPrimary: Colors.grey,

        iconSize: 26,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      hideNavigationBarWhenKeyboardAppears: false,
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),

      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,

      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(16.0),
        colorBehindNavBar: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),

      navBarStyle: NavBarStyle.style16, // استایل 16 معادل style15 است
      navBarHeight: 70,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }

  // ----------------- صفحات -----------------

  Widget _buildTransactionsPage() {
    return Scaffold(
      body: SafeArea(child: Center(child: Text("Customer"))),

      // backgroundColor: Colors.grey.shade50,
      // appBar: AppBar(
      //   title: const Text('تراکنش‌ها'),
      //   backgroundColor: Colors.orange,
      //   foregroundColor: Colors.white,
      //   elevation: 2,
      //   actions: [
      //     IconButton(
      //       onPressed: () {},
      //       icon: const Icon(Icons.filter_list),
      //     ),
      //   ],
      // ),
      // body: Column(
      //   children: [
      //     Padding(
      //       padding: const EdgeInsets.all(16),
      //       child: Row(
      //         children: [
      //           Expanded(
      //             child: ElevatedButton.icon(
      //               onPressed: () {},
      //               icon: const Icon(Icons.add),
      //               label: const Text('فروش جدید'),
      //               style: ElevatedButton.styleFrom(
      //                 backgroundColor: Colors.orange,
      //                 foregroundColor: Colors.white,
      //                 padding: const EdgeInsets.symmetric(vertical: 12),
      //               ),
      //             ),
      //           ),
      //           const SizedBox(width: 12),
      //           Expanded(
      //             child: ElevatedButton.icon(
      //               onPressed: () {},
      //               icon: const Icon(Icons.payment),
      //               label: const Text('پرداخت'),
      //               style: ElevatedButton.styleFrom(
      //                 backgroundColor: Colors.green,
      //                 foregroundColor: Colors.white,
      //                 padding: const EdgeInsets.symmetric(vertical: 12),
      //               ),
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),
      //     Expanded(
      //       child: ListView.builder(
      //         padding: const EdgeInsets.all(16),
      //         itemCount: 15,
      //         itemBuilder: (context, index) {
      //           return Card(
      //             margin: const EdgeInsets.only(bottom: 8),
      //             child: ListTile(
      //               leading: CircleAvatar(
      //                 backgroundColor: index % 3 == 0
      //                     ? Colors.green.shade100
      //                     : Colors.orange.shade100,
      //                 child: Icon(
      //                   index % 3 == 0 ? Icons.arrow_downward : Icons.arrow_upward,
      //                   color: index % 3 == 0 ? Colors.green : Colors.orange,
      //                 ),
      //               ),
      //               title: Text('تراکنش #${1000 + index}'),
      //               subtitle: Text('${index + 1} ساعت قبل'),
      //               trailing: Column(
      //                 mainAxisSize: MainAxisSize.min,
      //                 crossAxisAlignment: CrossAxisAlignment.end,
      //                 children: [
      //                   Text(
      //                     '${(index + 1) * 15000}',
      //                     style: const TextStyle(
      //                       fontWeight: FontWeight.bold,
      //                       fontSize: 16,
      //                     ),
      //                   ),
      //                   Text(
      //                     index % 3 == 0 ? 'واریز' : 'برداشت',
      //                     style: TextStyle(
      //                       color: index % 3 == 0 ? Colors.green : Colors.orange,
      //                       fontSize: 12,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           );
      //         },
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildReportsPage() {
    return Scaffold(
      body: SafeArea(child: Center(child: Text("report"))),

      //   backgroundColor: Colors.grey.shade50,
      //   appBar: AppBar(
      //     title: const Text('گزارش‌ها'),
      //     backgroundColor: Colors.purple,
      //     foregroundColor: Colors.white,
      //     elevation: 2,
      //   ),
      //   body: Padding(
      //     padding: const EdgeInsets.all(20),
      //     child: GridView.count(
      //       crossAxisCount: 2,
      //       crossAxisSpacing: 16,
      //       mainAxisSpacing: 16,
      //       children: [
      //         _buildReportCard(
      //           title: 'گزارش فروش',
      //           icon: Icons.shopping_cart,
      //           color: Colors.blue,
      //         ),
      //         _buildReportCard(
      //           title: 'گزارش مالی',
      //           icon: Icons.account_balance_wallet,
      //           color: Colors.green,
      //         ),
      //         _buildReportCard(
      //           title: 'گزارش مشتریان',
      //           icon: Icons.people,
      //           color: Colors.orange,
      //         ),
      //         _buildReportCard(
      //           title: 'گزارش موجودی',
      //           icon: Icons.inventory,
      //           color: Colors.purple,
      //         ),
      //         _buildReportCard(
      //           title: 'گزارش کارمندان',
      //           icon: Icons.badge,
      //           color: Colors.red,
      //         ),
      //         _buildReportCard(
      //           title: 'گزارش کلی',
      //           icon: Icons.summarize,
      //           color: Colors.teal,
      //         ),
      //       ],
      //     ),
      //   ),
    );
  }

  Widget _buildSettingsPage() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('تنظیمات'),
        backgroundColor: Colors.grey.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingItem(
            icon: Icons.person,
            title: 'پروفایل',
            subtitle: 'مدیریت اطلاعات شخصی',
            color: Colors.blue,
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'اعلان‌ها',
            subtitle: 'تنظیمات هشدارها',
            color: Colors.orange,
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: 'زبان',
            subtitle: 'تغییر زبان برنامه',
            color: Colors.green,
          ),
          _buildSettingItem(
            icon: Icons.security,
            title: 'امنیت',
            subtitle: 'رمز عبور و احراز هویت',
            color: Colors.red,
          ),
          _buildSettingItem(
            icon: Icons.backup,
            title: 'پشتیبان‌گیری',
            subtitle: 'تهیه نسخه پشتیبان',
            color: Colors.purple,
          ),
          _buildSettingItem(
            icon: Icons.help,
            title: 'راهنما و پشتیبانی',
            subtitle: 'تماس با ما',
            color: Colors.teal,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- کامپوننت‌های کمکی -----------------

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(unit, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 30,
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
