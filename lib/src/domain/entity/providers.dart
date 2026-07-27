class ProviderCompany {
  final int? id;
  final String shopId;
  final String name;
  final double balance;
  final String? logoPath;

  ProviderCompany({
    this.id,
    required this.shopId,
    required this.name,
    this.balance = 0.0,
    this.logoPath,
  });

  ProviderCompany copyWith({
    int? id,
    String? shopId,
    String? name,
    double? balance,
    String? logoPath,
  }) {
    return ProviderCompany(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  factory ProviderCompany.fromMap(Map<String, dynamic> map) {
    return ProviderCompany(
      id: map['id'] as int?,
      shopId: map['shop_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      balance: (map['balance'] as num? ?? 0.0).toDouble(),
      logoPath: map['logo_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'balance': balance,
      'logo_path': logoPath,
    };
  }
}
