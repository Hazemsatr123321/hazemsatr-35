import 'package:smart_iraq/src/models/profile_model.dart';

class Review {
  final int id;
  final DateTime createdAt;
  final int? productId;
  final String buyerId;
  final String sellerId;
  final int rating;
  final String? comment;
  final Profile? buyer; // Joined data

  Review({
    required this.id,
    required this.createdAt,
    this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.rating,
    this.comment,
    this.buyer,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      productId: json['product_id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      rating: json['rating'],
      comment: json['comment'],
      // The 'buyer' profile is nested in the JSON response from the query in SellerProfileScreen
      buyer: json.containsKey('buyer') && json['buyer'] != null ? Profile.fromJson(json['buyer']) : null,
    );
  }
}
