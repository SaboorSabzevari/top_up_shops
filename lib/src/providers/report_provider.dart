import '../data/local/app_database.dart';

Future<List<Map<String, dynamic>>> getFilteredReport(String companyName, String startDate, String endDate) async {
  final db = await DatabaseHelper.instance.database;
  return await db.rawQuery('''
    SELECT *, (credit_amount - paid_amount) as debt FROM transactions 
    WHERE provider_name = ? AND transaction_date BETWEEN ? AND ?
  ''', [companyName, startDate, endDate]);
}