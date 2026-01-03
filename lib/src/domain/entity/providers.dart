class ProviderCompany {
  final int? id;
  final String name;
  final String type; // ملاک تطابق (مثلاً: Roshan, MTN, Etisalat)
  final String ordinaryCode;
  final String wholesaleCode;

  ProviderCompany({this.id, required this.name, required this.type, required this.ordinaryCode, required this.wholesaleCode});

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'type': type, 'ordinary_code': ordinaryCode, 'wholesale_code': wholesaleCode,
  };
}