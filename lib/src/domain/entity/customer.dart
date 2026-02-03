class Customer {
  final int? id;
  final String shopId; // اضافه شد
  final String name;
  final String customerCode;
  final String type; // 'ORDINARY' یا 'WHOLESALE'
  final String? profileImage;
  final String? address;
  final String? tazkiraImage;

  Customer({
    this.id,
    required this.shopId, // اجباری شد
    required this.name,
    required this.customerCode,
    required this.type,
    this.profileImage,
    this.address,
    this.tazkiraImage
  });

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId, // ذخیره در دیتابیس برای تفکیک
      'name': name,
      'customer_code': customerCode,
      'type': type,
      'address': address,
      'profile_image': profileImage,
      'tazkira_image': tazkiraImage,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      shopId: (map['shop_id'] ?? '') as String,
      name: map['name'] as String,
      customerCode: map['customer_code'] as String,
      type: map['type'] as String,
      address: map['address'] as String?,
      profileImage: map['profile_image'] as String?,
      tazkiraImage: map['tazkira_image'] as String?,
    );
  }
}