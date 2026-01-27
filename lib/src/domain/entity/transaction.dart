class TransactionModel {
  final int id;
  final int? customerId;
  final String customerName;
  final String customerType;
  final String transactionType;
  final String phoneNumber;
  final String companyCode;
  final String operator;
  final int quantity;
  final int sentAmount;

  // فیلدهای اصلی مالی
  final double totalPrice;
  final double paidAmount; // این همان مبلغ دریافتی است
  final double remainingAmount;
  final double costPrice;
  final int profit;
  final String createdAt;

  // --- رفع ارور: اضافه کردن Getter برای سازگاری با کدهای قدیمی ---
  // این خط باعث می‌شود هر جا در برنامه t.receivedAmount صدا زده شد، مقدار paidAmount برگردانده شود
  double get receivedAmount => paidAmount;

  TransactionModel({
    required this.id,
    this.customerId,
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
      customerId: map['customer_id'] as int?,
      customerName: (map['customer_name'] ?? 'نامشخص') as String,
      customerType: (map['customer_type'] ?? 'WALK_IN') as String,
      transactionType: (map['transaction_type'] ?? 'DIGITAL') as String,
      phoneNumber: (map['phone_number'] ?? '') as String,
      companyCode: (map['company_code'] ?? '') as String,
      operator: (map['operator_name'] ?? '') as String,
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      sentAmount: (map['sent_amount'] as num? ?? 0).toInt(),
      totalPrice: (map['total_price'] as num? ?? 0).toDouble(),
      // اینجا مقدار را از هر دو ستون احتمالی می‌خوانیم تا خطا ندهد
      paidAmount: (map['paid_amount'] as num? ?? map['received_amount'] as num? ?? 0).toDouble(),
      remainingAmount: (map['remaining_amount'] as num? ?? 0).toDouble(),
      costPrice: (map['cost_price'] as num? ?? 0).toDouble(),
      profit: (map['profit'] as num? ?? 0).toInt(),
      createdAt: (map['created_at'] ?? '') as String,
    );
  }
}