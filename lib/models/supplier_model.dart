class SupplierModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? email;
  final String? phone;
  final String? address;
  final String? country;
  final double balance;
  final String? notes;
  final bool isActive;
  final String? createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.email,
    this.phone,
    this.address,
    this.country,
    this.balance = 0,
    this.notes,
    this.isActive = true,
    this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'] ?? json['nameAr'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      country: json['country'],
      balance: _parseDouble(json['balance']),
      notes: json['notes'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
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
      if (nameAr != null) 'name_ar': nameAr,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (country != null) 'country': country,
      if (notes != null) 'notes': notes,
    };
  }
}
