import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entity/customer.dart';
import '../../domain/entity/providers.dart';
import '../../providers/session_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  static const _uuid = Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('topup_system.db');
    return _database!;
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'transaction_date = ?',
      whereArgs: [date],
    );
  }

  Future<List<Map<String, dynamic>>> ajaxSearch(
    String query,
    String shopId,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
    SELECT id, name, customer_code, type 
    FROM customers 
    WHERE (name LIKE ? OR customer_code LIKE ?) AND shop_id = ?
    LIMIT 10
  ''',
      ['%$query%', '%$query%', shopId],
    );
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, filePath),
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _ensureIndexes,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final table in _syncTables) {
        await _ensureMetadataColumns(db, table);
      }
      await _ensureIndexes(db);
    }
    if (oldVersion < 3) {
      await _ensureColumn(db, 'transactions', 'customer_remote_id', 'TEXT');
      await _ensureColumn(db, 'sync_state', 'last_pulled_doc_id', 'TEXT');
      await _backfillTransactionCustomerRemoteIds(db);
    }
  }

  static const List<String> _syncTables = [
    'customers',
    'transactions',
    'purchases',
    'units',
    'paper_stock',
    'provider_balances',
    'providers',
  ];

  Future<void> _ensureMetadataColumns(Database db, String table) async {
    final existing = (await db.rawQuery(
      'PRAGMA table_info($table)',
    )).map((row) => row['name'] as String).toSet();

    Future<void> addColumn(String name, String type) async {
      if (!existing.contains(name)) {
        await db.execute('ALTER TABLE $table ADD COLUMN $name $type');
      }
    }

    await addColumn('remote_id', 'TEXT');
    await addColumn('created_at_server', 'TEXT');
    await addColumn('updated_at_server', 'TEXT');
    await addColumn('version', 'INTEGER DEFAULT 1');
    await addColumn('deleted_at', 'TEXT');
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String name,
    String type,
  ) async {
    final existing = (await db.rawQuery(
      'PRAGMA table_info($table)',
    )).map((row) => row['name'] as String).toSet();
    if (!existing.contains(name)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $name $type');
    }
  }

  Future<void> _backfillTransactionCustomerRemoteIds(Database db) async {
    await db.rawUpdate('''
      UPDATE transactions
      SET customer_remote_id = (
        SELECT customers.remote_id
        FROM customers
        WHERE customers.id = transactions.customer_id
          AND customers.shop_id = transactions.shop_id
        LIMIT 1
      )
      WHERE customer_remote_id IS NULL
        AND customer_id IS NOT NULL
    ''');
  }

  Future<void> _ensureIndexes(Database db) async {
    for (final table in _syncTables) {
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_${table}_remote_id ON $table(remote_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_shop_updated ON $table(shop_id, updated_at_server)',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_shop_created ON transactions(shop_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_shop_search ON customers(shop_id, name, customer_code)',
    );
    await db.execute('DROP INDEX IF EXISTS idx_customers_shop_code');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT,
    record_id INTEGER,
    operation TEXT,
    sync_time TEXT,
    status TEXT
  )
''');
    await db.execute('''CREATE TABLE customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    name TEXT, 
    customer_code TEXT, 
    type TEXT, 
    shop_id TEXT NOT NULL, 
    created_by TEXT,
    profile_image TEXT, 
    address TEXT, 
    tazkira_image TEXT,
    phones TEXT DEFAULT '[]', -- JSON array برای ذخیره چندین شماره
    wholesale_codes TEXT DEFAULT '[]', -- JSON array برای ذخیره چندین کد شرکت
    remote_id TEXT UNIQUE,
    created_at_server TEXT,
    updated_at_server TEXT,
    version INTEGER DEFAULT 1,
    deleted_at TEXT
  )''');
    // await db.execute('CREATE TABLE customer_phones (id INTEGER PRIMARY KEY AUTOINCREMENT, shop_id TEXT, customer_id INTEGER, phone_number TEXT)');
    await db.execute('''CREATE TABLE units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    buy_price REAL NOT NULL,
    sell_price REAL NOT NULL,
    name TEXT,
    shop_id TEXT NOT NULL,
    remote_id TEXT UNIQUE,
    created_at_server TEXT,
    updated_at_server TEXT,
    version INTEGER DEFAULT 1,
    deleted_at TEXT
  )''');
    await db.execute('''
  CREATE TABLE outbox (
    op_id TEXT PRIMARY KEY,
    shop_id TEXT,
    entity TEXT,
    entity_id TEXT,
    op_type TEXT,
    payload_json TEXT,
    status TEXT DEFAULT 'pending', -- pending, syncing, failed
    attempts INTEGER DEFAULT 0,
    next_attempt_at_ms INTEGER,
    created_at_ms INTEGER
  )
''');

    await db.execute('''
  CREATE TABLE sync_state (
    entity TEXT PRIMARY KEY,
    last_pulled_at TEXT,
    last_pulled_doc_id TEXT
  )
''');

    await db.execute('''
  CREATE TABLE providers (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    name TEXT NOT NULL,
    type TEXT,
    ordinary_code TEXT,
    wholesale_code TEXT,
    shop_id TEXT,  
    created_at TEXT,
    remote_id TEXT UNIQUE,
    created_at_server TEXT,
    updated_at_server TEXT,
    version INTEGER DEFAULT 1,
    deleted_at TEXT
  )
''');
    await db.execute('''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- مشخصات مشتری
    customer_id INTEGER,                 -- اگر مشتری ناشناس باشد، این مقدار NULL است
    customer_remote_id TEXT,
    customer_name TEXT,                  -- نام مشتری یا "مشتری رهگذر"
    customer_type TEXT,                  -- 'REGISTERED' (ثبت شده) یا 'WALK_IN' (رهگذر)
    shop_id TEXT NOT NULL,         -- اضافه شد
    created_by TEXT NOT NULL,      -- اضافه شد
    is_synced INTEGER DEFAULT 0,
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
    created_at TEXT,                     -- تاریخ و زمان دقیق تراکنش
    remote_id TEXT UNIQUE,
    created_at_server TEXT,
    updated_at_server TEXT,
    version INTEGER DEFAULT 1,
    deleted_at TEXT
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
    created_by TEXT NOT NULL,
    remote_id TEXT UNIQUE,
    created_at_server TEXT,
    updated_at_server TEXT,
    version INTEGER DEFAULT 1,
    deleted_at TEXT
  )''');
    // در متد _createDB، جدول paper_stock را اصلاح کنید:
    await db.execute('''
    CREATE TABLE IF NOT EXISTS paper_stock (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      operator_name TEXT,
      face_value INTEGER,
      quantity INTEGER DEFAULT 0,
      shop_id TEXT,
      remote_id TEXT UNIQUE,
      created_at_server TEXT,
      updated_at_server TEXT,
      version INTEGER DEFAULT 1,
      deleted_at TEXT,
      UNIQUE(operator_name, face_value, shop_id)
    )
  ''');
    await db.execute('''CREATE TABLE provider_balances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_name TEXT, 
    current_balance REAL DEFAULT 0,
    shop_id TEXT NOT NULL,
    remote_id TEXT UNIQUE,
    created_at_server TEXT,
    updated_at_server TEXT,
    version INTEGER DEFAULT 1,
    deleted_at TEXT,
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
    for (final table in _syncTables) {
      await _ensureMetadataColumns(db, table);
    }
    await _ensureIndexes(db);
  }
  // --- مدیریت موجودی کارت کاغذی ---

  Future<void> enqueueOutbox(
    DatabaseExecutor db, {
    required String entity,
    required String entityId,
    required String opType,
    required Map<String, dynamic> payload,
    String? shopId,
  }) async {
    final opId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('outbox', {
      'op_id': opId,
      'shop_id':
          shopId ?? payload['shop_id'] ?? SessionService.instance.currentShopId,
      'entity': entity,
      'entity_id': entityId,
      'op_type': opType,
      'payload_json': jsonEncode(payload),
      'created_at_ms': now,
      'next_attempt_at_ms': now,
    });
  }

  Map<String, dynamic> _withMetadata(
    Map<String, dynamic> data, {
    required String shopId,
    bool isCreate = true,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final remoteId = (data['remote_id']?.toString().isNotEmpty ?? false)
        ? data['remote_id'].toString()
        : _uuid.v4();
    return {
      ...data,
      'shop_id': shopId,
      'remote_id': remoteId,
      if (isCreate) 'created_at_server': data['created_at_server'] ?? now,
      'updated_at_server': now,
      'version': ((data['version'] as num?)?.toInt() ?? 0) + 1,
      'deleted_at': data['deleted_at'],
    };
  }

  Future<void> _enqueueEntityChange(
    DatabaseExecutor db, {
    required String table,
    required String opType,
    required Map<String, dynamic> row,
    required String shopId,
  }) {
    return enqueueOutbox(
      db,
      entity: table,
      entityId: row['remote_id'].toString(),
      opType: opType,
      payload: row,
      shopId: shopId,
    );
  }

  String _providerBalanceRemoteId(String providerName, String shopId) {
    return 'provider_balance_${Uri.encodeComponent(shopId)}_${Uri.encodeComponent(providerName)}';
  }

  String _paperStockRemoteId(String operator, int faceValue, String shopId) {
    return 'paper_stock_${Uri.encodeComponent(shopId)}_${Uri.encodeComponent(operator)}_$faceValue';
  }

  Future<String> _uniqueCustomerCode(
    DatabaseExecutor db,
    String baseCode,
    String shopId, {
    int? excludingId,
  }) async {
    final seed = baseCode.trim().isEmpty
        ? 'CUST-${DateTime.now().millisecondsSinceEpoch}'
        : baseCode.trim();
    var candidate = seed;
    var suffix = 1;

    while (true) {
      final rows = await db.query(
        'customers',
        columns: ['id'],
        where:
            'customer_code = ? AND shop_id = ? AND deleted_at IS NULL${excludingId == null ? '' : ' AND id != ?'}',
        whereArgs: excludingId == null
            ? [candidate, shopId]
            : [candidate, shopId, excludingId],
        limit: 1,
      );
      if (rows.isEmpty) return candidate;
      suffix++;
      candidate = '$seed-$suffix';
    }
  }

  Future<String?> _resolveCustomerRemoteId(
    DatabaseExecutor db,
    Object? customerId,
    String shopId,
  ) async {
    if (customerId == null) return null;
    final rows = await db.query(
      'customers',
      columns: ['remote_id'],
      where: 'id = ? AND shop_id = ? AND deleted_at IS NULL',
      whereArgs: [customerId, shopId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['remote_id'] as String?;
  }

  Future<Map<String, dynamic>> _normalizeTransactionData(
    DatabaseExecutor db,
    Map<String, dynamic> data,
    UserModel user,
  ) async {
    final row = Map<String, dynamic>.from(data);
    final paid =
        (row['paid_amount'] as num? ?? row['received_amount'] as num? ?? 0)
            .toDouble();
    row['paid_amount'] = paid;
    row['received_amount'] = paid;
    row['customer_remote_id'] ??= await _resolveCustomerRemoteId(
      db,
      row['customer_id'],
      user.shopId,
    );
    return row;
  }

  // کاهش موجودی (هنگام فروش)
  // در DatabaseHelper
  Future<int> decreasePaperStock(
    String operator,
    int faceValue,
    int qty,
    String shopId,
  ) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final res = await txn.query(
        'paper_stock',
        where:
            'operator_name = ? AND face_value = ? AND shop_id = ? AND deleted_at IS NULL',
        whereArgs: [operator, faceValue, shopId],
      );
      if (res.isEmpty) {
        throw Exception("این کارت در انبار دکان شما تعریف نشده است.");
      }
      final currentQty = (res.first['quantity'] as num).toInt();
      if (currentQty < qty) {
        throw Exception("موجودی کافی نیست! موجودی فعلی: $currentQty");
      }
      final row = _withMetadata(
        {...res.first, 'quantity': currentQty - qty},
        shopId: shopId,
        isCreate: false,
      );
      final updated = await txn.update(
        'paper_stock',
        row,
        where: 'id = ?',
        whereArgs: [res.first['id']],
      );
      await _enqueueEntityChange(
        txn,
        table: 'paper_stock',
        opType: 'update',
        row: row,
        shopId: shopId,
      );
      return updated;
    });
  }

  Future<void> increasePaperStock(
    String operator,
    int faceValue,
    int qty,
    String shopId,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await _increasePaperStockTxn(txn, operator, faceValue, qty, shopId);
    });
  }

  Future<Map<String, dynamic>> _increasePaperStockTxn(
    DatabaseExecutor txn,
    String operator,
    int faceValue,
    int qty,
    String shopId,
  ) async {
    final existing = await txn.query(
      'paper_stock',
      where: 'operator_name = ? AND face_value = ? AND shop_id = ?',
      whereArgs: [operator, faceValue, shopId],
      limit: 1,
    );
    late Map<String, dynamic> row;
    if (existing.isEmpty) {
      row = _withMetadata({
        'operator_name': operator,
        'face_value': faceValue,
        'quantity': qty,
        'remote_id': _paperStockRemoteId(operator, faceValue, shopId),
      }, shopId: shopId);
      final id = await txn.insert('paper_stock', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'paper_stock',
        opType: 'increment',
        row: {...row, '_delta_quantity': qty},
        shopId: shopId,
      );
    } else {
      row = _withMetadata(
        {
          ...existing.first,
          'quantity': (existing.first['quantity'] as num).toInt() + qty,
          'remote_id': _paperStockRemoteId(operator, faceValue, shopId),
        },
        shopId: shopId,
        isCreate: false,
      );
      await txn.update(
        'paper_stock',
        row,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      await _enqueueEntityChange(
        txn,
        table: 'paper_stock',
        opType: 'increment',
        row: {...row, '_delta_quantity': qty},
        shopId: shopId,
      );
    }
    return row;
  }

  Future<int> getPaperStockCount(
    String operator,
    int faceValue,
    String shopId,
  ) async {
    final db = await instance.database;
    final res = await db.query(
      'paper_stock',
      columns: ['quantity'],
      where:
          'LOWER(operator_name) = LOWER(?) AND face_value = ? AND shop_id = ? AND deleted_at IS NULL',
      whereArgs: [operator, faceValue, shopId],
    );
    return res.isNotEmpty ? (res.first['quantity'] as num).toInt() : 0;
  }

  Future<List<Map<String, dynamic>>> getAllPaperStocks() async {
    final db = await instance.database;
    return await db.query(
      'paper_stock',
      where: 'deleted_at IS NULL',
      orderBy: 'operator_name, face_value',
    );
  }

  // ۱. افزایش موجودی شرکت (هنگام خرید کریدیت عمده)
  Future<void> increaseProviderBalance(
    String providerName,
    double amount,
    String shopId,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await _increaseProviderBalanceTxn(txn, providerName, amount, shopId);
    });
  }

  Future<Map<String, dynamic>> _increaseProviderBalanceTxn(
    DatabaseExecutor txn,
    String providerName,
    double amount,
    String shopId,
  ) async {
    final existing = await txn.query(
      'provider_balances',
      where: 'provider_name = ? AND shop_id = ?',
      whereArgs: [providerName, shopId],
      limit: 1,
    );
    late Map<String, dynamic> row;
    if (existing.isEmpty) {
      row = _withMetadata({
        'provider_name': providerName,
        'current_balance': amount,
        'remote_id': _providerBalanceRemoteId(providerName, shopId),
      }, shopId: shopId);
      final id = await txn.insert('provider_balances', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'provider_balances',
        opType: 'increment',
        row: {...row, '_delta_balance': amount},
        shopId: shopId,
      );
    } else {
      row = _withMetadata(
        {
          ...existing.first,
          'current_balance':
              (existing.first['current_balance'] as num).toDouble() + amount,
          'remote_id': _providerBalanceRemoteId(providerName, shopId),
        },
        shopId: shopId,
        isCreate: false,
      );
      await txn.update(
        'provider_balances',
        row,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      await _enqueueEntityChange(
        txn,
        table: 'provider_balances',
        opType: 'increment',
        row: {...row, '_delta_balance': amount},
        shopId: shopId,
      );
    }
    return row;
  }

  // ۲. کاهش موجودی شرکت (هنگام فروش به مشتری)
  Future<void> decreaseProviderBalance(
    String providerName,
    double amount,
    String shopId,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await _decreaseProviderBalanceTxn(txn, providerName, amount, shopId);
    });
  }

  Future<Map<String, dynamic>> _decreaseProviderBalanceTxn(
    DatabaseExecutor txn,
    String providerName,
    double amount,
    String shopId,
  ) async {
    final existing = await txn.query(
      'provider_balances',
      where: 'provider_name = ? AND shop_id = ? AND deleted_at IS NULL',
      whereArgs: [providerName, shopId],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('موجودی شرکت "$providerName" تعریف نشده است.');
    }
    final current = (existing.first['current_balance'] as num).toDouble();
    if (current < amount) {
      throw Exception(
        'موجودی شرکت "$providerName" کافی نیست! موجودی فعلی: $current',
      );
    }
    final row = _withMetadata(
      {...existing.first, 'current_balance': current - amount},
      shopId: shopId,
      isCreate: false,
    );
    await txn.update(
      'provider_balances',
      row,
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
    await _enqueueEntityChange(
      txn,
      table: 'provider_balances',
      opType: 'increment',
      row: {...row, '_delta_balance': -amount},
      shopId: shopId,
    );
    return row;
  }

  // ۳. دریافت موجودی فعلی یک شرکت خاص
  Future<double> getProviderBalance(String providerName, String shopId) async {
    final db = await instance.database;
    final res = await db.query(
      'provider_balances',
      columns: ['current_balance'],
      where: 'provider_name = ? AND shop_id = ? AND deleted_at IS NULL',
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
    return await db.query('provider_balances', where: 'deleted_at IS NULL');
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
    return await db.transaction((txn) async {
      final row = _withMetadata(data, shopId: user.shopId);
      final id = await txn.insert('purchases', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'purchases',
        opType: 'create',
        row: row,
        shopId: user.shopId,
      );
      return id;
    });
  }

  // دریافت لیست تامین‌کنندگان دکان فعلی
  Future<List<Map<String, dynamic>>> getProviders([String? shopId]) async {
    final db = await instance.database;
    if (shopId == null || shopId.isEmpty) {
      return await db.query('providers', where: 'deleted_at IS NULL');
    }
    return await db.query(
      'providers',
      where: '(shop_id = ? OR shop_id IS NULL) AND deleted_at IS NULL',
      whereArgs: [shopId],
    );
  }

  Future<void> _seedProviders(Database db) async {
    final List<Map<String, dynamic>> initialProviders = [
      {
        'name': 'ستارگان متحد',
        'type': 'ستارگان متحد',
        'ordinary_code': '543*2',
        'wholesale_code': '543*6',
      },
      {
        'name': 'اکتیو سرویس',
        'type': 'اکتیو سرویس',
        'ordinary_code': '683',
        'wholesale_code': '683*2',
      },
      {
        'name': 'افغان پی',
        'type': 'افغان پی',
        'ordinary_code': '511',
        'wholesale_code': '511*5',
      },
      {
        'name': 'شاهی ایزیلود',
        'type': 'شاهی ایزیلود',
        'ordinary_code': '545',
        'wholesale_code': '511*5',
      },
    ];

    for (var provider in initialProviders) {
      await db.insert('providers', {
        ...provider,
        'remote_id': _uuid.v4(),
        'created_at_server': DateTime.now().toUtc().toIso8601String(),
        'updated_at_server': DateTime.now().toUtc().toIso8601String(),
        'version': 1,
      });
    }
  }

  Future<int> addCustomer(
    Customer c,
    List<String>? phones,
    List<Map<String, String>>? wholesaleCodes,
    UserModel user,
  ) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final customerMap = c.toMap();
      customerMap['shop_id'] = user.shopId;
      customerMap['created_by'] = user.uid;
      customerMap['customer_code'] = await _uniqueCustomerCode(
        txn,
        c.customerCode,
        user.shopId,
      );

      // تبدیل لیست‌ها به JSON
      if (phones != null && phones.isNotEmpty) {
        customerMap['phones'] = jsonEncode(phones);
      } else {
        customerMap['phones'] = '[]';
      }

      if (wholesaleCodes != null && wholesaleCodes.isNotEmpty) {
        customerMap['wholesale_codes'] = jsonEncode(wholesaleCodes);
      } else {
        customerMap['wholesale_codes'] = '[]';
      }

      final row = _withMetadata(customerMap, shopId: user.shopId);
      final id = await txn.insert('customers', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'customers',
        opType: 'create',
        row: row,
        shopId: user.shopId,
      );
      return id;
    });
  }

  Future<void> updateCustomer(
    int id,
    Customer c,
    List<String>? phones,
    List<Map<String, String>>? wholesaleCodes,
    UserModel user,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final Map<String, dynamic> updateData = {
        'name': c.name,
        'customer_code': await _uniqueCustomerCode(
          txn,
          c.customerCode,
          user.shopId,
          excludingId: id,
        ),
        'type': c.type,
        'shop_id': user.shopId,
        'created_by': user.uid,
        'address': c.address,
        'profile_image': c.profileImage,
        'tazkira_image': c.tazkiraImage,
      };

      // آپدیت JSON‌ها
      updateData['phones'] = jsonEncode(phones ?? []);
      updateData['wholesale_codes'] = jsonEncode(wholesaleCodes ?? []);

      final existing = await txn.query(
        'customers',
        where: 'id = ? AND shop_id = ?',
        whereArgs: [id, user.shopId],
        limit: 1,
      );
      final row = _withMetadata(
        {...?existing.firstOrNull, ...updateData},
        shopId: user.shopId,
        isCreate: false,
      );
      await txn.update(
        'customers',
        row,
        where: 'id = ? AND shop_id = ?',
        whereArgs: [id, user.shopId],
      );
      await _enqueueEntityChange(
        txn,
        table: 'customers',
        opType: 'update',
        row: row,
        shopId: user.shopId,
      );
    });
  }

  Future<List<Map<String, dynamic>>> searchCustomers(
    String query,
    String shopId,
  ) async {
    final db = await instance.database;

    return await db.query(
      'customers',
      where:
          '(name LIKE ? OR customer_code LIKE ? OR phones LIKE ?) AND shop_id = ? AND deleted_at IS NULL',
      whereArgs: ['%$query%', '%$query%', '%$query%', shopId],
    );
  }

  Future<Map<String, dynamic>> getCustomerFullDetails(int id) async {
    final db = await instance.database;
    final customer = await db.query(
      'customers',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );

    if (customer.isEmpty) {
      return {};
    }

    final result = Map<String, dynamic>.from(customer.first);

    // پارس کردن JSON‌ها
    try {
      final phonesJson = result['phones'] as String?;
      if (phonesJson != null && phonesJson.isNotEmpty) {
        final parsed = jsonDecode(phonesJson);
        if (parsed is List) {
          // اگر JSON یک لیست مستقیم از شماره‌هاست
          result['phones'] = parsed.map((phone) {
            if (phone is Map) {
              return phone;
            } else {
              return {'phone_number': phone.toString()};
            }
          }).toList();
        } else {
          result['phones'] = [];
        }
      } else {
        result['phones'] = [];
      }
    } catch (e) {
      result['phones'] = [];
    }

    try {
      final codesJson = result['wholesale_codes'] as String?;
      if (codesJson != null && codesJson.isNotEmpty) {
        final parsed = jsonDecode(codesJson);
        if (parsed is List) {
          result['wholesale_codes'] = parsed.map((code) {
            if (code is Map) {
              return {
                'company_name': code['company'] ?? code['company_name'],
                'company_code': code['code'] ?? code['company_code'],
              };
            }
            return code;
          }).toList();
        } else {
          result['wholesale_codes'] = [];
        }
      } else {
        result['wholesale_codes'] = [];
      }
    } catch (e) {
      result['wholesale_codes'] = [];
    }

    return result;
  }

  Future<int> addProvider(Map<String, dynamic> providerMap) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final shopId = providerMap['shop_id']?.toString() ?? '';
      final row = _withMetadata(providerMap, shopId: shopId);
      final id = await txn.insert('providers', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'providers',
        opType: 'create',
        row: row,
        shopId: shopId,
      );
      return id;
    });
  }

  Future<List<ProviderCompany>> getAllProviders(String shopId) async {
    final db = await instance.database;

    // فیلتر کردن بر اساس shop_id برای تفکیک دکان‌ها
    final res = await db.query(
      'providers',
      where: '(shop_id = ? OR shop_id IS NULL) AND deleted_at IS NULL',
      whereArgs: [shopId],
    );

    // استفاده از factory method که در مدل ساختیم
    return res.map((e) => ProviderCompany.fromMap(e)).toList();
  }

  //CRUD for TRANSACTION
  Future<int> addTransaction(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final shopId =
          data['shop_id']?.toString() ?? SessionService.instance.currentShopId;
      final user = SessionService.instance.user;
      final normalized = user == null
          ? data
          : await _normalizeTransactionData(txn, data, user);
      final row = _withMetadata(normalized, shopId: shopId);
      final id = await txn.insert('transactions', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'transactions',
        opType: 'create',
        row: row,
        shopId: shopId,
      );
      return id;
    });
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
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      // ایجاد واحد پیش‌فرض برای دکان جدید
      final newData = {
        'buy_price': 0.95,
        'sell_price': 0.96,
        'name': 'واحد اصلی',
        'shop_id': shopId,
      };
      final row = _withMetadata(newData, shopId: shopId);
      await db.insert('units', row);
      return newData;
    }
  }

  // آپدیت واحد فقط برای دکان فعلی
  Future<int> updateUnitByShop(double buy, double sell, String shopId) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final existing = await txn.query(
        'units',
        where: 'shop_id = ? AND deleted_at IS NULL',
        whereArgs: [shopId],
        limit: 1,
      );
      final row = _withMetadata(
        {
          ...?existing.firstOrNull,
          'buy_price': buy,
          'sell_price': sell,
          'name': existing.firstOrNull?['name'] ?? 'واحد اصلی',
        },
        shopId: shopId,
        isCreate: existing.isEmpty,
      );
      final id = existing.isEmpty
          ? await txn.insert('units', row)
          : await txn.update(
              'units',
              row,
              where: 'id = ?',
              whereArgs: [existing.first['id']],
            );
      await _enqueueEntityChange(
        txn,
        table: 'units',
        opType: existing.isEmpty ? 'create' : 'update',
        row: row,
        shopId: shopId,
      );
      return id;
    });
  }

  Future<int> addUnit(double buy, double sell) async {
    final db = await instance.database;
    return await db.insert('units', {
      'buy_price': buy,
      'sell_price': sell,
      'name': 'واحد جدید',
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
    return db.transaction((txn) async {
      final existing = await txn.query(
        'units',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isEmpty) return 0;
      final shopId =
          existing.first['shop_id']?.toString() ??
          SessionService.instance.currentShopId;
      final row = _withMetadata(
        {
          ...existing.first,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        },
        shopId: shopId,
        isCreate: false,
      );
      final count = await txn.update(
        'units',
        row,
        where: 'id = ?',
        whereArgs: [id],
      );
      await _enqueueEntityChange(
        txn,
        table: 'units',
        opType: 'delete',
        row: row,
        shopId: shopId,
      );
      return count;
    });
  }

  // در فایل app_database.dart
  Future<int> saveDetailedTransaction(
    Map<String, dynamic> data,
    UserModel user,
  ) async {
    final db = await instance.database;

    double total = (data['total_price'] ?? 0.0).toDouble();
    double paid = (data['paid_amount'] ?? 0.0).toDouble();
    double remaining = total - paid;

    return await db.transaction((txn) async {
      final normalized = await _normalizeTransactionData(db, {
        'shop_id': user.shopId, // <--- اضافه شد: آیدی دکان
        'created_by': user.uid, // <--- اضافه شد: آیدی ثبت کننده
        'customer_id': data['customer_id'],
        'customer_remote_id': data['customer_remote_id'],
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
      }, user);
      final row = _withMetadata(normalized, shopId: user.shopId);
      final id = await txn.insert('transactions', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'transactions',
        opType: 'create',
        row: row,
        shopId: user.shopId,
      );
      return id;
    });
  }

  Future<double> getCustomerTotalBalance(int customerId, String shopId) async {
    final db = await instance.database;
    var result = await db.rawQuery(
      '''
        SELECT SUM(total_price) - SUM(paid_amount) as balance 
        FROM transactions 
        WHERE customer_id = ? AND shop_id = ? AND deleted_at IS NULL
        ''',
      [customerId, shopId],
    );

    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getFilteredTransactions(
    UserModel user,
  ) async {
    final db = await instance.database;
    // برای همه یکسان: تمام تراکنش‌های دکان
    return await db.query(
      'transactions',
      where: 'shop_id = ? AND deleted_at IS NULL',
      whereArgs: [user.shopId],
      orderBy: 'created_at DESC',
    );
  } // در فایل app_database.dart

  Future<int> insertDetailedTransaction(
    Map<String, dynamic> data,
    UserModel user,
  ) async {
    final Map<String, dynamic> row = Map.from(data);
    row['shop_id'] = user.shopId;
    row['created_by'] = user.uid;
    row['created_at'] = DateTime.now().toIso8601String();

    return await addTransaction(row);
  }

  Future<int> recordDigitalSale({
    required Map<String, dynamic> transactionData,
    required String providerName,
    required double amount,
    required UserModel user,
  }) async {
    final db = await instance.database;
    return db.transaction((txn) async {
      await _decreaseProviderBalanceTxn(txn, providerName, amount, user.shopId);
      final normalized = await _normalizeTransactionData(txn, {
        ...transactionData,
        'shop_id': user.shopId,
        'created_by': user.uid,
        'created_at': DateTime.now().toIso8601String(),
      }, user);
      final row = _withMetadata(normalized, shopId: user.shopId);
      final id = await txn.insert('transactions', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'transactions',
        opType: 'create',
        row: row,
        shopId: user.shopId,
      );
      return id;
    });
  }

  Future<int> recordPaperSale({
    required Map<String, dynamic> transactionData,
    required String operator,
    required int faceValue,
    required int quantity,
    required UserModel user,
  }) async {
    final db = await instance.database;
    return db.transaction((txn) async {
      final stockRows = await txn.query(
        'paper_stock',
        where:
            'operator_name = ? AND face_value = ? AND shop_id = ? AND deleted_at IS NULL',
        whereArgs: [operator, faceValue, user.shopId],
        limit: 1,
      );
      if (stockRows.isEmpty) {
        throw Exception("این کارت در انبار دکان شما تعریف نشده است.");
      }
      final currentQty = (stockRows.first['quantity'] as num).toInt();
      if (currentQty < quantity) {
        throw Exception("موجودی کافی نیست! موجودی فعلی: $currentQty");
      }
      final stockRow = _withMetadata(
        {
          ...stockRows.first,
          'quantity': currentQty - quantity,
          'remote_id': _paperStockRemoteId(operator, faceValue, user.shopId),
        },
        shopId: user.shopId,
        isCreate: false,
      );
      await txn.update(
        'paper_stock',
        stockRow,
        where: 'id = ?',
        whereArgs: [stockRows.first['id']],
      );
      await _enqueueEntityChange(
        txn,
        table: 'paper_stock',
        opType: 'increment',
        row: {...stockRow, '_delta_quantity': -quantity},
        shopId: user.shopId,
      );

      final normalized = await _normalizeTransactionData(txn, {
        ...transactionData,
        'shop_id': user.shopId,
        'created_by': user.uid,
        'created_at': DateTime.now().toIso8601String(),
      }, user);
      final saleRow = _withMetadata(normalized, shopId: user.shopId);
      final id = await txn.insert('transactions', saleRow);
      saleRow['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'transactions',
        opType: 'create',
        row: saleRow,
        shopId: user.shopId,
      );
      return id;
    });
  }

  Future<int> recordPurchase({
    required Map<String, dynamic> purchaseData,
    required UserModel user,
    String? stockOperator,
    int? stockFaceValue,
    int? stockQuantity,
    String? providerName,
    double? providerCreditAmount,
  }) async {
    final db = await instance.database;
    return db.transaction((txn) async {
      if (stockOperator != null &&
          stockFaceValue != null &&
          stockQuantity != null) {
        await _increasePaperStockTxn(
          txn,
          stockOperator,
          stockFaceValue,
          stockQuantity,
          user.shopId,
        );
      }
      if (providerName != null && providerCreditAmount != null) {
        await _increaseProviderBalanceTxn(
          txn,
          providerName,
          providerCreditAmount,
          user.shopId,
        );
      }

      final row = _withMetadata({
        ...purchaseData,
        'shop_id': user.shopId,
        'created_by': user.uid,
        'created_at': DateTime.now().toIso8601String(),
      }, shopId: user.shopId);
      final id = await txn.insert('purchases', row);
      row['id'] = id;
      await _enqueueEntityChange(
        txn,
        table: 'purchases',
        opType: 'create',
        row: row,
        shopId: user.shopId,
      );
      return id;
    });
  }

  // Future<void> insertStaff(String uid, String name, String email, String shopId) async {
  //   final db = await instance.database;
  //   await db.insert('users', {
  //     'uid': uid,
  //     'name': name,
  //     'email': email,
  //     'role': 'STAFF',
  //     'shop_id': shopId, // آیدی دکانِ مدیری که او را ساخته
  //   });
  // }
}
