import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'شرایط و مقررات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFEA2A33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text(
              'قبول شرایط و ادامه',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              // TODO: handle accept
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                      const Color(0xFFEA2A33).withOpacity(0.1),
                      child: const Icon(
                        Icons.gavel,
                        color: Color(0xFFEA2A33),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'قوانین استفاده',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'آخرین بروزرسانی: ۱۴۰۳/۰۸/۱۵',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 24),

                /// CONTENT
                const _Section(
                  number: '۱',
                  title: 'مقدمه',
                  text:
                  'به سیستم مدیریت فروشگاه شارژ خوش آمدید. با استفاده از این برنامه، شما موافقت می‌کنید که به تمام قوانین و مقررات زیر پایبند باشید. این شرایط برای اطمینان از امنیت و کیفیت خدمات برای همه کاربران وضع شده است. لطفاً پیش از ادامه استفاده، این متن را به دقت مطالعه کنید.',
                ),
                const _Section(
                  number: '۲',
                  title: 'حساب کاربری و امنیت',
                  text:
                  'کاربران مسئول حفظ محرمانگی اطلاعات حساب کاربری و رمز عبور خود هستند. هرگونه فعالیت انجام شده تحت حساب کاربری شما، مسئولیتش با شماست. در صورت مشاهده هرگونه دسترسی غیرمجاز، فوراً به پشتیبانی اطلاع دهید. توصیه می‌شود از رمزهای عبور قوی استفاده کنید.',
                ),
                const _Section(
                  number: '۳',
                  title: 'تراکنش‌های مالی و شارژ',
                  text:
                  'تمامی تراکنش‌های خرید و فروش شارژ در سیستم ثبت می‌شود. مسئولیت دقت در وارد کردن شماره تلفن و مبلغ شارژ بر عهده کاربر است. در صورت بروز خطاهای خارج از کنترل سیستم، پشتیبانی پیگیری لازم را انجام خواهد داد.',
                ),
                const _Section(
                  number: '۴',
                  title: 'حریم خصوصی',
                  text:
                  'ما متعهد به حفظ حریم خصوصی کاربران هستیم. اطلاعات شخصی تنها برای ارائه خدمات بهتر استفاده می‌شود و بدون اجازه شما در اختیار اشخاص ثالث قرار نمی‌گیرد.',
                ),
                const _Section(
                  number: '۵',
                  title: 'تغییرات در قوانین',
                  text:
                  'مدیریت سیستم حق دارد در هر زمان قوانین را تغییر دهد. ادامه استفاده از برنامه به منزله پذیرش شرایط جدید خواهد بود.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- COMPONENT ----------------

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _Section({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.withOpacity(0.15),
                child: Text(
                  number,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: TextStyle(
              height: 1.7,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
