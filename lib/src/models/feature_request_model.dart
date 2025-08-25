import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';

class FeatureRequest {
  final int id;
  final DateTime createdAt;
  final String userId;
  final int productId;
  final int? paymentMethodId;
  final String transactionRef;
  final String status;
  final Profile? user;
  final Product? product;

  FeatureRequest({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.productId,
    this.paymentMethodId,
    required this.transactionRef,
    required this.status,
    this.user,
    this.product,
  });

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    return FeatureRequest(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
      productId: json['product_id'],
      paymentMethodId: json['payment_method_id'],
      transactionRef: json['transaction_ref'],
      status: json['status'],
      user: json['profiles'] == null ? null : Profile.fromJson(json['profiles']),
      product: json['products'] == null ? null : Product.fromJson(json['products']),
    );
  }
}
