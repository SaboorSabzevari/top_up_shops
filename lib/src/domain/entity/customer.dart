class Customer {
  final int? id;
  final String name;
  final String customerCode;
  final String type; // 'ORDINARY' یا 'WHOLESALE'
  final String? profileImage;
  final String? address;
  final String? tazkiraImage;

  Customer({this.id, required this.name, required this.customerCode, required this.type, this.profileImage, this.address, this.tazkiraImage});
  Map<String, dynamic> toMap() {
    return {
      // 'id': id,  <-- این خط را کامنت کنید یا حذف کنید تا دیتابیس خودش ID را مدیریت کند
      'name': name,
      'customer_code': customerCode,
      'type': type,
      'address': address,
      'profile_image': profileImage,
      'tazkira_image': tazkiraImage,
    };
  }}