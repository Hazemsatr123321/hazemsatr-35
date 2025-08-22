class Profile {
  final String id;
  final String? username;
  final String? referralCode;
  final int referralCount;
  final DateTime? updatedAt;
  final String? role;

  Profile({
    required this.id,
    this.username,
    this.referralCode,
    required this.referralCount,
    this.updatedAt,
    this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      referralCode: json['referral_code'] as String?,
      referralCount: json['referral_count'] as int? ?? 0,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      role: json['role'] as String?,
    );
  }
}
