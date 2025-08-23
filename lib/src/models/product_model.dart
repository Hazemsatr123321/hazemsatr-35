class Product {
  final String id;
  final String name;
  final String? description;
  final num price;
  final String? imageUrl;
  final String userId;
  final String? category;

  // B2B Fields
  final int? minimum_order_quantity;
  final int? stock_quantity;
  final String? unit_type;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.userId,
    this.category,
    this.minimum_order_quantity,
    this.stock_quantity,
    this.unit_type,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as num,
      imageUrl: json['image_url'] as String?,
      userId: json['user_id'] as String,
      category: json['category'] as String?,
      minimum_order_quantity: json['minimum_order_quantity'] as int?,
      stock_quantity: json['stock_quantity'] as int?,
      unit_type: json['unit_type'] as String?,
    );
  }
}
