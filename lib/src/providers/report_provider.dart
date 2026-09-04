// مسیر پیشنهادی: lib/src/providers/report_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getFilteredReport({
  required String companyName,
  required String startDate, // 'YYYY-MM-DD'
  required String endDate, // 'YYYY-MM-DD'
  required String shopId,
}) async {
  final start = DateTime.parse(startDate);
  final end = DateTime.parse(endDate).add(const Duration(days: 1));

  final snap = await FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .collection('transactions')
      .where('operator_name', isEqualTo: companyName)
      .where('created_at', isGreaterThanOrEqualTo: start.toIso8601String())
      .where('created_at', isLessThan: end.toIso8601String())
      .get();

  final rows = snap.docs
      .where((d) => d.data()['deleted_at'] == null)
      .map((d) {
    final data = Map<String, dynamic>.from(d.data());
    data['id'] = d.id;
    final sent = (data['sent_amount'] as num? ?? 0).toDouble();
    final paid = (data['paid_amount'] as num? ?? 0).toDouble();
    data['debt'] = sent - paid;
    return data;
  })
      .toList();

  rows.sort((a, b) => (b['created_at'] ?? '').toString().compareTo(
    (a['created_at'] ?? '').toString(),
  ));
  return rows;
}