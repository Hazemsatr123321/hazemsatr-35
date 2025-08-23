import 'package:smart_iraq/src/models/order_item_model.dart';

class Order {
  final String id;
  final String retailerId;
  final String wholesalerId;
  final String status;
  final num totalAmount;
  final String? shippingAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem>? items; // Optional: To hold related items

  Order({
    required this.id,
    required this.retailerId,
    required this.wholesalerId,
    required this.status,
    required this.totalAmount,
    this.shippingAddress,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      retailerId: json['retailer_id'] as String,
      wholesalerId: json['wholesaler_id'] as String,
      status: json['status'] as String,
      totalAmount: json['total_amount'] as num,
      shippingAddress: json['shipping_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      items: json['order_items'] == null
          ? null
          : (json['order_items'] as List)
              .map((itemJson) => OrderItem.fromJson(itemJson))
              .toList(),
    );
  }
}
