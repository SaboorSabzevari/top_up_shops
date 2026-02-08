import 'dart:convert';

class Customer {
  final int? id;
  final String name;
  final String customerCode;
  final String type; // 'ORDINARY' یا 'WHOLESALE'
  final String shopId;
  final String createdBy;
  final String? profileImage;
  final String? address;
  final String? tazkiraImage;
  final List<String> phones; // ✅ اضافه شد
  final List<Map<String, String>> wholesaleCodes; // ✅ اضافه شد

  Customer({
    this.id,
    required this.name,
    required this.customerCode,
    required this.type,
    required this.shopId,
    required this.createdBy,
    this.profileImage,
    this.address,
    this.tazkiraImage,
    this.phones = const [], // ✅ مقدار پیش‌فرض
    this.wholesaleCodes = const [], // ✅ مقدار پیش‌فرض
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'customer_code': customerCode,
      'type': type,
      'shop_id': shopId,
      'created_by': createdBy,
      'address': address,
      'profile_image': profileImage,
      'tazkira_image': tazkiraImage,
      'phones': phones.isNotEmpty ? jsonEncode(phones) : '[]',
      'wholesale_codes': wholesaleCodes.isNotEmpty ? jsonEncode(wholesaleCodes) : '[]',
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    // پارس کردن phones
    List<String> phonesList = [];
    try {
      if (map['phones'] != null && (map['phones'] as String).isNotEmpty) {
        final parsed = jsonDecode(map['phones'] as String);
        if (parsed is List) {
          phonesList = List<String>.from(parsed);
        }
      }
    } catch (e) {
      phonesList = [];
    }

    // پارس کردن wholesale_codes
    List<Map<String, String>> wholesaleList = [];
    try {
      if (map['wholesale_codes'] != null && (map['wholesale_codes'] as String).isNotEmpty) {
        final parsed = jsonDecode(map['wholesale_codes'] as String);
        if (parsed is List) {
          wholesaleList = List<Map<String, String>>.from(
              parsed.map((item) => Map<String, String>.from(item))
          );
        }
      }
    } catch (e) {
      wholesaleList = [];
    }

    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      customerCode: map['customer_code'] as String,
      type: map['type'] as String,
      shopId: map['shop_id'] as String,
      createdBy: map['created_by'] as String,
      profileImage: map['profile_image'] as String?,
      address: map['address'] as String?,
      tazkiraImage: map['tazkira_image'] as String?,
      phones: phonesList,
      wholesaleCodes: wholesaleList,
    );
  }
}