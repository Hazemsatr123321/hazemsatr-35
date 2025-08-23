class ProductRequest {
  final String id;
  final String retailerId;
  final String requestedProductName;
  final String? description;
  final String? quantityNeeded;
  final String? unitType;
  final bool isActive;
  final DateTime createdAt;

  ProductRequest({
    required this.id,
    required this.retailerId,
    required this.requestedProductName,
    this.description,
    this.quantityNeeded,
    this.unitType,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductRequest.fromJson(Map<String, dynamic> json) {
    return ProductRequest(
      id: json['id'] as String,
      retailerId: json['retailer_id'] as String,
      requestedProductName: json['requested_product_name'] as String,
      description: json['description'] as String?,
      quantityNeeded: json['quantity_needed'] as String?,
      unitType: json['unit_type'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
