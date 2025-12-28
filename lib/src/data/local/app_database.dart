import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../domain/entity/customer.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('topup_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return await openDatabase(join(dbPath, filePath), version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, customer_code TEXT, type TEXT, profile_image TEXT, address TEXT, tazkira_image TEXT)');
    await db.execute('CREATE TABLE customer_phones (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, phone_number TEXT)');
    await db.execute('CREATE TABLE customer_wholesale_codes (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, company_name TEXT, company_code TEXT)');
    await db.execute('CREATE TABLE providers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, ordinary_code TEXT, wholesale_code TEXT)');
    await db.execute('''CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, customer_code TEXT, customer_type TEXT,
      provider_id INTEGER, provider_name TEXT, target_destination TEXT, provider_used_code TEXT,
      credit_amount REAL, discount REAL, total_amount REAL, paid_amount REAL, remaining_amount REAL,
      communication_method TEXT, transaction_date TEXT)''');
  }

  // --- عملیات مشتریان ---
  Future<int> insertCustomer(Customer c) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('customers', c.toMap());
      if (c.type == 'ORDINARY' && c.phones != null) {
        for (var p in c.phones!) {
          await txn.insert('customer_phones', {'customer_id': id, 'phone_number': p});
        }
      } else if (c.type == 'WHOLESALE' && c.wholesaleCodes != null) {
        for (var w in c.wholesaleCodes!) {
          await txn.insert('customer_wholesale_codes', {'customer_id': id, 'company_name': w['company'], 'company_code': w['code']});
        }
      }
      return id;
    });
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await instance.database;
    return await db.query('customers', where: 'name LIKE ? OR customer_code LIKE ?', whereArgs: ['%$query%', '%$query%']);
  }

  // متد AJAX برای گرفتن جزئیات کامل مشتری
  Future<Map<String, dynamic>> getFullCustomer(int id) async {
    final db = await instance.database;
    final c = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    final result = Map<String, dynamic>.from(c.first);
    if (result['type'] == 'ORDINARY') {
      result['phones'] = await db.query('customer_phones', where: 'customer_id = ?', whereArgs: [id]);
    } else {
      result['wholesale_codes'] = await db.query('customer_wholesale_codes', where: 'customer_id = ?', whereArgs: [id]);
    }
    return result;
  }
}