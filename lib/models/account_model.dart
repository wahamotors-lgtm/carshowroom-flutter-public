class AccountModel {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String? currency;
  final String? parentId;
  final bool isSystemAccount;
  final String? createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0,
    this.currency,
    this.parentId,
    this.isSystemAccount = false,
    this.createdAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'other',
      balance: _parseDouble(json['balance']),
      currency: json['currency'],
      parentId: json['parent_id']?.toString() ?? json['parentId']?.toString(),
      isSystemAccount: json['is_system_account'] ?? json['isSystemAccount'] ?? false,
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      if (currency != null) 'currency': currency,
      if (parentId != null) 'parent_id': parentId,
    };
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? parentId,
    bool? isSystemAccount,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      parentId: parentId ?? this.parentId,
      isSystemAccount: isSystemAccount ?? this.isSystemAccount,
      createdAt: createdAt,
    );
  }
}

class AccountTypeModel {
  final String id;
  final String code;
  final String name;
  final String? nameAr;

  AccountTypeModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
  });

  factory AccountTypeModel.fromJson(Map<String, dynamic> json) {
    return AccountTypeModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'] ?? json['nameAr'],
    );
  }
}

/// Helper to get Arabic label for account type
String accountTypeLabel(String type) {
  const labels = {
    'cash_box': 'صندوق نقدي',
    'bank': 'بنك',
    'customer': 'عميل',
    'supplier': 'مورد',
    'revenue': 'إيراد',
    'expense': 'مصروف',
    'showroom': 'معرض',
    'customs': 'جمارك',
    'employee': 'موظف',
    'purchases': 'مشتريات',
    'capital': 'رأس مال',
    'shipping_company': 'شركة شحن',
    'other': 'أخرى',
  };
  return labels[type] ?? type;
}
