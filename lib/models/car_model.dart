class CarModel {
  final String id;
  final String? stockNumber;
  final String? vin;
  final String? make;
  final String? model;
  final String? year;
  final String? color;
  final String? fuelType;
  final int mileage;
  final double purchasePrice;
  final double sellingPrice;
  final String purchaseCurrency;
  final String? purchaseDate;
  final String status;
  final String? containerId;
  final String? shipmentId;
  final String? warehouseId;
  final String? supplierId;
  final String? customerId;
  final String? notes;
  final List<String> images;
  final String? createdAt;

  CarModel({
    required this.id,
    this.stockNumber,
    this.vin,
    this.make,
    this.model,
    this.year,
    this.color,
    this.fuelType,
    this.mileage = 0,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.purchaseCurrency = 'USD',
    this.purchaseDate,
    this.status = 'in_stock',
    this.containerId,
    this.shipmentId,
    this.warehouseId,
    this.supplierId,
    this.customerId,
    this.notes,
    this.images = const [],
    this.createdAt,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      stockNumber: json['stock_number'] ?? json['stockNumber'],
      vin: json['vin'],
      make: json['make'],
      model: json['model'],
      year: json['year']?.toString(),
      color: json['color'],
      fuelType: json['fuel_type'] ?? json['fuelType'],
      mileage: _parseInt(json['mileage']),
      purchasePrice: _parseDouble(json['purchase_price'] ?? json['purchasePrice']),
      sellingPrice: _parseDouble(json['selling_price'] ?? json['sellingPrice']),
      purchaseCurrency: json['purchase_currency'] ?? json['purchaseCurrency'] ?? 'USD',
      purchaseDate: json['purchase_date'] ?? json['purchaseDate'],
      status: json['status'] ?? 'in_stock',
      containerId: json['container_id']?.toString() ?? json['containerId']?.toString(),
      shipmentId: json['shipment_id']?.toString() ?? json['shipmentId']?.toString(),
      warehouseId: json['warehouse_id']?.toString() ?? json['warehouseId']?.toString(),
      supplierId: json['supplier_id']?.toString() ?? json['supplierId']?.toString(),
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      notes: json['notes'],
      images: _parseImages(json['images']),
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      if (stockNumber != null) 'stock_number': stockNumber,
      if (vin != null) 'vin': vin,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (color != null) 'color': color,
      if (fuelType != null) 'fuel_type': fuelType,
      'mileage': mileage,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'purchase_currency': purchaseCurrency,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      'status': status,
      if (containerId != null) 'container_id': containerId,
      if (shipmentId != null) 'shipment_id': shipmentId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (customerId != null) 'customer_id': customerId,
      if (notes != null) 'notes': notes,
    };
  }

  CarModel copyWith({
    String? stockNumber,
    String? vin,
    String? make,
    String? model,
    String? year,
    String? color,
    String? fuelType,
    int? mileage,
    double? purchasePrice,
    double? sellingPrice,
    String? purchaseCurrency,
    String? purchaseDate,
    String? status,
    String? containerId,
    String? shipmentId,
    String? warehouseId,
    String? supplierId,
    String? customerId,
    String? notes,
    List<String>? images,
  }) {
    return CarModel(
      id: id,
      stockNumber: stockNumber ?? this.stockNumber,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
      containerId: containerId ?? this.containerId,
      shipmentId: shipmentId ?? this.shipmentId,
      warehouseId: warehouseId ?? this.warehouseId,
      supplierId: supplierId ?? this.supplierId,
      customerId: customerId ?? this.customerId,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      createdAt: createdAt,
    );
  }
}
