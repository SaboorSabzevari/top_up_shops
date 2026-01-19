import '../data/local/app_database.dart';
import '../services/session_service.dart';

Future<List<Map<String, dynamic>>> getFilteredReport(String companyName, String startDate, String endDate) async {
  final db = await DatabaseHelper.instance.database;
  final shopId = SessionService.instance.currentShopId;
  return await db.rawQuery('''
    SELECT *, (total_price - paid_amount) as debt FROM transactions 
    WHERE operator_name = ? AND date(created_at) BETWEEN date(?) AND date(?) AND shop_id = ?
  ''', [companyName, startDate, endDate, shopId]);
}
