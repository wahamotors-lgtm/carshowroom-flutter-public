class TenantModel {
  final String id;
  final String companyName;
  final String ownerName;
  final String email;
  final String? phone;
  final bool isActive;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;

  TenantModel({
    required this.id,
    required this.companyName,
    required this.ownerName,
    required this.email,
    this.phone,
    this.isActive = false,
    this.subscriptionStatus,
    this.subscriptionEndDate,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['_id'] ?? json['id'] ?? '',
      companyName: json['companyName'] ?? '',
      ownerName: json['ownerName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['isActive'] ?? false,
      subscriptionStatus: json['subscriptionStatus'],
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.tryParse(json['subscriptionEndDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'ownerName': ownerName,
      'email': email,
      if (phone != null) 'phone': phone,
      'isActive': isActive,
      if (subscriptionStatus != null) 'subscriptionStatus': subscriptionStatus,
      if (subscriptionEndDate != null)
        'subscriptionEndDate': subscriptionEndDate!.toIso8601String(),
    };
  }
}
