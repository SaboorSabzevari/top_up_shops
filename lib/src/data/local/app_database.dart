import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entity/customer.dart';
import '../../domain/entity/providers.dart';
import '../../providers/session_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('topup_system.db');
    return _database!;
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query('transactions', where: 'transaction_date = ?', whereArgs: [date]);
  }
  Future<List<Map<String, dynamic>>> ajaxSearch(String query, String shopId) async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT id, name, customer_code, type 
    FROM customers 
    WHERE (name LIKE ? OR customer_code LIKE ?) AND shop_id = ?
    LIMIT 10
  ''', ['%$query%', '%$query%', shopId]);
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, filePath), version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    name TEXT, 
    customer_code TEXT, 
    type TEXT, 
    shop_id TEXT NOT NULL, 
    created_by TEXT,
    profile_image TEXT, 
    address TEXT, 
    tazkira_image TEXT
  )''');
    await db.execute('CREATE TABLE customer_phones (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, phone_number TEXT)');
    await db.execute('CREATE TABLE customer_wholesale_codes (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, company_name TEXT, company_code TEXT)');
    await db.execute('''CREATE TABLE units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    buy_price REAL NOT NULL,
    sell_price REAL NOT NULL,
    name TEXT,
    shop_id TEXT NOT NULL
  )''');
     await db.execute('CREATE TABLE providers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, ordinary_code TEXT, wholesale_code TEXT)'); // جدول تراکنش‌ها
    await db.execute('''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- مشخصات مشتری
    customer_id INTEGER,                 -- اگر مشتری ناشناس باشد، این مقدار NULL است
    customer_name TEXT,                  -- نام مشتری یا "مشتری رهگذر"
    customer_type TEXT,                  -- 'REGISTERED' (ثبت شده) یا 'WALK_IN' (رهگذر)
    shop_id TEXT NOT NULL,         -- اضافه شد
    created_by TEXT NOT NULL,      -- اضافه شد
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
    await db.execute('''CREATE TABLE purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    provider_name TEXT,
    operator_name TEXT,
    face_value INTEGER,
    quantity INTEGER,
    total_credit REAL,
    nominal_price REAL,
    actual_paid REAL,
    discount_amount REAL,
    cost_per_unit REAL,
    payment_status TEXT,
    payment_date TEXT,
    created_at TEXT,
    shop_id TEXT NOT NULL,
    created_by TEXT NOT NULL
  )''');
    await db.execute('''
  CREATE TABLE paper_stock (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operator TEXT,
    face_value INTEGER,
    quantity INTEGER DEFAULT 0,
    shop_id TEXT,
    UNIQUE(operator, face_value, shop_id) -- این خط حیاتی است
  )
''');
    await db.execute('''CREATE TABLE provider_balances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_name TEXT, 
    current_balance REAL DEFAULT 0,
    shop_id TEXT NOT NULL,
    UNIQUE(provider_name, shop_id) -- اضافه شدن shop_id برای جلوگیری از تداخل دکان‌ها
)''');
    // در متد _createDB در فایل app_database.dart این را اضافه کنید:

    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uid TEXT UNIQUE, -- آیدی فایربیس حتما اضافه شود
    name TEXT,
    email TEXT,
    role TEXT,
    shop_id TEXT
  )
''');

// به جدول transactions ستون زیر را اضافه کنید:
// 'created_by_id' INTEGER
    // در فایل app_database.dart
    await _seedProviders(db);
  }
  // --- مدیریت موجودی کارت کاغذی ---

  // افزایش موجودی (هنگام خرید)

  // کاهش موجودی (هنگام فروش)
