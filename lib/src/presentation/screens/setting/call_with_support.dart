import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// در صورت وجود می‌توانید مستقیماً از فایل colors.dart استفاده کنید
// اما برای اطمینان، پالت رنگی مشابه داشبورد در اینجا تعریف می‌شود
class AppColors {
  static const primary = Color(0xFFEA2A33);
  static const dashboardBg = Color(0xFFF3F4F6);
  static const cardBg = Colors.white;
  static const textMain = Color(0xFF1E293B); // slate-800
  static const textMuted = Color(0xFF64748B); // slate-500
  static const borderLight = Color(0xFFE2E8F0); // slate-200
}

class AppStyles {
  static final List<BoxShadow> customShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static const TextStyle fontVazir = TextStyle(fontFamily: 'Vazirmatn');
}

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors();

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'پشتیبانی و راهنمایی',
          style: AppStyles.fontVazir.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: AppColors.textMain,
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(right: 8.w),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 20.w, color: AppColors.textMain),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppStyles.customShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 28.w,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ما اینجا هستیم تا کمک کنیم',
                                style: AppStyles.fontVazir.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: AppColors.textMain,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'تیم پشتیبانی ما ۲۴/۷ آماده پاسخگویی به سوالات شماست',
                                style: AppStyles.fontVazir.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // QUICK ACTIONS TITLE (مشابه عنوان‌های داشبورد)
                  Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'راه‌های ارتباط سریع',
                        style: AppStyles.fontVazir.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // QUICK ACTIONS GRID (با کارت‌های افقی شبیه به بخش دسترسی سریع داشبورد)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12.w,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 2.2, // متناسب با کارت افقی
                        children: [
                          _buildQuickActionCard(
                            icon: Icons.phone_in_talk_rounded,
                            title: 'تماس تلفنی',
                            subtitle: 'پاسخ فوری',
                            color: AppColors.primary,
                          ),
                          _buildQuickActionCard(
                            icon: Icons.chat_bubble_rounded,
                            title: 'واتس‌اپ',
                            subtitle: 'پشتیبانی آنلاین',
                            color: const Color(0xFF25D366), // واتساپ سبز
                          ),
                          _buildQuickActionCard(
                            icon: Icons.email_rounded,
                            title: 'ایمیل',
                            subtitle: 'پاسخ در ۲۴ ساعت',
                            color: AppColors.textMuted,
                          ),
                          _buildQuickActionCard(
                            icon: Icons.forum_rounded,
                            title: 'چت آنلاین',
                            subtitle: 'همین الان',
                            color: AppColors.primary,
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // SUPPORT HOURS (کارت سفید با سایه)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppStyles.customShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                            size: 24.w,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ساعات کاری پشتیبانی',
                                style: AppStyles.fontVazir.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: AppColors.textMain,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'همه‌روزه از ساعت 8 صبح تا 5 عصر',
                                style: AppStyles.fontVazir.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // CONTACT INFO (کارت سفید بدون گرادیان)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppStyles.customShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اطلاعات تماس',
                          style: AppStyles.fontVazir.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildContactInfoRow(
                          icon: Icons.phone_rounded,
                          title: 'شماره تماس',
                          value: '93-793-320-572+',
                        ),
                        SizedBox(height: 12.h),
                        _buildContactInfoRow(
                          icon: Icons.email_rounded,
                          title: 'آدرس ایمیل',
                          value: 'support@example.com',
                        ),
                        SizedBox(height: 12.h),
                        _buildContactInfoRow(
                          icon: Icons.location_on_rounded,
                          title: 'آدرس دفتر',
                          value: 'هرات, چوک سینما, ساختمان ویتامکس',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // کارت افقی مخصوص دسترسی سریع (مشابه کارت‌های داشبورد)
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppStyles.customShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // نوار رنگی سمت چپ (در RTL سمت راست)
                Container(
                  width: 4.w,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 12.w),
                // متن‌ها
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppStyles.fontVazir.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: AppStyles.fontVazir.copyWith(
                          fontSize: 9.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // آیکون در پس‌زمینه‌ی رنگی کمرنگ
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, size: 18.w, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ردیف اطلاعات تماس
  Widget _buildContactInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.fontVazir.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: AppStyles.fontVazir.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
