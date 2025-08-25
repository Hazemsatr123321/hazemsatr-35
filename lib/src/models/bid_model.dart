class Bid {
  final String id;
  final String bidderId;
  final num amount;
  final DateTime createdAt;

  Bid({required this.id, required this.bidderId, required this.amount, required this.createdAt});

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'].toString(),
      bidderId: json['user_id'], // Corrected from bidder_id to user_id to match common schema
      amount: json['amount'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
