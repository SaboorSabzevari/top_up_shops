import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const Color primaryColor = Color(0xFFEA2A33);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'درباره ما',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// LOGO + VERSION
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'نسخه ۱.۰.۲',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// TITLE
                    const Text(
                      'سیستم مدیریت\nفروشگاه شارژ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'فروشگاه شارژ',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// DESCRIPTION
                    const Text(
                      'ما متعهد هستیم تا بهترین راهکارها را برای مدیریت فروشگاه‌های شارژ موبایل در افغانستان ارائه دهیم. هدف ما تسهیل فرآیند خرید و فروش شارژ، مدیریت دقیق حساب‌ها و کمک به رشد کسب‌وکارهای کوچک است. با ما، مدیریت فروشگاه شما ساده‌تر، سریع‌تر و هوشمندتر خواهد بود.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.8,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// LINKS
                    _LinkTile(
                      icon: Icons.language,
                      iconColor: Colors.blue,
                      title: 'وب‌سایت ما',
                      onTap: () {},
                    ),
                    _LinkTile(
                      icon: Icons.public,
                      iconColor: Colors.indigo,
                      title: 'فیسبوک',
                      onTap: () {},
                    ),
                    _LinkTile(
                      icon: Icons.send,
                      iconColor: Colors.lightBlue,
                      title: 'تلگرام',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            /// FOOTER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    '© ۲۰۲۴ تمامی حقوق محفوظ است',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'طراحی شده با ❤️ برای افغانستان',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- COMPONENT ----------------

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
