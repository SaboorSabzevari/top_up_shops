class TransactionModel {
  final int id;
  final String customerName;
  final String customerType; // اضافه شده
  final String phoneNumber;  // تغییر نام از phone به phoneNumber برای هماهنگی با UI
  final String companyCode;  // اضافه شده
  final String operator;
  final int sentAmount;
  final int receivedAmount;
  final int profit;
  final String createdAt;

  TransactionModel({
    required this.id,
    required this.customerName,
    required this.customerType,
    required this.phoneNumber,
    required this.companyCode,
    required this.operator,
    required this.sentAmount,
    required this.receivedAmount,
    required this.profit,
    required this.createdAt,
  });

  // در فایل transaction.dart متد fromMap را چک کنید:

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,
      customerName: (map['customer_name'] ?? '—') as String,
      customerType: (map['customer_type'] ?? 'normal') as String,
      phoneNumber: (map['phone_number'] ?? '') as String,
      companyCode: (map['company_code'] ?? '') as String,
      operator: (map['operator_name'] ?? 'نامشخص') as String,
      // استفاده از .toDouble().toInt() برای اطمینان از عدم خطا در مقادیر REAL
      sentAmount: (map['sent_amount'] as num? ?? 0).toInt(),
      receivedAmount: (map['received_amount'] as num? ?? 0).toInt(),
      profit: (map['profit'] as num? ?? 0).toInt(),
      createdAt: (map['created_at'] ?? '') as String,
    );
  }}