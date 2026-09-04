// مسیر پیشنهادی: lib/src/domain/entity/transaction.dart
// تغییر کلیدی نسبت به نسخه‌ی قبلی: id و customerId اکنون String هستند
// (چون آیدی سند در Firestore رشته است، نه عدد auto-increment مثل SQLite).
class TransactionModel {
  final String id;
  final String shopId;
  final String createdBy;
  final String? customerId;
  final String? customerRemoteId;
  final String customerName;
  final String customerType;
  final String transactionType;
  final String phoneNumber;
  final String companyCode;
  final String operator;
  final int quantity;
  final int sentAmount;
  final double totalPrice;
  final double paidAmount;
  final double remainingAmount;
  final double costPrice;
  final int profit;
  final String createdAt;

  double get receivedAmount => paidAmount;

  TransactionModel({
    required this.id,
    required this.shopId,
    required this.createdBy,
    this.customerId,
    this.customerRemoteId,
    required this.customerName,
    required this.customerType,
    required this.transactionType,
    required this.phoneNumber,
    required this.companyCode,
    required this.operator,
    required this.quantity,
    required this.sentAmount,
    required this.totalPrice,
    required this.paidAmount,
    required this.remainingAmount,
    required this.costPrice,
    required this.profit,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: (map['id'] ?? '').toString(),
      shopId: (map['shop_id'] ?? '') as String,
      createdBy: (map['created_by'] ?? '') as String,
      customerId: map['customer_id']?.toString(),
      customerRemoteId: map['customer_remote_id']?.toString(),
      customerName: (map['customer_name'] ?? 'نامشخص') as String,
      customerType: (map['customer_type'] ?? 'WALK_IN') as String,
      transactionType: (map['transaction_type'] ?? 'DIGITAL') as String,
      phoneNumber: (map['phone_number'] ?? '') as String,
      companyCode: (map['company_code'] ?? '') as String,
      operator: (map['operator_name'] ?? '') as String,
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      sentAmount: (map['sent_amount'] as num? ?? 0).toInt(),
      totalPrice: (map['total_price'] as num? ?? 0).toDouble(),
      paidAmount:
      (map['paid_amount'] as num? ?? map['received_amount'] as num? ?? 0)
          .toDouble(),
      remainingAmount: (map['remaining_amount'] as num? ?? 0).toDouble(),
      costPrice: (map['cost_price'] as num? ?? 0).toDouble(),
      profit: (map['profit'] as num? ?? 0).toInt(),
      createdAt: (map['created_at'] ?? '') as String,
    );
  }
}