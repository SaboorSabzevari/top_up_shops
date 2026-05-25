// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Pushto Pashto (`ps`).
class AppLocalizationsPs extends AppLocalizations {
  AppLocalizationsPs([String locale = 'ps']) : super(locale);

  @override
  String get appTitle => 'ټاپ اپ هټۍ';

  @override
  String get login => 'ننوتل';

  @override
  String get dashboard => 'ډشبورډ';

  @override
  String get customers => 'پېرودونکي';

  @override
  String get transactions => 'راکړې ورکړې';

  @override
  String get reports => 'راپورونه';

  @override
  String get settings => 'تنظیمات';

  @override
  String get newSale => 'نوې پلور';

  @override
  String get payment => 'تادیه';

  @override
  String get purchase => 'پېرود';

  @override
  String get employee => 'کارکوونکی';

  @override
  String get language => 'ژبه';

  @override
  String get syncStatus => 'د همغږۍ حالت';

  @override
  String get allSynced => 'ټول همغږي شوي';

  @override
  String pendingSync(Object count) {
    return '$count نه همغږي بدلونونه';
  }

  @override
  String get todaySales => 'د نن ورځې پلور';

  @override
  String get outstanding => 'باقي';

  @override
  String get margin => 'ګټه';

  @override
  String get save => 'ثبت';

  @override
  String get cancel => 'رد';

  @override
  // TODO: implement email
  String get email => "ایمیل";

  @override
  // TODO: implement password
  String get password => "رمز";

  @override
  // TODO: implement appSubTitle
  String get appSubTitle => "د خپل دوکان د اداره کولو لپاره ننوتل";

  @override
  // TODO: implement memorizeMe
  String get memorizeMe =>  "ما په یاد ولره.";

  @override
  // TODO: implement forgotPassword
  String get forgotPassword => "پټنوم مو هېر شوی؟";

  @override
  // TODO: implement noAccount
  String get noAccount => "حساب نه لرې؟";

  @override
  // TODO: implement callWithSupport
  String get callWithSupport => "د ملاتړ سره اړیکه ونیسئ";

  @override
  // TODO: implement languag
  String get languag => "ژبه";

  @override
  // TODO: implement notification
  String get notification => "اعلانونه";
  @override
  // TODO: implement generalSetting
  String get generalSetting =>"عمومی تنظیمات";

  @override
  // TODO: implement logout
  String get logout => "له حساب څخه ننوتل";
  String get setUnitPrice => "د واحد بیه تنظیمول";
  String get setUnit => "واحد تنظیمول";
  String get aboutUs => "زموږ په اړه";

  /// TRANSACTION
  String get transactionHistory => "د معاملاتو تاریخچه";
  String get todayProfit => "د نن ورځې ګټه";
  String get todayTransactions => "د نن ورځې معاملې";
  String get searchHintText => "لټون وکړئ";

  /// CUSTOMERS
  String get customerList => "د پیرودونکو لست";
  String get newCustomer => "نوی پیرودونکی";
  String get customer => "پیرودونکی";

  /// addNewCustomer
  String get addNewCustomer => "نوی پیرودونکی زیاتول";
  String get normalCustomer => "عادي پیرودونکی";
  String get SalesCustomer => "د پلور پیرودونکی";
  String get uploadImage => "انځور پورته کول";
  String get fullName => "بشپړ نوم";
  String get fullnameHint => "بشپړ نوم ولیکئ";
  String get phoneNumbers => "د تماس شمېره";
  String get add => "زیاتول";
  String get uploadIDImage => "د پېژندپاڼې انځور پورته کول";
  String get address => "پته";
  String get addressHint => "پته ولیکئ";
  String get salesCodes => "د پلور کوډونه";
  String get saveBotton => "ثبت";

  /// SendCredit
  String get sellCredit => "کریډیټ پلورل";
  String get customerName => "د پیرودونکي نوم";
  String get customerType => "د پیرودونکي ډول";
  String get chooseCompany => "شرکت وټاکئ";
  String get customerNumber => "د پیرودونکي شمېره";
  String get creditAmount => "د کریډیټ اندازه";
  String get discount => "تخفیف";
  String get totalPayAble => "د ورکړې ټول مبلغ";
  String get paiedAmount => "ورکړل شوی مبلغ";
  String get communicationWay => "د اړیکې طریقه";
  String get verbal => "حضوري";
  String get call => "زنګ";
  String get whatsApp => "واټس‌اپ";
  String get telegram => "ټېلېګرام";
  String get transactionSaveAndSubmit => "معامله ثبت او لېږل";
  String get customerNotFound => "پیرودونکی ونه موندل شو";
  String get submitNewCustomer => "نوی پیرودونکی ثبتول";


}
