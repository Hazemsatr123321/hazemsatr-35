class Product {
  final String id;
  final String title;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
    );
  }
}
