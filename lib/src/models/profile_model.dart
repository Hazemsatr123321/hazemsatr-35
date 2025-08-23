class Profile {
  final String id;
  final String? username;
  final DateTime? updatedAt;

  // B2B Fields
  final String? business_type; // 'wholesaler' or 'retailer'
  final String? verification_status; // 'pending', 'approved', 'rejected'
  final String? business_name;
  final String? business_address;
  final String? role;

  Profile({
    required this.id,
    this.username,
    this.updatedAt,
    this.business_type,
    this.verification_status,
    this.business_name,
    this.business_address,
    this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      business_type: json['business_type'] as String?,
      verification_status: json['verification_status'] as String?,
      business_name: json['business_name'] as String?,
      business_address: json['business_address'] as String?,
      role: json['role'] as String?,
    );
  }
}
