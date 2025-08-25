class Rfq {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String title;
  final String? productDescription;
  final String? quantity;
  final String status;

  Rfq({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.title,
    this.productDescription,
    this.quantity,
    required this.status,
  });

  factory Rfq.fromJson(Map<String, dynamic> json) {
    return Rfq(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
      title: json['title'],
      productDescription: json['product_description'],
      quantity: json['quantity'],
      status: json['status'],
    );
  }
}
