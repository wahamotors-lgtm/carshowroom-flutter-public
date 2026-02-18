class ShipmentModel {
  final String id;
  final String? shipmentNumber;
  final String? containerId;
  final String? customerId;
  final String status;
  final String? origin;
  final String? destination;
  final String? shippingDate;
  final String? deliveryDate;
  final double totalCost;
  final String? notes;
  final String? createdAt;

  ShipmentModel({
    required this.id,
    this.shipmentNumber,
    this.containerId,
    this.customerId,
    this.status = 'pending',
    this.origin,
    this.destination,
    this.shippingDate,
    this.deliveryDate,
    this.totalCost = 0,
    this.notes,
    this.createdAt,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      shipmentNumber: json['shipment_number'] ?? json['shipmentNumber'],
      containerId: json['container_id']?.toString() ?? json['containerId']?.toString(),
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString(),
      status: json['status'] ?? 'pending',
      origin: json['origin'],
      destination: json['destination'],
      shippingDate: json['shipping_date'] ?? json['shippingDate'],
      deliveryDate: json['delivery_date'] ?? json['deliveryDate'],
      totalCost: _parseDouble(json['total_cost'] ?? json['totalCost']),
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
      if (shipmentNumber != null) 'shipment_number': shipmentNumber,
      if (containerId != null) 'container_id': containerId,
      if (customerId != null) 'customer_id': customerId,
      'status': status,
      if (origin != null) 'origin': origin,
      if (destination != null) 'destination': destination,
      if (shippingDate != null) 'shipping_date': shippingDate,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      'total_cost': totalCost,
      if (notes != null) 'notes': notes,
    };
  }
}
