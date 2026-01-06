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

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,

      // دریافت نام مشتری
      customerName: (map['customer_name'] ?? '—') as String,

      // دریافت نوع مشتری (مطابق با نام ستون در app_database.dart)
      customerType: (map['customer_type'] ?? 'normal') as String,

      // دریافت شماره تماس (نام ستون در دیتابیس phone_number است)
      phoneNumber: (map['phone_number'] ?? '') as String,

      // دریافت کد شرکت (مطابق با نام ستون در app_database.dart)
      companyCode: (map['company_code'] ?? '') as String,

      // نکته مهم: در دیتابیس شما نام ستون operator_name است، نه operator
      operator: (map['operator_name'] ?? 'نامشخص') as String,

      sentAmount: (map['sent_amount'] ?? 0).toInt(),
      receivedAmount: (map['received_amount'] ?? 0).toInt(),
      profit: (map['profit'] ?? 0).toInt(),

      createdAt: (map['created_at'] ?? '') as String,
    );
  }
}