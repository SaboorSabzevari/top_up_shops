class TransactionModel {
  final int id;
  final String shopId; // اضافه شد
  final String createdBy; // اضافه شد (UID کارمند یا مدیر)
  final int? customerId;
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
    required this.shopId, // اضافه شد
    required this.createdBy, // اضافه شد
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
      id: map['id'] as int,
      shopId: (map['shop_id'] ?? '') as String, // خواندن از دیتابیس
      createdBy: (map['created_by'] ?? '') as String, // خواندن از دیتابیس
      customerId: map['customer_id'] as int?,
      customerRemoteId: map['customer_remote_id'] as String?,
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
