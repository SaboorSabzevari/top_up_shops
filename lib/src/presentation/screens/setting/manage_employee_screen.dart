// مسیر پیشنهادی: lib/src/presentation/screens/setting/manage_employees_screen.dart
//
// صفحه‌ی مخصوص مدیر (OWNER) برای:
//   - دیدن لیست کارمندان همین دکان
//   - تغییر دسترسی‌های هر کارمند (سود، نرخ‌ها، خرید، گزارش‌ها)
//   - غیرفعال‌کردن آنی دسترسی یک کارمند (بدون نیاز به اسکریپت/کنسول)
//
// ساخت کارمند جدید همچنان با اسکریپت 03_add_employee.js انجام می‌شود؛
// چون ساختن کاربر Firebase Auth از داخل اپ کلاینت باعث می‌شود شما
// (مدیر) از حساب خودتان خارج و وارد حساب کارمند تازه‌ساز شوید که تجربه‌ی
// خوبی نیست. این صفحه فقط دسترسیِ کارمندهای already-موجود را مدیریت می‌کند.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/premissions.dart';
import '../../../providers/session_provider.dart';
import '../../../services/async_helper.dart';
import '../../theme/colors.dart';

final shopEmployeesProvider =
FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
    ref,
    shopId,
    ) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('shopId', isEqualTo: shopId)
      .get();
  return snap.docs.map((d) {
    final data = Map<String, dynamic>.from(d.data());
    data['uid'] = d.id;
    return data;
  }).toList();
});

class ManageEmployeesScreen extends ConsumerWidget {
  const ManageEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);

    if (me == null || !me.isOwner) {
      // فقط مدیر اجازه‌ی دیدن این صفحه را دارد
      return Scaffold(
        appBar: AppBar(title: const Text('مدیریت کارمندان')),
        body: const Center(
          child: Text('این بخش فقط برای مدیر فروشگاه در دسترس است.'),
        ),
      );
    }

    final employeesAsync = ref.watch(shopEmployeesProvider(me.shopId));

    return Scaffold(
      backgroundColor: const Color(0xffF8F6F6),
      appBar: AppBar(
        title: const Text('مدیریت کارمندان'),
        centerTitle: true,
        backgroundColor: const Color(0xffF8F6F6),
        elevation: 0,
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا: $e')),
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text('هنوز کارمندی ثبت نشده است.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final emp = employees[i];
              return _EmployeeCard(
                employee: emp,
                shopId: me.shopId,
                isSelf: emp['uid'] == me.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String shopId;
  final bool isSelf;

  const _EmployeeCard({
    required this.employee,
    required this.shopId,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = (employee['role'] ?? 'STAFF').toString();
    final active = employee['active'] == null ? true : employee['active'] == true;
    final name = (employee['name'] ?? employee['email'] ?? '---').toString();
    final email = (employee['email'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: active
                    ? kPrimaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                child: Icon(
                  role == 'OWNER' ? Icons.star : Icons.person,
                  color: active ? kPrimaryColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name + (isSelf ? ' (شما)' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Chip(
                label: Text(role == 'OWNER' ? 'مدیر' : 'کارمند'),
                backgroundColor: role == 'OWNER'
                    ? Colors.amber.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.1),
              ),
            ],
          ),
          if (role != 'OWNER') ...[
            const Divider(height: 24),
            ...PermissionKeys.all
                .where((k) => k != PermissionKeys.canManageEmployees)
                .map((key) {
              final current = (employee['permissions'] as Map?)?[key] == true;
              return SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  PermissionKeys.labels[key] ?? key,
                  style: const TextStyle(fontSize: 13),
                ),
                value: current,
                activeColor: kPrimaryColor,
                onChanged: !isSelf
                    ? (val) => _updatePermission(context, ref, key, val)
                    : null,
              );
            }),
            const SizedBox(height: 4),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'دسترسی فعال (اگر خاموش کنید، دیگر نمی‌تواند وارد شود)',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
              value: active,
              activeColor: Colors.red,
              onChanged: !isSelf ? (val) => _updateActive(context, ref, val) : null,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updatePermission(
      BuildContext context,
      WidgetRef ref,
      String key,
      bool value,
      ) async {
    await runGuarded(() async {
      final currentPerms = Map<String, dynamic>.from(
        (employee['permissions'] as Map?) ?? kDefaultStaffPermissions,
      );
      currentPerms[key] = value;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employee['uid'])
          .update({'permissions': currentPerms});
      ref.invalidate(shopEmployeesProvider(shopId));
    }, successMessage: 'دسترسی به‌روزرسانی شد');
  }

  Future<void> _updateActive(BuildContext context, WidgetRef ref, bool value) async {
    await runGuarded(() async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employee['uid'])
          .update({'active': value});
      ref.invalidate(shopEmployeesProvider(shopId));
    }, successMessage: value ? 'دسترسی کارمند فعال شد' : 'دسترسی کارمند غیرفعال شد');
  }
}