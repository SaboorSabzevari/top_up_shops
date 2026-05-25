import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// --- استایل‌های مشترک (برای هماهنگی با داشبورد) ---
class AppColors {
  static const primary = Color(0xFFEA2A33);
  static const dashboardBg = Color(0xFFF3F4F6);
  static const cardBg = Colors.white;
  static const textMain = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const borderLight = Color(0xFFE2E8F0);
}

class AppStyles {
  static final List<BoxShadow> customShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      offset: const Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -2,
    ),
  ];
  static const TextStyle fontVazir = TextStyle(fontFamily: 'Vazirmatn');
}

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      // 1. هدر اختصاصی داشبورد
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.h),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'شرایط و مقررات',
                    style: AppStyles.fontVazir.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 16.w, // دکمه بازگشت
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 2. بدنه صفحه (طومار قوانین)
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: AppStyles.customShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // هدر داخلی کارت (لوگو و تاریخ)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.gavel_rounded,
                            color: AppColors.primary,
                            size: 28.w,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'توافق‌نامه کاربری',
                              style: AppStyles.fontVazir.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 12.sp, color: AppColors.textMuted),
                                SizedBox(width: 4.w),
                                Text(
                                  'بروزرسانی: ۱۴۰۳/۰۸/۱۵',
                                  style: AppStyles.fontVazir.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Divider(color: AppColors.borderLight, thickness: 1),
                    ),

                    // محتوای متنی
                    const _Section(
                      number: '۱',
                      title: 'مقدمه',
                      text:
                      'به سیستم مدیریت فروشگاه شارژ خوش آمدید. با استفاده از این برنامه، شما موافقت می‌کنید که به تمام قوانین و مقررات زیر پایبند باشید. این شرایط برای اطمینان از امنیت و کیفیت خدمات برای همه کاربران وضع شده است.',
                    ),
                    const _Section(
                      number: '۲',
                      title: 'حساب کاربری و امنیت',
                      text:
                      'کاربران مسئول حفظ محرمانگی اطلاعات حساب کاربری و رمز عبور خود هستند. هرگونه فعالیت انجام شده تحت حساب کاربری شما، مسئولیتش با شماست. در صورت مشاهده هرگونه دسترسی غیرمجاز، فوراً به پشتیبانی اطلاع دهید.',
                    ),
                    const _Section(
                      number: '۳',
                      title: 'تراکنش‌های مالی',
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
                      title: 'تغییرات',
                      text:
                      'مدیریت سیستم حق دارد در هر زمان قوانین را تغییر دهد. ادامه استفاده از برنامه به منزله پذیرش شرایط جدید خواهد بود.',
                    ),

                    SizedBox(height: 20.h), // فضای خالی انتهای متن
                  ],
                ),
              ),
            ),
          ),

          // 3. دکمه ثابت پایین صفحه
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                onPressed: () {
                  // TODO: handle accept logic
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      'قبول شرایط و ادامه',
                      style: AppStyles.fontVazir.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ویجت کمکی برای بخش‌های متن ---
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
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: AppStyles.fontVazir.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: AppStyles.fontVazir.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(right: 34.w), // ایندنت متن نسبت به بولت
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: AppStyles.fontVazir.copyWith(
                height: 1.8, // ارتفاع خط برای خوانایی بهتر متن فارسی
                color: AppColors.textMuted,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}