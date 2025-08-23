class CharityCampaign {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final num? goalAmount;
  final num currentAmount;
  final bool isActive;

  CharityCampaign({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.goalAmount,
    required this.currentAmount,
    required this.isActive,
  });

  factory CharityCampaign.fromJson(Map<String, dynamic> json) {
    return CharityCampaign(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      goalAmount: json['goal_amount'],
      currentAmount: json['current_amount'] ?? 0,
      isActive: json['is_active'],
    );
  }
}
