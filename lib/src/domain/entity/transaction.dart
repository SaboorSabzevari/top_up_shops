class TransactionModel {
  final int id;
  final String? remoteId;
  final String? shopId;
  final int? customerId;
  final String customerName;
  final String customerType;
  final String phoneNumber;
  final String companyCode;
  final String operator;
  final int sentAmount;
  final int receivedAmount;
  final int profit;
  final String createdAt;
  final String? eventAt;
  final String? transactionType;
  final String? refersToTransactionId;
  final String? createdByEmployeeId;
  final String? paymentMethod;
  final String? currency;
  final String? metadataJson;
  final bool isDeleted;
  final double totalPrice; // مبلغ نهایی فاکتور
  final double paidAmount;  // مبلغ پرداختی توسط مشتری
  final double remainingAmount; // باقی‌مانده

  TransactionModel({
    required this.id,
    this.remoteId,
    this.shopId,
    required this.customerName,
    required this.customerType,
    required this.phoneNumber,
    required this.companyCode,
    required this.operator,
    required this.sentAmount,
    required this.receivedAmount,
    required this.profit,
    required this.createdAt,
    this.eventAt,
    this.transactionType,
    this.refersToTransactionId,
    this.createdByEmployeeId,
    this.paymentMethod,
    this.currency,
    this.metadataJson,
    this.isDeleted = false,
    this.customerId, required this.totalPrice, required this.paidAmount, required this.remainingAmount,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,
      remoteId: map['remote_id'] as String?,
      shopId: map['shop_id'] as String?,
      customerId: map['customer_id'] as int?,
      customerName: (map['customer_name'] ?? '—') as String,
      customerType: (map['customer_type'] ?? 'normal') as String,
      phoneNumber: (map['phone_number'] ?? '') as String,
      companyCode: (map['company_code'] ?? '') as String,
      operator: (map['operator_name'] ?? 'نامشخص') as String,
      sentAmount: (map['sent_amount'] as num? ?? 0).toInt(),
      receivedAmount: (map['received_amount'] as num? ?? 0).toInt(),
      profit: (map['profit'] as num? ?? 0).toInt(),
      createdAt: (map['created_at'] ?? '') as String,
      eventAt: map['event_at'] as String?,
      transactionType: map['transaction_type'] as String?,
      refersToTransactionId: map['refers_to_transaction_id'] as String?,
      createdByEmployeeId: map['created_by_employee_id'] as String?,
      paymentMethod: map['payment_method'] as String?,
      currency: map['currency'] as String?,
      metadataJson: map['metadata_json'] as String?,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      totalPrice: (map['total_price'] as num? ?? 0).toDouble(),
      paidAmount: (map['paid_amount'] as num? ?? 0).toDouble(),
      remainingAmount: (map['remaining_amount'] as num? ?? 0).toDouble(),);
  }
}
