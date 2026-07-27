import 'package:flutter/material.dart';
import 'package:top_up_shops/src/data/local/app_database.dart';

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;

      // روش 1: استفاده از query مستقیم
      _purchases = await db.query(
        'purchases',
        orderBy: 'id DESC', // جدیدترین اول
      );

      // روش 2: یا از rawQuery برای جزئیات بیشتر
      // _purchases = await db.rawQuery('''
      //   SELECT * FROM purchases
      //   ORDER BY created_at DESC
      // ''');

      print('✅ تعداد خریدهای یافت شده: ${_purchases.length}');
    } catch (e) {
      print('❌ خطا در خواندن purchases: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاهده خریدها'),
        actions: [
          IconButton(
            onPressed: _loadPurchases,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
          ? const Center(child: Text('هنوز خریدی ثبت نشده است'))
          : _buildPurchasesList(),
    );
  }

  Widget _buildPurchasesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        final purchase = _purchases[index];
        return _buildPurchaseCard(purchase);
      },
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> purchase) {
    final isPaper = purchase['type'] == 'PAPER';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // هدر کارت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    isPaper ? '📄 کارت کاغذی' : '📱 کریدیت دیجیتال',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: isPaper ? Colors.blue : Colors.green,
                ),
                Text(
                  'ID: ${purchase['id']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // اطلاعات اصلی
            if (isPaper) ...[
              _buildInfoRow(
                '🏢 تأمین‌کننده:',
                purchase['provider_name']?.toString() ?? '-',
              ),
              _buildInfoRow(
                '📞 اپراتور:',
                purchase['operator_name']?.toString() ?? '-',
              ),
              _buildInfoRow('💰 مقدار کارت:', '${purchase['face_value']} AFN'),
              _buildInfoRow('🔢 تعداد:', '${purchase['quantity']} عدد'),
              _buildInfoRow(
                '📦 مقدار کل:',
                '${(purchase['face_value'] as int? ?? 0) * (purchase['quantity'] as int? ?? 1)} AFN',
              ),
            ] else ...[
              _buildInfoRow(
                '🏢 تأمین‌کننده:',
                purchase['provider_name']?.toString() ?? '-',
              ),
              _buildInfoRow(
                '💰 مقدار کریدیت:',
                '${purchase['total_credit']} AFN',
              ),
            ],

            const SizedBox(height: 8),

            // اطلاعات مالی
            const Divider(),
            const SizedBox(height: 8),

            _buildInfoRow(
              '💵 قیمت فی واحد:',
              '${purchase['cost_per_unit']} AFN',
            ),

            if (purchase['actual_paid'] != null)
              _buildInfoRow(
                '💳 مبلغ پرداختی واقعی:',
                '${purchase['actual_paid']} AFN',
                isBold: true,
                color: Colors.green,
              ),

            if (purchase['nominal_price'] != null &&
                purchase['actual_paid'] != null)
              _buildInfoRow(
                '🎁 تخفیف:',
                '${(purchase['nominal_price'] as num? ?? 0) - (purchase['actual_paid'] as num? ?? 0)} AFN',
                color: Colors.orange,
              ),

            if (purchase['payment_status'] != null)
              _buildInfoRow(
                '📊 وضعیت پرداخت:',
                _getPaymentStatusText(purchase['payment_status']),
                color: _getPaymentStatusColor(purchase['payment_status']),
              ),

            const SizedBox(height: 8),

            // تاریخ
            if (purchase['created_at'] != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    purchase['created_at'].toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: isBold ? 15 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'FULL':
        return 'پرداخت کامل';
      case 'PARTIAL':
        return 'پرداخت جزئی';
      case 'PENDING':
        return 'در انتظار پرداخت';
      case 'OVERPAID':
        return 'پرداخت اضافی';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'FULL':
        return Colors.green;
      case 'PARTIAL':
        return Colors.orange;
      case 'PENDING':
        return Colors.red;
      case 'OVERPAID':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
