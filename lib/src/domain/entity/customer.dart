// مدل مشتری
class Customer {
  final int? id;
  final String name;
  final String code;
  final String type; // ORDINARY or WHOLESALE
  final List<String>? phones;
  final List<Map<String, String>>? wholesaleCodes;

  Customer({this.id, required this.name, required this.code, required this.type, this.phones, this.wholesaleCodes});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'customer_code': code, 'type': type};
  }
}

// مدل شرکت تامین کننده
class ProviderCompany {
  final int? id;
  final String name;
  final String type;
  final String ordinaryCode;
  final String wholesaleCode;

  ProviderCompany({this.id, required this.name, required this.type, required this.ordinaryCode, required this.wholesaleCode});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': type, 'ordinary_code': ordinaryCode, 'wholesale_code': wholesaleCode};
  }
}