import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/colors.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _CustomColors();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'پشتیبانی و راهنمایی',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(right: 8.w),
          child: IconButton(
            icon: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: colors.backgroundLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20.w,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER SECTION
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          colors.primary.withValues(alpha: 0.1),
                          colors.secondary.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: colors.primary,
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
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'تیم پشتیبانی ما ۲۴/۷ آماده پاسخگویی به سوالات شماست',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colors.textSecondary,
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

                  // QUICK ACTIONS TITLE
                  Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'راه‌های ارتباط سریع',
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // QUICK ACTIONS GRID
                  // برای صفحات کوچک 2 ستون، برای صفحات بزرگ 4 ستون
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16.w,
                        crossAxisSpacing: 16.w,
                        childAspectRatio: 1.1,
                        children: [
                          _QuickActionCard(
                            icon: Icons.phone_in_talk_rounded,
                            title: 'تماس تلفنی',
                            subtitle: 'پاسخ فوری',
                            color: colors.success,
                            iconBackground: colors.success.withValues(alpha:0.1),
                            onTap: () {},
                          ),
                          _QuickActionCard(
                            icon: Icons.chat_bubble_rounded,
                            title: 'واتس‌اپ',
                            subtitle: 'پشتیبانی آنلاین',
                            color: colors.whatsapp,
                            iconBackground: colors.whatsapp.withValues(alpha:0.1),
                            onTap: () {},
                          ),
                          _QuickActionCard(
                            icon: Icons.email_rounded,
                            title: 'ایمیل',
                            subtitle: 'پاسخ در ۲۴ ساعت',
                            color: colors.warning,
                            iconBackground: colors.warning.withValues(alpha:0.1),
                            onTap: () {},
                          ),
                          _QuickActionCard(
                            icon: Icons.forum_rounded,
                            title: 'چت آنلاین',
                            subtitle: 'همین الان',
                            color: colors.info,
                            iconBackground: colors.info.withValues(alpha:0.1),
                            onTap: () {},
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // SUPPORT HOURS
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: colors.backgroundLight,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: colors.border,
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: colors.primary,
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
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'همه‌روزه از ساعت ۸ صبح تا ۱۲ شب',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'پشتیبانی تلفنی: ۲۴/۷',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // CONTACT INFO
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withValues(alpha:0.05),
                          colors.secondary.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اطلاعات تماس',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _ContactInfoRow(
                          icon: Icons.phone_rounded,
                          title: 'شماره تماس',
                          value: '۰۲۱-۱۲۳۴۵۶۷۸',
                        ),
                        SizedBox(height: 12.h),
                        _ContactInfoRow(
                          icon: Icons.email_rounded,
                          title: 'آدرس ایمیل',
                          value: 'support@example.com',
                        ),
                        SizedBox(height: 12.h),
                        _ContactInfoRow(
                          icon: Icons.location_on_rounded,
                          title: 'آدرس دفتر مرکزی',
                          value: 'تهران، خیابان ولیعصر',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),

          // FLOATING ACTION BUTTON
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 20.w,
                  offset: Offset(0, -4.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Icons.add_rounded,
                      size: 24.w,
                    ),
                    label: Text(
                      'ارسال تیکت جدید',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: colors.backgroundLight,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chat_rounded,
                      color: colors.primary,
                      size: 24.w,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------- COMPONENTS --------------------

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconBackground;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10.w,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.w,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: _CustomColors().textSecondary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ContactInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _CustomColors();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colors.primary,
          size: 20.w,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// -------------------- CUSTOM COLORS --------------------

class _CustomColors {
  final Color primary = kPrimaryColor; // فرض می‌کنیم kPrimaryColor تعریف شده
  final Color secondary = const Color(0xFF3A0CA3);
  final Color success = const Color(0xFF4CC9F0);
  final Color warning = const Color(0xFFF72585);
  final Color info = const Color(0xFF7209B7);
  final Color whatsapp = const Color(0xFF25D366);
  final Color backgroundLight = const Color(0xFFF8F9FA);
  final Color textSecondary = const Color(0xFF6C757D);
  final Color border = const Color(0xFFE9ECEF);
}