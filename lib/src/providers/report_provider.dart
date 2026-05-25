import '../data/local/app_database.dart';

Future<List<Map<String, dynamic>>> getFilteredReport({
  required String companyName,
  required String startDate,
  required String endDate,
  required String shopId, // اضافه شدن shopId الزامی است
}) async {
  final db = await DatabaseHelper.instance.database;

  return await db.rawQuery('''
    SELECT *, 
    (sent_amount - paid_amount) as debt 
    FROM transactions 
    WHERE operator_name = ? 
    AND shop_id = ? 
    AND date(created_at) BETWEEN ? AND ?
    ORDER BY created_at DESC
  ''', [companyName, shopId, startDate, endDate]);
}