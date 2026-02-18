class RentalModel {
  final String id;
  final String? carId;
  final String? customerId;
  final String? name;
  final String? startDate;
  final String? endDate;
  final double dailyRate;
  final double totalAmount;
  final double amount;
  final String? currency;
  final String status;
  final String? dueDate;
  final String? notes;
  final String? createdAt;

  RentalModel({
    required this.id,
    this.carId,
    this.customerId,
    this.name,
    this.startDate,
    this.endDate,
    this.dailyRate = 0,
    this.totalAmount = 0,
    this.amount = 0,
    this.currency,
    this.status = 'active',
    this.dueDate,
    this.notes,
    this.createdAt,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      carId: json['car_id']?.toString() ?? json['carId']?.toString(),
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      name: json['name'],
      startDate: json['start_date'] ?? json['startDate'],
      endDate: json['end_date'] ?? json['endDate'],
      dailyRate: _parseDouble(json['daily_rate'] ?? json['dailyRate']),
      totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']),
      amount: _parseDouble(json['amount']),
      currency: json['currency'],
      status: json['status'] ?? 'active',
      dueDate: json['due_date'] ?? json['dueDate'],
      notes: json['notes'],
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
      if (carId != null) 'car_id': carId,
      if (customerId != null) 'customer_id': customerId,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'daily_rate': dailyRate,
      'total_amount': totalAmount,
      if (amount > 0) 'amount': amount,
      if (currency != null) 'currency': currency,
      'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (notes != null) 'notes': notes,
    };
  }
}
