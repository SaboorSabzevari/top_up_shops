import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entity/customer.dart';
import '../../domain/entity/providers.dart';
import '../../domain/entity/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('topup_system.db');
    return _database!;
  }
  // محاسبه مجموع باقیات یک مشتری خاص
  Future<double> getCustomerTotalBalance(int customerId) async {
    final db = await instance.database;
    // جمع تمام ستون‌های باقی‌مانده (remaining_amount) برای این مشتری
    var result = await db.rawQuery(
        'SELECT SUM(remaining_amount) as total FROM transactions WHERE customer_id = ?',
        [customerId]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // متد پیشرفته ثبت تراکنش با محاسبه آنی
  Future<int> insertFullTransaction(TransactionEntity txn) async {
    final db = await instance.database;
    return await db.insert('transactions', txn.toMap());
  }
  // پیشنهادی برای اضافه کردن به app_database.dart
  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query('transactions', where: 'transaction_date = ?', whereArgs: [date]);
  }
// متد جستجوی سریع (AJAX) بر اساس نام یا کد مشتری
  Future<List<Map<String, dynamic>>> ajaxSearch(String query) async {
    final db = await instance.database;

    // جستجو در جدول مشتریان برای پیدا کردن نام یا کد مشابه
    return await db.query(
      'customers',
      where: 'name LIKE ? OR customer_code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 10, // محدود کردن تعداد نتایج برای سرعت بیشتر در AJAX
    );
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, filePath), version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // جدول مشتری
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, customer_code TEXT, type TEXT, profile_image TEXT, address TEXT, tazkira_image TEXT)');
    // جدول شماره تماس‌ها (عادی)
    await db.execute('CREATE TABLE customer_phones (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, phone_number TEXT)');
    // جدول کدهای شرکت (عمده)
    await db.execute('CREATE TABLE customer_wholesale_codes (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, company_name TEXT, company_code TEXT)');
    await db.execute('''
  CREATE TABLE units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    buy_price REAL NOT NULL,
    sell_price REAL NOT NULL,
    name TEXT
  )
''');
    // جدول شرکت‌های تامین کننده
    await db.execute('CREATE TABLE providers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, ordinary_code TEXT, wholesale_code TEXT)'); // جدول تراکنش‌ها
    await db.execute('''CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT, 
  customer_id INTEGER, 
  customer_name TEXT, 
  customer_type TEXT,
  operator_name TEXT, 
  phone_number TEXT, 
  company_code TEXT,
  sent_amount REAL, 
  received_amount REAL, 
  cost_price REAL, 
  profit REAL, 
  ussd_command TEXT, 
  created_at TEXT)''');
    await _seedProviders(db);
  }
  Future<void> _seedProviders(Database db) async {
    final List<Map<String, dynamic>> initialProviders = [
      {
        'name': 'ستارگان متحد',
        'type': 'ستارگان متحد',
        'ordinary_code': '543*2', // کدی که خودت تعیین می‌کنی
        'wholesale_code': '543*6'
      },
      {
        'name': 'اکتیو سرویس',
        'type': 'اکتیو سرویس',
        'ordinary_code': '683',
        'wholesale_code': '683*2'
      },
      {
        'name': 'افغان پی',
        'type': 'افغان پی',
        'ordinary_code': '511',
        'wholesale_code': '511*5'
      },
      {
        'name': 'شاهی ایزیلود',
        'type': 'شاهی ایزیلود',
        'ordinary_code': '545',
        'wholesale_code': '511*5'
      },
      {
        'name': 'سلام (Salaam)',
        'type': 'Salaam',
        'ordinary_code': 'SA-ORD-400',
        'wholesale_code': 'SA-WHL-800'
      },
    ];

    for (var provider in initialProviders) {
      await db.insert('providers', provider);
    }
  }

  // --- CRUD CUSTOMERS ---
  Future<int> addCustomer(Customer c, List<String>? phones, List<Map<String, String>>? wholesaleCodes) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // ۱. درج مشتری
      final id = await txn.insert('customers', c.toMap());

      // ۲. درج شماره‌ها (حذف شرط نوع مشتری برای ذخیره شماره دکان‌دار)
      if (phones != null && phones.isNotEmpty) {
        for (var p in phones) {
          await txn.insert('customer_phones', {
            'customer_id': id,
            'phone_number': p,
          });
        }
      }

      // ۳. درج کدهای دیلری (اصلاح نام ستون به company_code)
      if (wholesaleCodes != null && wholesaleCodes.isNotEmpty) {
        for (var item in wholesaleCodes) {
          await txn.insert('customer_wholesale_codes', {
            'customer_id': id,
            'company_name': item['company'],
            'company_code': item['code'],
          });
        }
      }
      return id;
    });
  }

  Future<void> updateCustomer(int id, Customer customer, List<String>? phones, List<Map<String, String>>? wholesaleCodes) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // ۱. آپدیت اطلاعات پایه (دقت کنید که در toMap نباید ID فرستاده شود)
      await txn.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      // ۲. مدیریت شماره تماس‌ها (حذف قدیمی و درج جدید)
      await txn.delete('customer_phones', where: 'customer_id = ?', whereArgs: [id]);
      if (phones != null && phones.isNotEmpty) {
        for (var phone in phones) {
          await txn.insert('customer_phones', {
            'customer_id': id,
            'phone_number': phone,
          });
        }
      }

      // ۳. مدیریت کدهای دیلری (حذف قدیمی و درج جدید با نام ستون صحیح)
      await txn.delete('customer_wholesale_codes', where: 'customer_id = ?', whereArgs: [id]);
      if (wholesaleCodes != null && wholesaleCodes.isNotEmpty) {
        for (var item in wholesaleCodes) {
          await txn.insert('customer_wholesale_codes', {
            'customer_id': id,
            'company_name': item['company'],
            'company_code': item['code'],
          });
        }
      }
    });
  }
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await instance.database;
    return await db.query('customers', where: 'name LIKE ? OR customer_code LIKE ?', whereArgs: ['%$query%', '%$query%']);
  }

  Future<Map<String, dynamic>> getCustomerFullDetails(int id) async {
    final db = await instance.database;
    final customer = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    final result = Map<String, dynamic>.from(customer.first);
    result['phones'] = await db.query('customer_phones', where: 'customer_id = ?', whereArgs: [id]);
    result['wholesale_codes'] = await db.query('customer_wholesale_codes', where: 'customer_id = ?', whereArgs: [id]);
    return result;
  }

  // --- CRUD PROVIDERS ---
  Future<int> addProvider(ProviderCompany p) async {
    final db = await instance.database;
    return await db.insert('providers', p.toMap());
  }

  Future<List<ProviderCompany>> getAllProviders() async {
    final db = await instance.database;
    final res = await db.query('providers');
    return res.map((e) => ProviderCompany(id: e['id'] as int, name: e['name'] as String, type: e['type'] as String, ordinaryCode: e['ordinary_code'] as String, wholesaleCode: e['wholesale_code'] as String)).toList();
  }

  // --- TRANSACTIONS ---
  Future<int> addTransaction(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('transactions', data);
  }


  Future<Map<String, dynamic>> getSingleUnit() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('units', where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      // ایجاد ردیف پیش‌فرض در صورت عدم وجود
      await db.insert('units', {
        'id': 1,
        'buy_price': 0.95,
        'sell_price': 0.96,
        'name': 'واحد اصلی سیستم'
      });
      return {'id': 1, 'buy_price': 0.95, 'sell_price': 0.96, 'name': 'واحد اصلی سیستم'};
    }
  }

  // بروزرسانی تنظیمات واحد واحد
  Future<int> updateSingleUnit(double buy, double sell) async {
    final db = await instance.database;
    return await db.update(
      'units',
      {
        'buy_price': buy,
        'sell_price': sell,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

// ۲. افزودن واحد جدید
  Future<int> addUnit(double buy, double sell) async {
    final db = await instance.database;
    return await db.insert('units', {
      'buy_price': buy,
      'sell_price': sell,
      'name': 'واحد جدید'
    });
  }

// ۳. بروزرسانی واحد
  Future<int> updateUnit(int id, double buy, double sell) async {
    final db = await instance.database;
    return await db.update(
      'units',
      {'buy_price': buy, 'sell_price': sell},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// ۴. حذف واحد
  Future<int> deleteUnit(int id) async {
    final db = await instance.database;
    return await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }
// در بخش متدهای DatabaseHelper اضافه کنید
// این متد را به انتهای کلاس DatabaseHelper اضافه کنید
// متد ذخیره تراکنش با تمام جزئیات مالی
  Future<int> saveDetailedTransaction(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('transactions', {
      'customer_id': data['customer_id'],
      'customer_name': data['customer_name'],
      'customer_type': data['customer_type'],
      'operator_name': data['operator_name'],
      'phone_number': data['phone_number'],
      'company_code': data['company_code'],
      'sent_amount': data['sent_amount'],
      'received_amount': data['received_amount'],
      'cost_price': data['cost_price'],
      'profit': data['profit'],
      'ussd_command': data['ussd_command'],
      'created_at': DateTime.now().toIso8601String(),
    });
  }}

// Future<int> saveDetailedTransaction(Map<String, dynamic> data) async {
//   final db = await instance.database;
//   return await db.insert('transactions', {
//     'customer_id': data['customer_id'],
//     'customer_name': data['customer_name'],
//     'customer_type': data['customer_type'],
//     'provider_name': data['operator_name'], // اصلاح شد
//     'target_destination': data['phone_number'], // اصلاح شد
//     'provider_used_code': data['company_code'], // اصلاح شد
//     'credit_amount': data['sent_amount'], // اصلاح شد
//     'total_amount': data['received_amount'], // اصلاح شد
//     'transaction_date': DateTime.now().toIso8601String(), // اصلاح شد
//     // نکته: ستون‌های profit و cost_price در تعریف جدول شما وجود ندارند
//     // اگر به آن‌ها نیاز دارید، راه حل دوم را انجام دهید.
//   });
// }