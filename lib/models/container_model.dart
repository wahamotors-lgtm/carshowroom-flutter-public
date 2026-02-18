class ContainerModel {
  final String id;
  final String? containerNumber;
  final String? shippingLine;
  final String? originPort;
  final String? destinationPort;
  final String? departureDate;
  final String? arrivalDate;
  final String status;
  final double totalCost;
  final String? notes;
  final String? createdAt;

  ContainerModel({
    required this.id,
    this.containerNumber,
    this.shippingLine,
    this.originPort,
    this.destinationPort,
    this.departureDate,
    this.arrivalDate,
    this.status = 'pending',
    this.totalCost = 0,
    this.notes,
    this.createdAt,
  });

  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      containerNumber: json['container_number'] ?? json['containerNumber'],
      shippingLine: json['shipping_line'] ?? json['shippingLine'],
      originPort: json['origin_port'] ?? json['originPort'],
      destinationPort: json['destination_port'] ?? json['destinationPort'],
      departureDate: json['departure_date'] ?? json['departureDate'],
      arrivalDate: json['arrival_date'] ?? json['arrivalDate'],
      status: json['status'] ?? 'pending',
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
      if (containerNumber != null) 'container_number': containerNumber,
      if (shippingLine != null) 'shipping_line': shippingLine,
      if (originPort != null) 'origin_port': originPort,
      if (destinationPort != null) 'destination_port': destinationPort,
      if (departureDate != null) 'departure_date': departureDate,
      if (arrivalDate != null) 'arrival_date': arrivalDate,
      'status': status,
      'total_cost': totalCost,
      if (notes != null) 'notes': notes,
    };
  }
}
