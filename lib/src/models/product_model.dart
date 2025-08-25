import 'package:smart_iraq/src/models/profile_model.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final num? price;
  final String? imageUrl;
  final String userId;
  final String? category;
  final String? condition; // new, used
  final Profile? seller;

  // B2B Fields
  final int? minimum_order_quantity;
  final int? stock_quantity;
  final String? unit_type;

  // Donation Fields
  final bool is_available_for_donation;
  final String? donation_description;

  // Featured Field
  final bool is_featured;

  // Auction Fields
  final String listing_type;
  final num? start_price;
  final String? end_time;
  final num? highest_bid;


  Product({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.imageUrl,
    required this.userId,
    this.category,
    this.condition,
    this.seller,
    this.minimum_order_quantity,
    this.stock_quantity,
    this.unit_type,
    this.is_available_for_donation = false,
    this.donation_description,
    this.is_featured = false,
    this.listing_type = 'sale',
    this.start_price,
    this.end_time,
    this.highest_bid,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as num?,
      imageUrl: json['image_url'] as String?,
      userId: json['user_id'] as String,
      category: json['category'] as String?,
      condition: json['condition'] as String?,
      seller: json['profiles'] == null ? null : Profile.fromJson(json['profiles']),
      minimum_order_quantity: json['minimum_order_quantity'] as int?,
      stock_quantity: json['stock_quantity'] as int?,
      unit_type: json['unit_type'] as String?,
      is_available_for_donation: json['is_available_for_donation'] as bool? ?? false,
      donation_description: json['donation_description'] as String?,
      is_featured: json['is_featured'] as bool? ?? false,
      listing_type: json['listing_type'] as String? ?? 'sale',
      start_price: json['start_price'] as num?,
      end_time: json['end_time'] as String?,
      highest_bid: json['highest_bid'] as num?,
    );
  }
}
