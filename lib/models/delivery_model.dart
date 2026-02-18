class DeliveryModel {
  final String id;
  final String? shipmentId;
  final String? carId;
  final String? deliveryDate;
  final String status;
  final String? recipientName;
  final String? recipientPhone;
  final String? notes;
  final String? createdAt;

  DeliveryModel({
    required this.id,
    this.shipmentId,
    this.carId,
    this.deliveryDate,
    this.status = 'pending',
    this.recipientName,
    this.recipientPhone,
    this.notes,
    this.createdAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? json['shipmentId']?.toString(),
      carId: json['car_id']?.toString() ?? json['carId']?.toString(),
      deliveryDate: json['delivery_date'] ?? json['deliveryDate'],
      status: json['status'] ?? 'pending',
      recipientName: json['recipient_name'] ?? json['recipientName'],
      recipientPhone: json['recipient_phone'] ?? json['recipientPhone'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (shipmentId != null) 'shipment_id': shipmentId,
      if (carId != null) 'car_id': carId,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      'status': status,
      if (recipientName != null) 'recipient_name': recipientName,
      if (recipientPhone != null) 'recipient_phone': recipientPhone,
      if (notes != null) 'notes': notes,
    };
  }
}
