class CurrencyModel {
  final String id;
  final String code;
  final String name;
  final String? nameAr;
  final String? symbol;
  final double exchangeRate;
  final bool isDefault;
  final String? createdAt;

  CurrencyModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
    this.symbol,
    this.exchangeRate = 1,
    this.isDefault = false,
    this.createdAt,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'] ?? json['nameAr'],
      symbol: json['symbol'],
      exchangeRate: _parseDouble(json['exchange_rate'] ?? json['exchangeRate']),
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 1;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 1;
    return 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      if (nameAr != null) 'name_ar': nameAr,
      if (symbol != null) 'symbol': symbol,
      'exchange_rate': exchangeRate,
      'is_default': isDefault,
    };
  }
}
