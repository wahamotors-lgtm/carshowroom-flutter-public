class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final String? category;
  final String? expenseDate;
  final String? carId;
  final String? containerId;
  final String? shipmentId;
  final String? accountId;
  final String? debitAccountId;
  final String? creditAccountId;
  final String? notes;
  final String? createdAt;

  ExpenseModel({
    required this.id,
    this.description = '',
    this.amount = 0,
    this.currency = 'USD',
    this.category,
    this.expenseDate,
    this.carId,
    this.containerId,
    this.shipmentId,
    this.accountId,
    this.debitAccountId,
    this.creditAccountId,
    this.notes,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      description: json['description'] ?? '',
      amount: _parseDouble(json['amount']),
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      expenseDate: json['expense_date'] ?? json['expenseDate'],
      carId: json['car_id']?.toString() ?? json['carId']?.toString(),
      containerId: json['container_id']?.toString() ?? json['containerId']?.toString(),
      shipmentId: json['shipment_id']?.toString() ?? json['shipmentId']?.toString(),
      accountId: json['account_id']?.toString() ?? json['accountId']?.toString(),
      debitAccountId: json['debit_account_id']?.toString() ?? json['debitAccountId']?.toString(),
      creditAccountId: json['credit_account_id']?.toString() ?? json['creditAccountId']?.toString(),
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
      'description': description,
      'amount': amount,
      'currency': currency,
      if (category != null) 'category': category,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (carId != null) 'car_id': carId,
      if (containerId != null) 'container_id': containerId,
      if (shipmentId != null) 'shipment_id': shipmentId,
      if (accountId != null) 'account_id': accountId,
      if (debitAccountId != null) 'debit_account_id': debitAccountId,
      if (creditAccountId != null) 'credit_account_id': creditAccountId,
      if (notes != null) 'notes': notes,
    };
  }
}
