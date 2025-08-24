class Review {
  final int id;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  // Optionally, join the reviewer's profile info
  final String? reviewerUsername;

  Review({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerUsername,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String? tempUsername;
    if (json.containsKey('profiles') && json['profiles'] != null) {
      tempUsername = json['profiles']['business_name'] ?? json['profiles']['username'];
    }

    return Review(
      id: json['id'] as int,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerUsername: tempUsername,
    );
  }
}
