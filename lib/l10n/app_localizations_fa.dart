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
  String get email => " ایمیل";

  @override
  // TODO: implement password
  String get password => "گذرواژه";

  @override
  // TODO: implement appSubTitle
  String get appSubTitle => "برای مدیریت فروشگاه خود وارد شوید";
  String get memorizeMe => "مرا به خاطر بسپار";

  @override
  // TODO: implement forgotPassword
  String get forgotPassword => "رمز عبور را فراموش کرده اید؟";

  @override
  // TODO: implement noAccount
  String get noAccount => "حساب کاربری ندارید؟";

  @override
  // TODO: implement callWithSupport
  String get callWithSupport => "تماس با پشتیبانی";

  @override
  // TODO: implement languag
  String get languag => "زبان";
  String get notification => "اعلانات";

  @override
  // TODO: implement generalSetting
  String get generalSetting => "تنظیمات عمومی";

  @override
  // TODO: implement logout
  String get logout => "خروج از حساب";
  String get setUnitPrice => "تنظیم قیمت واحد";
  String get setUnit => "تنظیم واحد";
  String get aboutUs => "درباره ما";

  /// TRANSACTION
  String get transactionHistory => "تاریخچه تراکنش‌ها";
  String get todayProfit => "سود امروز";
  String get todayTransactions => "تراکنش‌های امروز";
  String get searchHintText => "جستجو کنید";

  /// CUSTOMERS
  String get customerList => "لیست مشتریان";
  String get newCustomer => "مشتری جدید";
  String get customer => "مشتری";

  /// addNewCustomer
  String get addNewCustomer => "افزودن مشتری جدید";
  String get normalCustomer => "مشتری عادی";
  String get SalesCustomer => "مشتری فروش";
  String get uploadImage => "آپلود تصویر";
  String get fullName => "نام کامل";
  String get fullnameHint => "نام و نام خانوادگی را وارد کنید";
  String get phoneNumbers => "شماره تماس";
  String get add => "افزودن";
  String get uploadIDImage => "آپلود تصویر کارت شناسایی";
  String get address => "آدرس";
  String get addressHint => "آدرس را وارد کنید";
  String get salesCodes => "کدهای فروش";
  String get saveBotton => "ذخیره";

  /// SendCredit
  String get sellCredit => "فروش اعتبار";
  String get customerName => "نام مشتری";
  String get customerType => "نوع مشتری";
  String get chooseCompany => "انتخاب شرکت";
  String get customerNumber => "شماره مشتری";
  String get creditAmount => "مقدار اعتبار";
  String get discount => "تخفیف";
  String get totalPayAble => "مبلغ قابل پرداخت";
  String get paiedAmount => "مبلغ پرداخت‌شده";
  String get communicationWay => "روش ارتباط";
  String get verbal => "حضوری";
  String get call => "تماس";
  String get whatsApp => "واتساپ";
  String get telegram => "تلگرام";
  String get transactionSaveAndSubmit => "ذخیره و ثبت تراکنش";
  String get customerNotFound => "مشتری یافت نشد";
  String get submitNewCustomer => "ثبت مشتری جدید";
}
