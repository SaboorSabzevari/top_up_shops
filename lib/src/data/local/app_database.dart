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
  Future<double> getCustomerTotalBalance(int customerId) async {
    final db = await instance.database;
    var result = await db.rawQuery(
        'SELECT SUM(remaining_amount) as total FROM transactions WHERE customer_id = ?',
        [customerId]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

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
