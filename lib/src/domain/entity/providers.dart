class ProviderCompany {
  final int? id;
  final String name;
  final String type; // مثلا Roshan
  final String ordinaryCode;
  final String wholesaleCode;

  ProviderCompany({this.id, required this.name, required this.type, required this.ordinaryCode, required this.wholesaleCode});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'ordinary_code': ordinaryCode,
      'wholesale_code': wholesaleCode,
    };
  }
}