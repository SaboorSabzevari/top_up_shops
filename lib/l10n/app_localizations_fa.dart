// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'فروشگاه‌های تاپ‌آپ';

  @override
  String get login => 'ورود';

  @override
  String get dashboard => 'داشبورد';

  @override
  String get customers => 'مشتریان';

  @override
  String get transactions => 'تراکنش‌ها';

  @override
  String get reports => 'گزارش‌ها';

  @override
  String get settings => 'تنظیمات';

  @override
  String get newSale => 'فروش جدید';

  @override
  String get payment => 'پرداخت';

  @override
  String get purchase => 'خرید';

  @override
  String get employee => 'کارمند';

  @override
  String get language => 'زبان';

  @override
  String get syncStatus => 'وضعیت همگام‌سازی';

  @override
  String get allSynced => 'همه هماهنگ است';

  @override
  String pendingSync(Object count) {
    return '$count تغییری همگام‌نشده';
  }

  @override
  String get todaySales => 'فروش امروز';

  @override
  String get outstanding => 'باقی‌مانده';

  @override
  String get margin => 'حاشیه سود';

  @override
  String get save => 'ذخیره';

  @override
  String get cancel => 'لغو';

  @override
  // TODO: implement email
  String get email =>" ایمیل";

  @override
  // TODO: implement password
  String get password => "گذرواژه";

  @override
  // TODO: implement appSubTitle
  String get appSubTitle => "برای مدیریت فروشگاه خود وارد شوید";
  String get memorizeMe=> "مرا به خاطر بسپار";

  @override
  // TODO: implement forgotPassword
  String get forgotPassword => "رمز عبور خود را فراموش کرده اید؟";

  @override
  // TODO: implement noAccount
  String get noAccount => "حساب کاربری ندارید؟";

  @override
  // TODO: implement callWithSupport
  String get callWithSupport => "تماس با پشتیبانی";
}
