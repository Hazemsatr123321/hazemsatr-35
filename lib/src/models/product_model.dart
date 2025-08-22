class Product {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String? description;
  final String userId;
  final String? category;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.description,
    required this.userId,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      description: json['description'] as String?,
      userId: json['user_id'] as String,
      category: json['category'] as String?,
    );
  }
}
