class EmployeeModel {
  final String id;
  final String name;
  final String code;
  final String? email;
  final String? role;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.code,
    this.email,
    this.role,
    this.isActive = true,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? json['employeeCode'] ?? '',
      email: json['email'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      'isActive': isActive,
    };
  }
}
