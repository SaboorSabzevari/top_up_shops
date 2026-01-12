
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_up_shops/src/presentation/screens/setting/unit_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/local_provider.dart';
import '../../theme/colors.dart';
import '../auth/login_screen.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
        elevation: 0,
        centerTitle: true,
        title:  Text(
          l10n.settings,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            _profileHeader(),
            const SizedBox(height: 16),

            /// ================= General =================
            _groupTitle(l10n.generalSetting),
            _card(
              children: [
                _languageTile(ref, locale,l10n.languag),
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

            /// ================= Security =================
            _groupTitle(l10n.setUnitPrice),
            _card(
              children: [
                // _switchTile(
                //   icon: Icons.lock,
                //   iconBg: Colors.green.shade50,
                //   iconColor: Colors.green,
                //   title: '',
                //   value: false,
                //   onChanged: (_) {},
                // ),
                _navigationTile(
                  icon: Icons.pin,
                  iconBg: Colors.green.shade50,
                  iconColor: Colors.green,
                  title: l10n.setUnit,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>UnitScreen()));
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
                ), _navigationTile(
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

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                    );
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
                    children:  [
                      Text(
                       l10n.logout,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.logout),
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

  Widget _languageTile(WidgetRef ref, Locale locale,String title) {
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

  Widget _profileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(radius: 40, backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
                Positioned(
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('فروشگاه کابل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('۰۷۹۹۰۰۰۰۰۰', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('ویرایش پروفایل', style: TextStyle(color: Color(0xFFEA2A33), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
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
