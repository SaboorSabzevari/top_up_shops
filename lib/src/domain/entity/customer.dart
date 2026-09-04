// مسیر پیشنهادی: lib/src/domain/entity/customer.dart
// تغییر کلیدی: id اکنون String است (آیدی سند Firestore) و phones /
// wholesaleCodes به‌صورت لیست بومی ذخیره می‌شوند (نه رشته‌ی JSON)، چون
// Firestore خودش از آرایه و مپ تودرتو پشتیبانی می‌کند.
class Customer {
  final String? id;
  final String? remoteId;
  final String name;
  final String customerCode;
  final String type; // 'ORDINARY' یا 'WHOLESALE'
  final String shopId;
  final String createdBy;
  final String? profileImage;
  final String? address;
  final String? tazkiraImage;
  final List<String> phones;
  final List<Map<String, String>> wholesaleCodes;

  Customer({
    this.id,
    this.remoteId,
    required this.name,
    required this.customerCode,
    required this.type,
    required this.shopId,
    required this.createdBy,
    this.profileImage,
    this.address,
    this.tazkiraImage,
    this.phones = const [],
    this.wholesaleCodes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'customer_code': customerCode,
      'type': type,
      'shop_id': shopId,
      'created_by': createdBy,
      'address': address,
      'profile_image': profileImage,
      'tazkira_image': tazkiraImage,
      'phones': phones,
      'wholesale_codes': wholesaleCodes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    List<String> phonesList = [];
    final rawPhones = map['phones'];
    if (rawPhones is List) {
      phonesList = rawPhones
          .map((p) => p is Map ? (p['phone_number']?.toString() ?? '') : p.toString())
          .where((s) => s.isNotEmpty)
          .cast<String>()
          .toList();
    }

    List<Map<String, String>> wholesaleList = [];
    final rawCodes = map['wholesale_codes'];
    if (rawCodes is List) {
      wholesaleList = rawCodes
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
          .toList();
    }

    return Customer(
      id: map['id']?.toString(),
      remoteId: map['id']?.toString(),
      name: (map['name'] ?? '') as String,
      customerCode: (map['customer_code'] ?? '') as String,
      type: (map['type'] ?? 'ORDINARY') as String,
      shopId: (map['shop_id'] ?? '') as String,
      createdBy: (map['created_by'] ?? '') as String,
      profileImage: map['profile_image'] as String?,
      address: map['address'] as String?,
      tazkiraImage: map['tazkira_image'] as String?,
      phones: phonesList,
      wholesaleCodes: wholesaleList,
    );
  }
}