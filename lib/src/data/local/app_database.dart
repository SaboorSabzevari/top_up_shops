import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entity/customer.dart';
import '../../domain/entity/providers.dart';
import '../../services/session_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _dbVersion = 2;
  static const _uuid = Uuid();
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
    final shopId = SessionService.instance.currentShopId;
    return await db.query('transactions', where: 'date(created_at) = date(?) AND shop_id = ?', whereArgs: [date, shopId]);
  }
  Future<List<Map<String, dynamic>>> ajaxSearch(String query) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;

    return await db.query(
      'customers',
      where: 'shop_id = ? AND (name LIKE ? OR customer_code LIKE ?)',
      whereArgs: [shopId, '%$query%', '%$query%'],
      limit: 10,
    );
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, filePath),
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE shops (id TEXT PRIMARY KEY, name TEXT, phone TEXT, address TEXT, logo_path TEXT, owner_uid TEXT, status TEXT, subscription_status TEXT, subscription_plan TEXT, subscription_start TEXT, subscription_start_ms INTEGER, subscription_expiry TEXT, subscription_expiry_ms INTEGER, allow_view_on_expired INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE roles (id TEXT PRIMARY KEY, shop_id TEXT, name TEXT, permissions_json TEXT, is_system INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE employees (uid TEXT PRIMARY KEY, shop_id TEXT, full_name TEXT, role_id TEXT, status TEXT, phone TEXT, email TEXT, salary_contract_id TEXT, last_login_at TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, name TEXT, customer_code TEXT, type TEXT, profile_image TEXT, address TEXT, tazkira_image TEXT, balance_cache REAL DEFAULT 0, discount_rate REAL DEFAULT 0, pricing_tier TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE customer_phones (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, customer_id INTEGER, phone_number TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE customer_wholesale_codes (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, customer_id INTEGER, company_name TEXT, company_code TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('''
  CREATE TABLE units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    buy_price REAL NOT NULL,
    sell_price REAL NOT NULL,
    name TEXT,
    remote_id TEXT,
    shop_id TEXT,
    updated_at TEXT,
    version INTEGER DEFAULT 0,
    last_op_id TEXT,
    is_deleted INTEGER DEFAULT 0
  )
''');
    await db.execute('CREATE TABLE providers (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, name TEXT, type TEXT, ordinary_code TEXT, wholesale_code TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('''CREATE TABLE transactions (
     id INTEGER PRIMARY KEY AUTOINCREMENT, 
     remote_id TEXT,
     shop_id TEXT,
     transaction_type TEXT,
     refers_to_transaction_id TEXT,
     created_by_employee_id TEXT,
     event_at TEXT,
     customer_id INTEGER, 
     customer_name TEXT, 
     customer_type TEXT,
     operator_name TEXT, 
     phone_number TEXT, 
     company_code TEXT,
     sent_amount REAL, 
    
     discount REAL DEFAULT 0,        
     total_price REAL,               
     paid_amount REAL DEFAULT 0,
     remaining_amount REAL DEFAULT 0,
     
     received_amount REAL, 
     cost_price REAL, 
     profit REAL, 
     ussd_command TEXT, 
     payment_method TEXT,
     currency TEXT,
     metadata_json TEXT,
     created_at TEXT,
     updated_at TEXT,
     version INTEGER DEFAULT 0,
     last_op_id TEXT,
     is_deleted INTEGER DEFAULT 0
  )''');
    await db.execute('CREATE TABLE suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, name TEXT, phone TEXT, address TEXT, credit_limit REAL DEFAULT 0, balance_cache REAL DEFAULT 0, status TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE assets (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, name TEXT, category TEXT, purchase_price REAL DEFAULT 0, purchase_date TEXT, useful_life_months INTEGER, depreciation_method TEXT, current_value REAL, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE paper_card_batches (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, provider_id INTEGER, unit_id INTEGER, face_value REAL, buy_price REAL, sell_price REAL, quantity INTEGER, remaining_qty INTEGER, status TEXT, purchase_tx_remote_id TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE salary_contracts (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, employee_uid TEXT, type TEXT, base_amount REAL DEFAULT 0, commission_rate REAL DEFAULT 0, effective_from TEXT, effective_to TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE salary_payments (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, employee_uid TEXT, period_start TEXT, period_end TEXT, amount REAL DEFAULT 0, payment_method TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE outbox (id INTEGER PRIMARY KEY AUTOINCREMENT, op_id TEXT UNIQUE, shop_id TEXT, entity TEXT, entity_id TEXT, op_type TEXT, payload_json TEXT, base_version INTEGER, status TEXT, attempts INTEGER DEFAULT 0, next_attempt_at TEXT, created_at TEXT, last_error TEXT)');
    await db.execute('CREATE TABLE sync_state (entity TEXT PRIMARY KEY, last_pulled_at TEXT, last_doc_id TEXT)');
    await db.execute('CREATE TABLE conflicts (id INTEGER PRIMARY KEY AUTOINCREMENT, entity TEXT, entity_id TEXT, local_payload TEXT, remote_payload TEXT, created_at TEXT, resolved_at TEXT, resolution TEXT)');
    await db.execute('CREATE TABLE audit_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, employee_uid TEXT, action TEXT, entity TEXT, entity_id TEXT, payload TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0)');
    await _seedProviders(db);
    await _seedLocalDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateV2(db);
    }
  }

  Future<void> _migrateV2(Database db) async {
    await _createTableIfMissing(db, 'shops', 'id TEXT PRIMARY KEY, name TEXT, phone TEXT, address TEXT, logo_path TEXT, owner_uid TEXT, status TEXT, subscription_plan TEXT, subscription_status TEXT, subscription_start TEXT, subscription_start_ms INTEGER, subscription_expiry TEXT, subscription_expiry_ms INTEGER, allow_view_on_expired INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'roles', 'id TEXT PRIMARY KEY, shop_id TEXT, name TEXT, permissions_json TEXT, is_system INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'employees', 'uid TEXT PRIMARY KEY, shop_id TEXT, full_name TEXT, role_id TEXT, status TEXT, phone TEXT, email TEXT, salary_contract_id TEXT, last_login_at TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'customers', 'remote_id', 'TEXT');
    await _addColumnIfMissing(db, 'customers', 'shop_id', 'TEXT');
    await _addColumnIfMissing(db, 'customers', 'balance_cache', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'customers', 'discount_rate', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, 'customers', 'pricing_tier', 'TEXT');
    await _addColumnIfMissing(db, 'customers', 'updated_at', 'TEXT');
    await _addColumnIfMissing(db, 'customers', 'version', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'customers', 'last_op_id', 'TEXT');
    await _addColumnIfMissing(db, 'customers', 'is_deleted', 'INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'customer_phones', 'remote_id', 'TEXT');
    await _addColumnIfMissing(db, 'customer_phones', 'shop_id', 'TEXT');
    await _addColumnIfMissing(db, 'customer_phones', 'updated_at', 'TEXT');
    await _addColumnIfMissing(db, 'customer_phones', 'version', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'customer_phones', 'last_op_id', 'TEXT');
    await _addColumnIfMissing(db, 'customer_phones', 'is_deleted', 'INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'customer_wholesale_codes', 'remote_id', 'TEXT');
    await _addColumnIfMissing(db, 'customer_wholesale_codes', 'shop_id', 'TEXT');
    await _addColumnIfMissing(db, 'customer_wholesale_codes', 'updated_at', 'TEXT');
    await _addColumnIfMissing(db, 'customer_wholesale_codes', 'version', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'customer_wholesale_codes', 'last_op_id', 'TEXT');
    await _addColumnIfMissing(db, 'customer_wholesale_codes', 'is_deleted', 'INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'units', 'remote_id', 'TEXT');
    await _addColumnIfMissing(db, 'units', 'shop_id', 'TEXT');
    await _addColumnIfMissing(db, 'units', 'updated_at', 'TEXT');
    await _addColumnIfMissing(db, 'units', 'version', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'units', 'last_op_id', 'TEXT');
    await _addColumnIfMissing(db, 'units', 'is_deleted', 'INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'providers', 'remote_id', 'TEXT');
    await _addColumnIfMissing(db, 'providers', 'shop_id', 'TEXT');
    await _addColumnIfMissing(db, 'providers', 'updated_at', 'TEXT');
    await _addColumnIfMissing(db, 'providers', 'version', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'providers', 'last_op_id', 'TEXT');
    await _addColumnIfMissing(db, 'providers', 'is_deleted', 'INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'transactions', 'remote_id', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'shop_id', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'transaction_type', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'refers_to_transaction_id', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'created_by_employee_id', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'event_at', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'payment_method', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'currency', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'metadata_json', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'updated_at', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'version', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(db, 'transactions', 'last_op_id', 'TEXT');
    await _addColumnIfMissing(db, 'transactions', 'is_deleted', 'INTEGER DEFAULT 0');

    await _createTableIfMissing(db, 'suppliers', 'id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, name TEXT, phone TEXT, address TEXT, credit_limit REAL DEFAULT 0, balance_cache REAL DEFAULT 0, status TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'assets', 'id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, name TEXT, category TEXT, purchase_price REAL DEFAULT 0, purchase_date TEXT, useful_life_months INTEGER, depreciation_method TEXT, current_value REAL, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'paper_card_batches', 'id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, provider_id INTEGER, unit_id INTEGER, face_value REAL, buy_price REAL, sell_price REAL, quantity INTEGER, remaining_qty INTEGER, status TEXT, purchase_tx_remote_id TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'salary_contracts', 'id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, employee_uid TEXT, type TEXT, base_amount REAL DEFAULT 0, commission_rate REAL DEFAULT 0, effective_from TEXT, effective_to TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'salary_payments', 'id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, employee_uid TEXT, period_start TEXT, period_end TEXT, amount REAL DEFAULT 0, payment_method TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');
    await _createTableIfMissing(db, 'outbox', 'id INTEGER PRIMARY KEY AUTOINCREMENT, op_id TEXT UNIQUE, shop_id TEXT, entity TEXT, entity_id TEXT, op_type TEXT, payload_json TEXT, base_version INTEGER, status TEXT, attempts INTEGER DEFAULT 0, next_attempt_at TEXT, created_at TEXT, last_error TEXT');
    await _createTableIfMissing(db, 'sync_state', 'entity TEXT PRIMARY KEY, last_pulled_at TEXT, last_doc_id TEXT');
    await _createTableIfMissing(db, 'conflicts', 'id INTEGER PRIMARY KEY AUTOINCREMENT, entity TEXT, entity_id TEXT, local_payload TEXT, remote_payload TEXT, created_at TEXT, resolved_at TEXT, resolution TEXT');
    await _createTableIfMissing(db, 'audit_logs', 'id INTEGER PRIMARY KEY AUTOINCREMENT, remote_id TEXT, shop_id TEXT, employee_uid TEXT, action TEXT, entity TEXT, entity_id TEXT, payload TEXT, created_at TEXT, updated_at TEXT, version INTEGER DEFAULT 0, last_op_id TEXT, is_deleted INTEGER DEFAULT 0');

    await _addColumnIfMissing(db, 'shops', 'phone', 'TEXT');
    await _addColumnIfMissing(db, 'shops', 'address', 'TEXT');
    await _addColumnIfMissing(db, 'shops', 'logo_path', 'TEXT');
    await _addColumnIfMissing(db, 'shops', 'subscription_start_ms', 'INTEGER');
    await _addColumnIfMissing(db, 'shops', 'subscription_expiry_ms', 'INTEGER');
    await _backfillShopIds(db);
    await _ensureRemoteIds(db);
    await _seedLocalDefaults(db);
  }

  Future<void> _backfillShopIds(Database db) async {
    final shopId = SessionService.instance.currentShopId;
    await db.execute("UPDATE customers SET shop_id = ? WHERE shop_id IS NULL", [shopId]);
    await db.execute("UPDATE customer_phones SET shop_id = ? WHERE shop_id IS NULL", [shopId]);
    await db.execute("UPDATE customer_wholesale_codes SET shop_id = ? WHERE shop_id IS NULL", [shopId]);
    await db.execute("UPDATE units SET shop_id = ? WHERE shop_id IS NULL", [shopId]);
    await db.execute("UPDATE providers SET shop_id = ? WHERE shop_id IS NULL", [shopId]);
    await db.execute("UPDATE transactions SET shop_id = ? WHERE shop_id IS NULL", [shopId]);
  }

  Future<void> _ensureRemoteIds(Database db) async {
    await _assignRemoteIds(db, 'customers');
    await _assignRemoteIds(db, 'customer_phones');
    await _assignRemoteIds(db, 'customer_wholesale_codes');
    await _assignRemoteIds(db, 'units');
    await _assignRemoteIds(db, 'providers');
    await _assignRemoteIds(db, 'transactions');
  }

  Future<void> _assignRemoteIds(Database db, String table) async {
    final rows = await db.query(table, columns: ['id', 'remote_id']);
    for (final row in rows) {
      if (row['remote_id'] == null || (row['remote_id'] as String).isEmpty) {
        await db.update(
          table,
          {'remote_id': _uuid.v4()},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  Future<void> _createTableIfMissing(Database db, String table, String columns) async {
    await db.execute('CREATE TABLE IF NOT EXISTS $table ($columns)');
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _seedLocalDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    final shopId = SessionService.instance.currentShopId;
    final existing = await db.query('shops', where: 'id = ?', whereArgs: [shopId], limit: 1);
    if (existing.isEmpty) {
      final expiry = DateTime.now().add(const Duration(days: 365));
      await db.insert('shops', {
        'id': shopId,
        'name': 'فروشگاه من',
        'owner_uid': SessionService.instance.currentEmployeeId,
        'status': 'active',
        'subscription_status': 'active',
        'subscription_plan': 'yearly',
        'subscription_start': now,
        'subscription_start_ms': DateTime.now().millisecondsSinceEpoch,
        'subscription_expiry': expiry.toIso8601String(),
        'subscription_expiry_ms': expiry.millisecondsSinceEpoch,
        'allow_view_on_expired': 1,
        'created_at': now,
        'updated_at': now,
        'version': 0,
      });
    }

    final roleExists = await db.query('roles', where: 'id = ? AND shop_id = ?', whereArgs: ['owner', shopId], limit: 1);
    if (roleExists.isEmpty) {
      await db.insert('roles', {
        'id': 'owner',
        'shop_id': shopId,
        'name': 'مالک',
        'permissions_json': jsonEncode([
          'tx.create',
          'tx.refund',
          'customers.write',
          'reports.view',
          'inventory.write',
          'suppliers.write',
          'salaries.write',
          'employees.write',
          'settings.write',
        ]),
        'is_system': 1,
        'created_at': now,
        'updated_at': now,
        'version': 0,
      });
    }

    final employeeExists = await db.query('employees', where: 'uid = ? AND shop_id = ?', whereArgs: [SessionService.instance.currentEmployeeId, shopId], limit: 1);
    if (employeeExists.isEmpty) {
      await db.insert('employees', {
        'uid': SessionService.instance.currentEmployeeId,
        'shop_id': shopId,
        'full_name': 'مالک',
        'role_id': 'owner',
        'status': 'active',
        'created_at': now,
        'updated_at': now,
        'version': 0,
      });
    }
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

    final shopId = SessionService.instance.currentShopId;
    final now = DateTime.now().toIso8601String();
    for (var provider in initialProviders) {
      await db.insert('providers', {
        ...provider,
        'remote_id': _uuid.v4(),
        'shop_id': shopId,
        'updated_at': now,
        'version': 0,
      });
    }
  }

  Future<int> addCustomer(Customer c, List<String>? phones, List<Map<String, String>>? wholesaleCodes) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final shopId = SessionService.instance.currentShopId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    return await db.transaction((txn) async {
      final id = await txn.insert('customers', {
        ...c.toMap(),
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'version': 0,
        'last_op_id': opId,
      });

       if (phones != null && phones.isNotEmpty) {
        for (var p in phones) {
          await txn.insert('customer_phones', {
            'customer_id': id,
            'phone_number': p,
            'remote_id': _uuid.v4(),
            'shop_id': shopId,
            'updated_at': now,
            'version': 0,
            'last_op_id': opId,
          });
        }
      }
       if (wholesaleCodes != null && wholesaleCodes.isNotEmpty) {
        for (var item in wholesaleCodes) {
          await txn.insert('customer_wholesale_codes', {
            'customer_id': id,
            'company_name': item['company'],
            'company_code': item['code'],
            'remote_id': _uuid.v4(),
            'shop_id': shopId,
            'updated_at': now,
            'version': 0,
            'last_op_id': opId,
          });
        }
      }
      await enqueueOutbox(
        txn,
        opId: opId,
        entity: 'customers',
        entityId: remoteId,
        opType: 'create',
        payload: {
          ...c.toMap(),
          'remote_id': remoteId,
          'shop_id': shopId,
          'phones': phones ?? [],
          'wholesale_codes': wholesaleCodes ?? [],
          'updated_at': now,
          'created_at': now,
          'version': 0,
          'last_op_id': opId,
        },
        baseVersion: 0,
      );
      return id;
    });
  }

  Future<void> updateCustomer(int id, Customer customer, List<String>? phones, List<Map<String, String>>? wholesaleCodes) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final existing = await txn.query('customers', where: 'id = ?', whereArgs: [id], limit: 1);
      if (existing.isEmpty) return;
      final row = existing.first;
      final prevVersion = (row['version'] as int? ?? 0);
      final remoteId = row['remote_id'] as String? ?? _uuid.v4();
      final shopId = row['shop_id'] as String? ?? SessionService.instance.currentShopId;
      final now = DateTime.now().toIso8601String();
      final opId = _uuid.v4();
       await txn.update(
        'customers',
        {
          ...customer.toMap(),
          'remote_id': remoteId,
          'shop_id': shopId,
          'updated_at': now,
          'version': prevVersion + 1,
          'last_op_id': opId,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.delete('customer_phones', where: 'customer_id = ?', whereArgs: [id]);
      if (phones != null && phones.isNotEmpty) {
        for (var phone in phones) {
          await txn.insert('customer_phones', {
            'customer_id': id,
            'phone_number': phone,
            'remote_id': _uuid.v4(),
            'shop_id': shopId,
            'updated_at': now,
            'version': 0,
            'last_op_id': opId,
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
            'remote_id': _uuid.v4(),
            'shop_id': shopId,
            'updated_at': now,
            'version': 0,
            'last_op_id': opId,
          });
        }
      }
      await enqueueOutbox(
        txn,
        opId: opId,
        entity: 'customers',
        entityId: remoteId,
        opType: 'update',
        payload: {
          ...customer.toMap(),
          'remote_id': remoteId,
          'shop_id': shopId,
          'phones': phones ?? [],
          'wholesale_codes': wholesaleCodes ?? [],
          'updated_at': now,
          'version': prevVersion + 1,
          'last_op_id': opId,
        },
        baseVersion: prevVersion,
      );
    });
  }
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    return await db.query('customers', where: 'shop_id = ? AND (name LIKE ? OR customer_code LIKE ?)', whereArgs: [shopId, '%$query%', '%$query%']);
  }

  Future<Map<String, dynamic>> getCustomerFullDetails(int id) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final customer = await db.query('customers', where: 'id = ? AND shop_id = ?', whereArgs: [id, shopId]);
    final result = Map<String, dynamic>.from(customer.first);
    result['phones'] = await db.query('customer_phones', where: 'customer_id = ? AND shop_id = ?', whereArgs: [id, shopId]);
    result['wholesale_codes'] = await db.query('customer_wholesale_codes', where: 'customer_id = ? AND shop_id = ?', whereArgs: [id, shopId]);
    return result;
  }

  //CRUD for providers
  Future<int> addProvider(ProviderCompany p) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final now = DateTime.now().toIso8601String();
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final id = await db.insert('providers', {
      ...p.toMap(),
      'remote_id': remoteId,
      'shop_id': shopId,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    });
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'providers',
      entityId: remoteId,
      opType: 'create',
      payload: {
        ...p.toMap(),
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'created_at': now,
        'version': 0,
        'last_op_id': opId,
      },
      baseVersion: 0,
    );
    return id;
  }

  Future<List<ProviderCompany>> getAllProviders() async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final res = await db.query('providers', where: 'shop_id = ? AND (is_deleted IS NULL OR is_deleted = 0)', whereArgs: [shopId]);
    return res.map((e) => ProviderCompany(id: e['id'] as int, name: e['name'] as String, type: e['type'] as String, ordinaryCode: e['ordinary_code'] as String, wholesaleCode: e['wholesale_code'] as String)).toList();
  }
//CRUD for TRANSACTION
  Future<int> addTransaction(Map<String, dynamic> data) async {
    if (!SessionService.instance.subscriptionActive) {
      throw StateError('اشتراک فروشگاه منقضی شده است');
    }
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final shopId = SessionService.instance.currentShopId;
    final employeeId = SessionService.instance.currentEmployeeId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final payload = {
      ...data,
      'remote_id': remoteId,
      'shop_id': shopId,
      'created_by_employee_id': employeeId,
      'transaction_type': data['transaction_type'] ?? 'topup_sale',
      'event_at': data['event_at'] ?? now,
      'payment_method': data['payment_method'] ?? 'cash',
      'currency': data['currency'] ?? 'AFN',
      'metadata_json': data['metadata_json'] ?? jsonEncode({}),
      'created_at': now,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('transactions', payload);
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'transactions',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    return id;
  }

// CRUD FOR UNIT SECTION
  Future<Map<String, dynamic>> getSingleUnit() async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final List<Map<String, dynamic>> maps = await db.query('units', where: 'id = ? AND shop_id = ?', whereArgs: [1, shopId]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      final now = DateTime.now().toIso8601String();
      final remoteId = _uuid.v4();
      final opId = _uuid.v4();
       await db.insert('units', {
        'id': 1,
        'buy_price': 0.95,
        'sell_price': 0.96,
        'name': 'واحد اصلی سیستم',
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'version': 0,
        'last_op_id': opId,
      });
      await enqueueOutbox(
        db,
        opId: opId,
        entity: 'units',
        entityId: remoteId,
        opType: 'create',
        payload: {
          'id': 1,
          'buy_price': 0.95,
          'sell_price': 0.96,
          'name': 'واحد اصلی سیستم',
          'remote_id': remoteId,
          'shop_id': shopId,
          'updated_at': now,
          'created_at': now,
          'version': 0,
          'last_op_id': opId,
        },
        baseVersion: 0,
      );
      return {'id': 1, 'buy_price': 0.95, 'sell_price': 0.96, 'name': 'واحد اصلی سیستم'};
    }
  }

  Future<int> updateSingleUnit(double buy, double sell) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final rows = await db.query('units', where: 'id = ? AND shop_id = ?', whereArgs: [1, shopId], limit: 1);
    if (rows.isEmpty) {
      return updateUnit(1, buy, sell);
    }
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      'units',
      {
        'buy_price': buy,
        'sell_price': sell,
        'updated_at': now,
        'version': prevVersion + 1,
        'last_op_id': opId,
      },
      where: 'id = ? AND shop_id = ?',
      whereArgs: [1, shopId],
    );
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'units',
      entityId: remoteId,
      opType: 'update',
      payload: {
        'id': 1,
        'buy_price': buy,
        'sell_price': sell,
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'version': prevVersion + 1,
        'last_op_id': opId,
      },
      baseVersion: prevVersion,
    );
    return count;
  }

  Future<int> addUnit(double buy, double sell) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final now = DateTime.now().toIso8601String();
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();
    final id = await db.insert('units', {
      'buy_price': buy,
      'sell_price': sell,
      'name': 'واحد جدید',
      'remote_id': remoteId,
      'shop_id': shopId,
      'updated_at': now,
      'version': 0,
      'last_op_id': opId,
    });
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'units',
      entityId: remoteId,
      opType: 'create',
      payload: {
        'buy_price': buy,
        'sell_price': sell,
        'name': 'واحد جدید',
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'created_at': now,
        'version': 0,
        'last_op_id': opId,
      },
      baseVersion: 0,
    );
    return id;
  }

  Future<int> updateUnit(int id, double buy, double sell) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final rows = await db.query('units', where: 'id = ? AND shop_id = ?', whereArgs: [id, shopId], limit: 1);
    if (rows.isEmpty) return 0;
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      'units',
      {
        'buy_price': buy,
        'sell_price': sell,
        'updated_at': now,
        'version': prevVersion + 1,
        'last_op_id': opId,
      },
      where: 'id = ? AND shop_id = ?',
      whereArgs: [id, shopId],
    );
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'units',
      entityId: remoteId,
      opType: 'update',
      payload: {
        'buy_price': buy,
        'sell_price': sell,
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'version': prevVersion + 1,
        'last_op_id': opId,
      },
      baseVersion: prevVersion,
    );
    return count;
  }

  Future<int> deleteUnit(int id) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    final rows = await db.query('units', where: 'id = ? AND shop_id = ?', whereArgs: [id, shopId], limit: 1);
    if (rows.isEmpty) return 0;
    final row = rows.first;
    final prevVersion = (row['version'] as int? ?? 0);
    final remoteId = row['remote_id'] as String? ?? _uuid.v4();
    final opId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      'units',
      {'is_deleted': 1, 'updated_at': now, 'version': prevVersion + 1, 'last_op_id': opId},
      where: 'id = ? AND shop_id = ?',
      whereArgs: [id, shopId],
    );
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'units',
      entityId: remoteId,
      opType: 'delete',
      payload: {
        'remote_id': remoteId,
        'shop_id': shopId,
        'updated_at': now,
        'version': prevVersion + 1,
        'last_op_id': opId,
        'is_deleted': 1,
      },
      baseVersion: prevVersion,
    );
    return count;
  }
// method for save transaction
  // در فایل app_database.dart، این متد را جایگزین قبلی کنید:
  Future<int> saveDetailedTransaction(Map<String, dynamic> data) async {
    if (!SessionService.instance.subscriptionActive) {
      throw StateError('اشتراک فروشگاه منقضی شده است');
    }
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final shopId = SessionService.instance.currentShopId;
    final employeeId = SessionService.instance.currentEmployeeId;
    final remoteId = _uuid.v4();
    final opId = _uuid.v4();

    // اطمینان از اینکه مقادیر عددی هستند
    double total = (data['total_price'] ?? 0.0).toDouble();
    double paid = (data['paid_amount'] ?? 0.0).toDouble();
    double remaining = total - paid;

    final payload = {
      'customer_id': data['customer_id'],
      'customer_name': data['customer_name'],
      'customer_type': data['customer_type'],
      'operator_name': data['operator_name'],
      'phone_number': data['phone_number'],
      'company_code': data['company_code'],
      'sent_amount': data['sent_amount'],
      'remaining_amount': remaining, // حالا این ستون در جدول وجود دارد

      'discount': data['discount'] ?? 0.0,
      'total_price': total,
      'paid_amount': paid,

      'received_amount': data['received_amount'] ?? total,
      'cost_price': data['cost_price'],
      'profit': data['profit'],
      'ussd_command': data['ussd_command'],
      'created_at': now,
      'updated_at': now,
      'remote_id': remoteId,
      'shop_id': shopId,
      'created_by_employee_id': employeeId,
      'transaction_type': data['transaction_type'] ?? 'topup_sale',
      'event_at': data['event_at'] ?? now,
      'payment_method': data['payment_method'] ?? 'cash',
      'currency': data['currency'] ?? 'AFN',
      'metadata_json': data['metadata_json'] ?? jsonEncode({}),
      'version': 0,
      'last_op_id': opId,
    };
    final id = await db.insert('transactions', payload);
    await enqueueOutbox(
      db,
      opId: opId,
      entity: 'transactions',
      entityId: remoteId,
      opType: 'create',
      payload: payload,
      baseVersion: 0,
    );
    return id;
  }
  Future<double> getCustomerTotalBalance(int customerId) async {
    final db = await instance.database;
    final shopId = SessionService.instance.currentShopId;
    var result = await db.rawQuery(
        'SELECT SUM(total_price) - SUM(paid_amount) as balance FROM transactions WHERE customer_id = ? AND shop_id = ?',
        [customerId, shopId]
    );
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> addRefundTransaction({
    required String originalRemoteId,
    required int? customerId,
    required String customerName,
    required String customerType,
    required String operatorName,
    required String phoneNumber,
    required String companyCode,
    required double amount,
    required double originalReceivedAmount,
    required double originalProfit,
    required String reason,
  }) async {
    if (!SessionService.instance.subscriptionActive) {
      throw StateError('اشتراک فروشگاه منقضی شده است');
    }
    final now = DateTime.now().toIso8601String();
    final ratio = originalReceivedAmount == 0 ? 0 : (amount / originalReceivedAmount);
    final refundProfit = -(originalProfit * ratio);
    final payload = {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_type': customerType,
      'operator_name': operatorName,
      'phone_number': phoneNumber,
      'company_code': companyCode,
      'sent_amount': 0,
      'remaining_amount': 0,
      'discount': 0,
      'total_price': -amount,
      'paid_amount': -amount,
      'received_amount': -amount,
      'cost_price': 0,
      'profit': refundProfit,
      'ussd_command': '',
      'transaction_type': 'refund',
      'refers_to_transaction_id': originalRemoteId,
      'metadata_json': jsonEncode({'reason': reason}),
      'event_at': now,
      'created_at': now,
      'payment_method': 'cash',
      'currency': 'AFN',
    };
    return addTransaction(payload);
  }

  Future<void> enqueueOutbox(
    DatabaseExecutor db, {
    required String opId,
    required String entity,
    required String entityId,
    required String opType,
    required Map<String, dynamic> payload,
    required int baseVersion,
  }) async {
    final now = DateTime.now();
    final updatedMs = now.millisecondsSinceEpoch;
    final payloadWithMeta = Map<String, dynamic>.from(payload);
    payloadWithMeta.putIfAbsent('updated_at_ms', () => updatedMs);
    if (opType == 'create') {
      payloadWithMeta.putIfAbsent('created_at_ms', () => updatedMs);
    }
    await db.insert('outbox', {
      'op_id': opId,
      'shop_id': SessionService.instance.currentShopId,
      'entity': entity,
      'entity_id': entityId,
      'op_type': opType,
      'payload_json': jsonEncode(payloadWithMeta),
      'base_version': baseVersion,
      'status': 'pending',
      'attempts': 0,
      'next_attempt_at': null,
      'created_at': DateTime.now().toIso8601String(),
      'last_error': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
