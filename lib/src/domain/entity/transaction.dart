class TransactionEntity {
  final int? id;
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final int providerId;
  final String providerName;
  final String targetDestination; // شماره یا کد شرکت
  final String providerUsedCode;
  final double creditAmount;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String communicationMethod;
  final String transactionDate;
  final String transactionTime;

  TransactionEntity({
    this.id, required this.customerId, required this.customerName,
    required this.customerCode, required this.customerType,
    required this.providerId, required this.providerName,
    required this.targetDestination, required this.providerUsedCode,
    required this.creditAmount, required this.discount,
    required this.totalAmount, required this.paidAmount,
    required this.remainingAmount, required this.communicationMethod,
    required this.transactionDate, required this.transactionTime,
  });

  Map<String, dynamic> toMap() => {
    'customer_id': customerId, 'customer_name': customerName,
    'customer_code': customerCode, 'customer_type': customerType,
    'provider_id': providerId, 'provider_name': providerName,
    'target_destination': targetDestination, 'provider_used_code': providerUsedCode,
    'credit_amount': creditAmount, 'discount': discount,
    'total_amount': totalAmount, 'paid_amount': paidAmount,
    'remaining_amount': remainingAmount, 'communication_method': communicationMethod,
    'transaction_date': transactionDate, 'transaction_time': transactionTime,
  };
}