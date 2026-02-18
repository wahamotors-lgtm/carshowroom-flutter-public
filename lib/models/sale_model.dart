class SaleModel {
  final String id;
  final String? carId;
  final String? customerId;
  final String? customerName;
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String saleDate;
  final double salePrice;
  final String currency;
  final String? paymentMethod;
  final String status;
  final String? notes;
  final String? createdAt;

  SaleModel({
    required this.id,
    this.carId,
    this.customerId,
    this.customerName,
    this.carMake,
    this.carModel,
    this.carYear,
    this.saleDate = '',
    this.salePrice = 0,
    this.currency = 'USD',
    this.paymentMethod,
    this.status = 'completed',
    this.notes,
    this.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      carId: json['car_id']?.toString() ?? json['carId']?.toString(),
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      customerName: json['customer_name'] ?? json['customerName'],
      carMake: json['make'] ?? json['car_make'] ?? json['carMake'],
      carModel: json['model'] ?? json['car_model'] ?? json['carModel'],
      carYear: json['year']?.toString() ?? json['car_year']?.toString(),
      saleDate: json['sale_date'] ?? json['saleDate'] ?? '',
      salePrice: _parseDouble(json['sale_price'] ?? json['salePrice']),
      currency: json['currency'] ?? 'USD',
      paymentMethod: json['payment_method'] ?? json['paymentMethod'],
      status: json['status'] ?? 'completed',
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
      'sale_date': saleDate,
      'sale_price': salePrice,
      'currency': currency,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }
}
