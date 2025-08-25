class Profile {
  final String id;
  final DateTime? updatedAt;
  final String? username;

  // B2B Fields
  final String? business_name;
  final String? business_type; // 'wholesaler' or 'shop_owner'

  // Auth/Admin Fields
  final String? role;
  final bool? is_banned;

  // Reputation Fields
  final double? reputation_score;
  final String? seller_tier;

  Profile({
    required this.id,
    this.updatedAt,
    this.username,
    this.business_name,
    this.business_type,
    this.role,
    this.is_banned,
    this.reputation_score,
    this.seller_tier,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at']),
      username: json['username'],
      business_name: json['business_name'],
      business_type: json['business_type'],
      role: json['role'],
      is_banned: json['is_banned'],
      reputation_score: (json['reputation_score'] as num?)?.toDouble(),
      seller_tier: json['seller_tier'],
    );
  }
}