// در DatabaseHelper
  Future<int> decreasePaperStock(String operator, int faceValue, int qty, String shopId) async {
    final db = await instance.database;

    // استفاده از نام جدول اصلاح شده
    final res = await db.query(
      'paper_stock',
      where: 'operator = ? AND face_value = ? AND shop_id = ?',
      whereArgs: [operator, faceValue, shopId],
    );

    if (res.isNotEmpty) {
      int currentQty = res.first['quantity'] as int;
      if (currentQty >= qty) {
        return await db.update(
          'paper_stock',
          {'quantity': currentQty - qty},
          where: 'id = ?',
          whereArgs: [res.first['id']],
        );
      } else {
        throw Exception("موجودی کافی نیست! موجودی فعلی: $currentQty");
      }
    }
    throw Exception("این کارت در انبار دکان شما تعریف نشده است.");
  } // افزایش موجودی (هنگام خرید) - مختص همان دکان
  Future<void> increasePaperStock(String operator, int faceValue, int qty, String shopId) async {
    final db = await instance.database;
    await db.rawInsert('''
    INSERT INTO paper_stock (operator, face_value, quantity, shop_id)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(operator, face_value, shop_id) 
    DO UPDATE SET quantity = quantity + EXCLUDED.quantity
  ''', [operator, faceValue, qty, shopId]); // دقت کنید پارامتر qty اضافه حذف شد چون از EXCLUDED استفاده کردیم
  } // دریافت تعداد موجودی یک کارت در دکان فعلی
  Future<int> getPaperStockCount(String operator, int faceValue, String shopId) async {
    final db = await instance.database;
    final res = await db.query(
      'paper_stock',
      columns: ['quantity'],
      where: 'LOWER(operator) = LOWER(?) AND face_value = ? AND shop_id = ?',
      whereArgs: [operator, faceValue, shopId],
    );
    return res.isNotEmpty ? (res.first['quantity'] as num).toInt() : 0;
  }
   Future<List<Map<String, dynamic>>> getAllPaperStocks() async {
    final db = await instance.database;
    return await db.query('paper_stock', orderBy: 'operator_name, face_value');
  }

  // ۱. افزایش موجودی شرکت (هنگام خرید کریدیت عمده)
  Future<void> increaseProviderBalance(String providerName, double amount, String shopId) async {
    final db = await instance.database;
    await db.rawInsert('''
    INSERT INTO provider_balances (provider_name, current_balance, shop_id)
    VALUES (?, ?, ?)
    ON CONFLICT(provider_name, shop_id) 
    DO UPDATE SET current_balance = current_balance + ?
  ''', [providerName, amount, shopId, amount]);
  }

// ۲. کاهش موجودی شرکت (هنگام فروش به مشتری)
  Future<void> decreaseProviderBalance(String providerName, double amount, String shopId) async {
    final db = await instance.database;
    await db.rawUpdate('''
    UPDATE provider_balances 
    SET current_balance = current_balance - ? 
    WHERE provider_name = ? AND shop_id = ?
  ''', [amount, providerName, shopId]);
  }

// ۳. دریافت موجودی فعلی یک شرکت خاص
  Future<double> getProviderBalance(String providerName, String shopId) async {
    final db = await instance.database;
    final res = await db.query(
      'provider_balances',
      columns: ['current_balance'],
      where: 'provider_name = ? AND shop_id = ?',
      whereArgs: [providerName, shopId],
    );
    if (res.isNotEmpty) {
      return (res.first['current_balance'] as num).toDouble();
    }
    return 0.0;
  }
  // کاهش موجودی شرکت (هنگام فروش به مشتری)

  Future<List<Map<String, dynamic>>> getAllProviderBalances() async {
    final db = await instance.database;
    return await db.query('provider_balances');
  }
