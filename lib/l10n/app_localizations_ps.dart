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
  String get phoneNumber => 'د تلیفون شمیره';

  @override
  String get sendCode => 'کوډ واستوئ';

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
}
