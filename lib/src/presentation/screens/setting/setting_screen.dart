import 'dart:io'; // برای نمایش عکس از فایل
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/local_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../data/repository/shop_repository.dart';
import '../../theme/colors.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart' hide kPrimaryColor;
import 'package:top_up_shops/src/presentation/screens/setting/unit_screen.dart';
import 'shop_profile_screen.dart';
import 'employees_screen.dart';
import 'roles_screen.dart';
import '../inventory/paper_card_inventory_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../suppliers/assets_screen.dart';
import '../salaries/salaries_screen.dart';
import 'sync_status_screen.dart';

// 1. تعریف یک Provider برای خواندن اطلاعات پروفایل
final profileInfoProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final shop = await ShopRepository().getCurrentShop();
  return {
    'name': shop?['name']?.toString() ?? 'فروشگاه من',
    'phone': shop?['phone']?.toString() ?? '---',
    'image': shop?['logo_path']?.toString() ?? '',
  };
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider).session;
    final isOwner = session.roleId == 'owner';

    // 2. گوش دادن به اطلاعات پروفایل
    final profileAsync = ref.watch(profileInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.settings,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // پاس دادن اطلاعات پروفایل به هدر
            _profileHeader(context, ref, profileAsync),
            const SizedBox(height: 16),

            /// ================= General =================
            _groupTitle(l10n.generalSetting),
            _card(
              children: [
                _languageTile(ref, locale, l10n.languag),
                _switchTile(
                  icon: Icons.notifications,
                  iconBg: Colors.orange.shade50,
                  iconColor: Colors.orange,
                  title: l10n.notification,
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ================= Shop & Team =================
            if (isOwner) ...[
              _groupTitle('فروشگاه و کارمندان'),
              _card(
                children: [
                  _navigationTile(
                    icon: Icons.store,
                    iconBg: Colors.blue.shade50,
                    iconColor: Colors.blue,
                    title: 'پروفایل فروشگاه',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopProfileScreen()));
                    },
                  ),
                  _navigationTile(
                    icon: Icons.group,
                    iconBg: Colors.teal.shade50,
                    iconColor: Colors.teal,
                    title: 'کارمندان',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeesScreen()));
                    },
                  ),
                  _navigationTile(
                    icon: Icons.security,
                    iconBg: Colors.orange.shade50,
                    iconColor: Colors.orange,
                    title: 'نقش‌ها و دسترسی‌ها',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RolesScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            /// ================= Set Unit =================
            _groupTitle(l10n.setUnitPrice),
            _card(
              children: [
                _navigationTile(
                  icon: Icons.pin,
                  iconBg: Colors.green.shade50,
                  iconColor: Colors.green,
                  title: l10n.setUnit,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ================= Inventory & Suppliers =================
            _groupTitle('موجودی و تامین‌کنندگان'),
            _card(
              children: [
                _navigationTile(
                  icon: Icons.inventory,
                  iconBg: Colors.green.shade50,
                  iconColor: Colors.green,
                  title: 'کارت‌های کاغذی',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PaperCardInventoryScreen()));
                  },
                ),
                _navigationTile(
                  icon: Icons.local_shipping,
                  iconBg: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  title: 'تامین‌کنندگان',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SuppliersScreen()));
                  },
                ),
                _navigationTile(
                  icon: Icons.inventory_2,
                  iconBg: Colors.teal.shade50,
                  iconColor: Colors.teal,
                  title: 'دارایی‌ها',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetsScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ================= Salaries & Sync =================
            _groupTitle('حقوق و همگام‌سازی'),
            _card(
              children: [
                _navigationTile(
                  icon: Icons.payments,
                  iconBg: Colors.indigo.shade50,
                  iconColor: Colors.indigo,
                  title: 'حقوق',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SalariesScreen()));
                  },
                ),
                _navigationTile(
                  icon: Icons.sync,
                  iconBg: Colors.blueGrey.shade50,
                  iconColor: Colors.blueGrey,
                  title: 'وضعیت همگام‌سازی',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncStatusScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ================= Support =================
            _groupTitle('پشتیبانی'),
            _card(
              children: [
                _navigationTile(
                  icon: Icons.headset_mic,
                  iconBg: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  title: l10n.callWithSupport,
                  trailingIcon: Icons.call,
                  onTap: () {},
                ),
                _navigationTile(
                  icon: Icons.description,
                  iconBg: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  title: 'شرایط و مقررات',
                  onTap: () {},
                ),
                _navigationTile(
                  icon: Icons.info,
                  iconBg: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  title: l10n.aboutUs,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// ================= Logout =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.logout,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.logout),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('نسخه ۱.۰.۰', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ================= Widgets =================

  // 3. اصلاح ویجت هدر پروفایل برای نمایش اطلاعات واقعی
  Widget _profileHeader(BuildContext context, WidgetRef ref, AsyncValue<Map<String, String>> profileAsync) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Stack(
              children: [
                // نمایش عکس پروفایل
                profileAsync.when(
                  data: (data) {
                    final imagePath = data['image'];
                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (imagePath != null && imagePath.isNotEmpty)
                          ? FileImage(File(imagePath)) as ImageProvider
                          : null, // اگر عکس نبود نال برمی‌گرداند
                      child: (imagePath == null || imagePath.isEmpty)
                          ? const Icon(Icons.store, size: 40, color: Colors.grey)
                          : null,
                    );
                  },
                  loading: () => const CircleAvatar(radius: 40, child: CircularProgressIndicator()),
                  error: (_, __) => const CircleAvatar(radius: 40, child: Icon(Icons.error)),
                ),

                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFEA2A33),
                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // نمایش نام فروشگاه
                  profileAsync.when(
                    data: (data) => Text(
                      data['name']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Container(width: 100, height: 20, color: Colors.grey.shade200),
                    error: (_, __) => const Text('خطا'),
                  ),

                  const SizedBox(height: 4),

                  // نمایش شماره تماس
                  profileAsync.when(
                    data: (data) => Text(
                      data['phone']!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    loading: () => Container(width: 80, height: 15, color: Colors.grey.shade200),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () async {
                      // 4. رفتن به صفحه ویرایش و رفرش کردن اطلاعات هنگام بازگشت
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfilePage()),
                      );
                      // این خط باعث می‌شود وقتی کاربر برگشت، اطلاعات دوباره خوانده شود
                      ref.refresh(profileInfoProvider);
                    },
                    child: const Text(
                      'ویرایش پروفایل',
                      style: TextStyle(color: Color(0xFFEA2A33), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageTile(WidgetRef ref, Locale locale, String title) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: const Icon(Icons.language, color: Colors.blue),
      ),
      title: Text(title),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.languageCode,
          items: const [
            DropdownMenuItem(value: 'fa', child: Text('دری')),
            DropdownMenuItem(value: 'ps', child: Text('پشتو')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(localeProvider.notifier).changeLanguage(value);
            }
          },
        ),
      ),
    );
  }

  Widget _groupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      ),
    );
  }

  Widget _navigationTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    IconData? trailingIcon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: iconBg, child: Icon(icon, color: iconColor)),
      title: Text(title),
      trailing: Icon(trailingIcon ?? Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: CircleAvatar(backgroundColor: iconBg, child: Icon(icon, color: iconColor)),
      title: Text(title),
      activeColor: const Color(0xFFEA2A33),
    );
  }
}