// ثبت خرید کریدیت عمده با برچسب دکان
  Future<int> insertPurchase(Map<String, dynamic> row, UserModel user) async {
    final db = await instance.database;
    final Map<String, dynamic> data = {
      ...row,
      'shop_id': user.shopId,
      'created_by': user.uid,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.insert('purchases', data);
  }

  // دریافت لیست تامین‌کنندگان دکان فعلی
  Future<List<Map<String, dynamic>>> getProviders() async {
    final db = await instance.database;
    return await db.query('providers',);
  }

  Future<void> _seedProviders(Database db) async {
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

  Future<int> addCustomer(Customer c, List<String>? phones, List<Map<String, String>>? wholesaleCodes, UserModel user) async {  final db = await instance.database;
    return await db.transaction((txn) async {
      final customerMap = c.toMap();
      customerMap['shop_id'] = user.shopId;
      customerMap['created_by'] = user.uid;

      final id = await txn.insert('customers', customerMap);

      if (phones != null) {
        for (var p in phones) {
          await txn.insert('customer_phones', {'customer_id': id, 'phone_number': p});
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

  Future<void> updateCustomer(int id, Customer c, List<String>? phones, List<Map<String, String>>? wholesaleCodes, UserModel user) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // آپدیت اطلاعات پایه با شرط shop_id برای امنیت
      await txn.update(
        'customers',
        c.toMap(),
        where: 'id = ? AND shop_id = ?',
        whereArgs: [id, user.shopId],
      );

      // حذف موبایل‌های قبلی و ثبت جدید
      await txn.delete('customer_phones', where: 'customer_id = ?', whereArgs: [id]);
      if (phones != null) {
        for (var p in phones) {
          await txn.insert('customer_phones', {'customer_id': id, 'phone_number': p});
        }
      }

      // حذف کدهای عمده قبلی و ثبت جدید
      await txn.delete('customer_wholesale_codes', where: 'customer_id = ?', whereArgs: [id]);
      if (wholesaleCodes != null) {
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
// اضافه کردن پارامتر دوم (shopId) به تعریف تابع
  Future<List<Map<String, dynamic>>> searchCustomers(String query, String shopId) async {
    final db = await instance.database;

    return await db.query(
      'customers',
      // اضافه کردن شرط shop_id به کوئری
      where: '(name LIKE ? OR customer_code LIKE ?) AND shop_id = ?',
      whereArgs: ['%$query%', '%$query%', shopId],
    );
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
  Future<int> addProvider(Map<String, dynamic> providerMap) async {
    final db = await instance.database;
    return await db.insert('providers', providerMap);
  }
  Future<List<ProviderCompany>> getAllProviders(String shopId) async {
    final db = await instance.database;

    // فیلتر کردن بر اساس shop_id برای تفکیک دکان‌ها
    final res = await db.query(
        'providers',

    );

    // استفاده از factory method که در مدل ساختیم
    return res.map((e) => ProviderCompany.fromMap(e)).toList();
  }
//CRUD for TRANSACTION
  Future<int> addTransaction(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('transactions', data);
  }

// CRUD FOR UNIT SECTION
  // دریافت نرخ واحد مخصوص دکان
  // دریافت واحد مخصوص هر دکان (اگر نبود، یکی می‌سازد)
  Future<Map<String, dynamic>> getSingleUnit(String shopId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'units',
        where: 'shop_id = ?',
        whereArgs: [shopId],
        limit: 1
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      // ایجاد واحد پیش‌فرض برای دکان جدید
      final newData = {
        'buy_price': 0.95,
        'sell_price': 0.96,
        'name': 'واحد اصلی',
        'shop_id': shopId
      };
      await db.insert('units', newData);
      return newData;
    }
  }

  // آپدیت واحد فقط برای دکان فعلی
  Future<int> updateUnitByShop(double buy, double sell, String shopId) async {
    final db = await instance.database;
    return await db.update(
      'units',
      {'buy_price': buy, 'sell_price': sell},
      where: 'shop_id = ?',
      whereArgs: [shopId],
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
  // در فایل app_database.dart
  Future<int> saveDetailedTransaction(Map<String, dynamic> data, UserModel user) async {
    final db = await instance.database;

    double total = (data['total_price'] ?? 0.0).toDouble();
    double paid = (data['paid_amount'] ?? 0.0).toDouble();
    double remaining = total - paid;

    return await db.insert('transactions', {
      'shop_id': user.shopId,       // <--- اضافه شد: آیدی دکان
      'created_by': user.uid,        // <--- اضافه شد: آیدی ثبت کننده
      'customer_id': data['customer_id'],
      'customer_name': data['customer_name'] ?? 'مشتری رهگذر',
      'customer_type': data['customer_type'] ?? 'WALK_IN',
      'transaction_type': data['transaction_type'] ?? 'DIGITAL',
      'operator_name': data['operator_name'],
      'phone_number': data['phone_number'],
      'company_code': data['company_code'],
      'sent_amount': data['sent_amount'],
      'quantity': data['quantity'] ?? 1,
      'discount': data['discount'] ?? 0.0,
      'total_price': total,
      'paid_amount': paid,
      'remaining_amount': remaining,
      'received_amount': data['received_amount'] ?? paid,
      'cost_price': data['cost_price'],
      'profit': data['profit'],
      'ussd_command': data['ussd_command'],
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  Future<double> getCustomerTotalBalance(int customerId, String shopId) async {
    final db = await instance.database;
    var result = await db.rawQuery('''
        SELECT SUM(total_price) - SUM(paid_amount) as balance 
        FROM transactions 
        WHERE customer_id = ? AND shop_id = ?
        ''', [customerId, shopId]);

    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }
  Future<List<Map<String, dynamic>>> getFilteredTransactions(UserModel user) async {
    final db = await instance.database;

    if (user.role == 'OWNER') {
      // صاحب دکان: تمام تراکنش‌های دکان خودش
      return await db.query('transactions',
          where: 'shop_id = ?',
          whereArgs: [user.shopId],
          orderBy: 'created_at DESC');
    } else {
      // کارمند: فقط تراکنش‌هایی که خودش ثبت کرده
      return await db.query('transactions',
          where: 'shop_id = ? AND created_by = ?',
          whereArgs: [user.shopId, user.uid],
          orderBy: 'created_at DESC');
    }
  } // در فایل app_database.dart
  Future<int> insertDetailedTransaction(Map<String, dynamic> data, UserModel user) async {
    final db = await instance.database;

    // اضافه کردن اطلاعات کاربر به مپِ داده‌ها قبل از درج در دیتابیس
    final Map<String, dynamic> row = Map.from(data);
    row['shop_id'] = user.shopId;
    row['created_by'] = user.uid;
    row['created_at'] = DateTime.now().toIso8601String();

    return await db.insert('transactions', row);
  }
  Future<void> insertStaff(String uid, String name, String email, String shopId) async {
    final db = await instance.database;
    await db.insert('users', {
      'uid': uid,
      'name': name,
      'email': email,
      'role': 'STAFF',
      'shop_id': shopId, // آیدی دکانِ مدیری که او را ساخته
    });
  }
}
