import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entity/customer.dart';
import '../../domain/entity/providers.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('topup_system.db');
    return _database!;
  }
  // Future<double> getCustomerTotalBalance(int customerId) async {
  //   final db = await instance.database;
  //   var result = await db.rawQuery(
  //       'SELECT SUM(remaining_amount) as total FROM transactions WHERE customer_id = ?',
  //       [customerId]
  //   );
  //   return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  // }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query('transactions', where: 'transaction_date = ?', whereArgs: [date]);
  }
  Future<List<Map<String, dynamic>>> ajaxSearch(String query) async {
    final db = await instance.database;

    return await db.query(
      'customers',
      where: 'name LIKE ? OR customer_code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 10,
    );
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, filePath), version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, customer_code TEXT, type TEXT, profile_image TEXT, address TEXT, tazkira_image TEXT)');
    await db.execute('CREATE TABLE customer_phones (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, phone_number TEXT)');
    await db.execute('CREATE TABLE customer_wholesale_codes (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, company_name TEXT, company_code TEXT)');
    await db.execute('''
  CREATE TABLE units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    buy_price REAL NOT NULL,
    sell_price REAL NOT NULL,
    name TEXT
  )
''');
     await db.execute('CREATE TABLE providers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, ordinary_code TEXT, wholesale_code TEXT)'); // جدول تراکنش‌ها
    await db.execute('''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- مشخصات مشتری
    customer_id INTEGER,                 -- اگر مشتری ناشناس باشد، این مقدار NULL است
    customer_name TEXT,                  -- نام مشتری یا "مشتری رهگذر"
    customer_type TEXT,                  -- 'REGISTERED' (ثبت شده) یا 'WALK_IN' (رهگذر)
    
    -- مشخصات نوع سرویس
    transaction_type TEXT DEFAULT 'DIGITAL', -- مقادیر: 'DIGITAL' (شارژ) یا 'PAPER' (کارت فیزیکی)
    operator_name TEXT,                  -- مثال: AWCC, ROSHAN
    phone_number TEXT,                   -- برای کارت کاغذی می‌تواند NULL باشد
    company_code TEXT,                   -- کد شرکت (برای مشتریان عمده)
    
    -- مقادیر کمی
    sent_amount REAL,                    -- ارزش اسمی (مثلاً کارت ۵۰ افغانی)
    quantity INTEGER DEFAULT 1,          -- تعداد (برای کارت کاغذی مثلا ۱۰ عدد، برای شارژ ۱)
    
    -- محاسبات مالی فروش
    total_price REAL,                    -- مبلغ کل فاکتور (قیمت فی × تعداد - تخفیف)
    discount REAL DEFAULT 0,             -- تخفیف داده شده
    paid_amount REAL DEFAULT 0,          -- مبلغی که مشتری نقد پرداخت کرده
    remaining_amount REAL DEFAULT 0,     -- مبلغ باقی‌مانده (بدهی)
    
    -- محاسبات سود و زیان (سمت فروشنده)
    cost_price REAL,                     -- قیمت خرید تمام شده برای شما
    profit REAL,                         -- سود خالص (فروش - خرید)
    
    -- اطلاعات سیستمی
    received_amount REAL,                -- (جهت سازگاری با کدهای قبلی آمار) معمولا برابر paid_amount
    ussd_command TEXT,                   -- کد دستوری اجرا شده (اختیاری برای کارت کاغذی)
    created_at TEXT                      -- تاریخ و زمان دقیق تراکنش
  )
''');

    // در متد _createDB در app_database.dart، جدول purchases را به این شکل تغییر دهید:
    await db.execute('''
  CREATE TABLE purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,                -- 'PAPER' یا 'DIGITAL'
    provider_name TEXT,       -- نام شرکت تأمین‌کننده
    operator_name TEXT,       -- برای کاغذی (AWCC, Roshan...)
    face_value INTEGER,       -- مقدار کارت (50, 100...)
    quantity INTEGER,         -- تعداد برای کاغذی
    
    -- مقادیر اسمی
    total_credit REAL,        -- مجموع مبلغ کریدیت (برای ارسالی)
    nominal_price REAL,       -- مبلغ اسمی (قبل از تخفیف)
    
    -- مقادیر واقعی پرداختی
    actual_paid REAL,         -- مبلغ واقعی که پرداخت کردید ✓
    discount_amount REAL,     -- مقدار تخفیف
    cost_per_unit REAL,       -- قیمت خرید فی واحد
    
    -- وضعیت پرداخت
    payment_status TEXT,      -- 'FULL', 'PARTIAL', 'PENDING'
    payment_date TEXT,        -- تاریخ پرداخت
    
    -- سیستمی
    created_at TEXT
  )
''');
    // داخل متد _createDB در DatabaseHelper
    await db.execute('''
  CREATE TABLE paper_stocks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operator_name TEXT,  -- مثال: roshan
    face_value INTEGER,  -- مثال: 100
    quantity INTEGER DEFAULT 0, -- موجودی فعلی
    UNIQUE(operator_name, face_value) -- جلوگیری از تکرار
  )
''');

    await db.execute('''
  CREATE TABLE provider_balances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_name TEXT UNIQUE, -- مثال: افغان پی
    current_balance REAL DEFAULT 0 -- موجودی کریدیت
  )
''');
    // در فایل app_database.dart
    await _seedProviders(db);
  }
  // --- مدیریت موجودی کارت کاغذی ---

  // افزایش موجودی (هنگام خرید)
  Future<void> increasePaperStock(String operator, int faceValue, int qty) async {
    final db = await instance.database;
    // چک میکنیم اگر رکورد هست آپدیت بشه، اگر نیست ساخته بشه
    await db.rawInsert('''
      INSERT INTO paper_stocks (operator_name, face_value, quantity)
      VALUES (?, ?, ?)
      ON CONFLICT(operator_name, face_value)
      DO UPDATE SET quantity = quantity + ?
    ''', [operator, faceValue, qty, qty]);
  }

  // کاهش موجودی (هنگام فروش)
  Future<void> decreasePaperStock(String operator, int faceValue, int qty) async {
    final db = await instance.database;
    await db.rawUpdate('''
      UPDATE paper_stocks 
      SET quantity = quantity - ? 
      WHERE operator_name = ? AND face_value = ?
    ''', [qty, operator, faceValue]);
  }

  // دریافت موجودی یک کارت خاص (برای چک کردن قبل از فروش)
  // در فایل app_database.dart متد زیر را پیدا و اصلاح کنید
  Future<int> getPaperStockCount(String operator, int faceValue) async {
    final db = await instance.database;

    // استفاده از LOWER برای از بین بردن حساسیت به حروف بزرگ و کوچک
    final res = await db.query(
      'paper_stocks',
      columns: ['quantity'],
      where: 'LOWER(operator_name) = LOWER(?) AND face_value = ?',
      whereArgs: [operator, faceValue],
    );

    if (res.isNotEmpty) {
      return (res.first['quantity'] as num).toInt();
    }
    return 0;
  }
  // دریافت کل لیست موجودی کارت‌ها (برای نمایش در صفحه مدیریت)
  Future<List<Map<String, dynamic>>> getAllPaperStocks() async {
    final db = await instance.database;
    return await db.query('paper_stocks', orderBy: 'operator_name, face_value');
  }

  // --- مدیریت موجودی کریدیت دیجیتال ---

  // افزایش موجودی شرکت (هنگام خرید)
  Future<void> increaseProviderBalance(String providerName, double amount) async {
    final db = await instance.database;
    await db.rawInsert('''
      INSERT INTO provider_balances (provider_name, current_balance)
      VALUES (?, ?)
      ON CONFLICT(provider_name)
      DO UPDATE SET current_balance = current_balance + ?
    ''', [providerName, amount, amount]);
  }

  // کاهش موجودی شرکت (هنگام فروش به مشتری)
  Future<void> decreaseProviderBalance(String providerName, double amount) async {
    final db = await instance.database;
    await db.rawUpdate('''
      UPDATE provider_balances 
      SET current_balance = current_balance - ? 
      WHERE provider_name = ?
    ''', [amount, providerName]);
  }

  // دریافت موجودی یک شرکت
  Future<double> getProviderBalance(String providerName) async {
    final db = await instance.database;
    final res = await db.query(
      'provider_balances',
      columns: ['current_balance'],
      where: 'provider_name = ?',
      whereArgs: [providerName],
    );
    if (res.isNotEmpty) {
      return (res.first['current_balance'] as num).toDouble();
    }
    return 0.0;
  }

  // دریافت لیست همه شرکت‌ها و موجودی‌شان
  Future<List<Map<String, dynamic>>> getAllProviderBalances() async {
    final db = await instance.database;
    return await db.query('provider_balances');
  }
  // برای سازگاری با سیستم قدیمی، این متد را به‌روزرسانی کنید:
  Future<int> insertPurchase(Map<String, dynamic> row) async {
    Database db = await instance.database;

    // تبدیل به فرمت جدول جدید
    Map<String, dynamic> data = {
      'type': row['type'],
      'provider_name': row['provider_name'],
      'operator_name': row['operator_name'],
      'face_value': row['face_value'],
      'quantity': row['quantity'],
      'total_credit': row['total_credit'] ?? 0,
      'cost_per_unit': row['cost_per_unit'] ?? 0,
      'nominal_price': row['nominal_price'] ?? 0,
      'actual_paid': row['actual_paid'] ?? row['nominal_price'] ?? 0,
      'discount_amount': row['discount_amount'] ?? 0,
      'payment_status': row['payment_status'] ?? 'FULL',
      'payment_date': row['payment_date'],
      'created_at': row['created_at'],
    };

    return await db.insert('purchases', data);
  }Future<List<Map<String, dynamic>>> getProviders() async {
    Database db = await instance.database;
    // نام جدول را جایگزین 'providers_table' کنید
    return await db.query('providers_table');
  } Future<void> _seedProviders(Database db) async {
    final List<Map<String, dynamic>> initialProviders = [
      {
        'name': 'ستارگان متحد',
        'type': 'ستارگان متحد',
        'ordinary_code': '543*2',
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
    ];

    for (var provider in initialProviders) {
      await db.insert('providers', provider);
    }
  }

  Future<int> addCustomer(Customer c, List<String>? phones, List<Map<String, String>>? wholesaleCodes) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('customers', c.toMap());

       if (phones != null && phones.isNotEmpty) {
        for (var p in phones) {
          await txn.insert('customer_phones', {
            'customer_id': id,
            'phone_number': p,
          });
        }
      }
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
       await txn.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.delete('customer_phones', where: 'customer_id = ?', whereArgs: [id]);
      if (phones != null && phones.isNotEmpty) {
        for (var phone in phones) {
          await txn.insert('customer_phones', {
            'customer_id': id,
            'phone_number': phone,
          });
        }
      }

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

  //CRUD for providers
  Future<int> addProvider(ProviderCompany p) async {
    final db = await instance.database;
    return await db.insert('providers', p.toMap());
  }

  Future<List<ProviderCompany>> getAllProviders() async {
    final db = await instance.database;
    final res = await db.query('providers');
    return res.map((e) => ProviderCompany(id: e['id'] as int, name: e['name'] as String, type: e['type'] as String, ordinaryCode: e['ordinary_code'] as String, wholesaleCode: e['wholesale_code'] as String)).toList();
  }
//CRUD for TRANSACTION
  Future<int> addTransaction(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('transactions', data);
  }

// CRUD FOR UNIT SECTION
  Future<Map<String, dynamic>> getSingleUnit() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('units', where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
       await db.insert('units', {
        'id': 1,
        'buy_price': 0.95,
        'sell_price': 0.96,
        'name': 'واحد اصلی سیستم'
      });
      return {'id': 1, 'buy_price': 0.95, 'sell_price': 0.96, 'name': 'واحد اصلی سیستم'};
    }
  }

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

  Future<int> addUnit(double buy, double sell) async {
    final db = await instance.database;
    return await db.insert('units', {
      'buy_price': buy,
      'sell_price': sell,
      'name': 'واحد جدید'
    });
  }

  Future<int> updateUnit(int id, double buy, double sell) async {
    final db = await instance.database;
    return await db.update(
      'units',
      {'buy_price': buy, 'sell_price': sell},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUnit(int id) async {
    final db = await instance.database;
    return await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }
// method for save transaction
  // در فایل app_database.dart، این متد را جایگزین قبلی کنید:
  // Future<int> saveDetailedTransaction(Map<String, dynamic> data) async {
  //   final db = await instance.database;
  //
  //   // اطمینان از اینکه مقادیر عددی هستند
  //   double total = (data['total_price'] ?? 0.0).toDouble();
  //   double paid = (data['paid_amount'] ?? 0.0).toDouble();
  //   double remaining = total - paid;
  //
  //   return await db.insert('transactions', {
  //     'customer_id': data['customer_id'],
  //     'customer_name': data['customer_name'],
  //     'customer_type': data['customer_type'],
  //     'operator_name': data['operator_name'],
  //     'phone_number': data['phone_number'],
  //     'company_code': data['company_code'],
  //     'sent_amount': data['sent_amount'],
  //     'remaining_amount': remaining, // حالا این ستون در جدول وجود دارد
  //
  //     'discount': data['discount'] ?? 0.0,
  //     'total_price': total,
  //     'paid_amount': paid,
  //
  //     'received_amount': data['received_amount'] ?? total,
  //     'cost_price': data['cost_price'],
  //     'profit': data['profit'],
  //     'ussd_command': data['ussd_command'],
  //     'created_at': DateTime.now().toIso8601String(),
  //   });
  // }
  Future<int> saveDetailedTransaction(Map<String, dynamic> data) async {
    final db = await instance.database;

    // اطمینان از فرمت صحیح اعداد
    double total = (data['total_price'] ?? 0.0).toDouble();
    double paid = (data['paid_amount'] ?? 0.0).toDouble();
    // محاسبه دقیق بدهی: اگر مشتری پول کمتر داد، مابقی بدهی می‌شود
    double remaining = total - paid;

    return await db.insert('transactions', {
      // بخش مشتری
      'customer_id': data['customer_id'], // برای مشتری ناشناس null می‌آید
      'customer_name': data['customer_name'] ?? 'مشتری رهگذر',
      'customer_type': data['customer_type'] ?? 'WALK_IN',

      // بخش نوع تراکنش (جدید)
      'transaction_type': data['transaction_type'] ?? 'DIGITAL', // پیش‌فرض دیجیتال است
      'operator_name': data['operator_name'],
      'phone_number': data['phone_number'],
      'company_code': data['company_code'],

      // بخش مقادیر (جدید)
      'sent_amount': data['sent_amount'], // ارزش کارت (مثلا ۵۰)
      'quantity': data['quantity'] ?? 1,  // تعداد کارت

      // بخش مالی
      'discount': data['discount'] ?? 0.0,
      'total_price': total,
      'paid_amount': paid,
      'remaining_amount': remaining,

      // بخش سود و آمار
      'received_amount': data['received_amount'] ?? paid, // برای سازگاری با آمار
      'cost_price': data['cost_price'],
      'profit': data['profit'],

      // سیستمی
      'ussd_command': data['ussd_command'],
      'created_at': DateTime.now().toIso8601String(),
    });
  }Future<double> getCustomerTotalBalance(int customerId) async {
    final db = await instance.database;
    var result = await db.rawQuery(
        'SELECT SUM(total_price) - SUM(paid_amount) as balance FROM transactions WHERE customer_id = ?',
        [customerId]
    );
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }
}
