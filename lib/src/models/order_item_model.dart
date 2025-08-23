class OrderItem {
  final int id;
  final String orderId;
  final String productId;
  final int quantity;
  final num pricePerUnit;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.pricePerUnit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      pricePerUnit: json['price_per_unit'] as num,
    );
  }
}
