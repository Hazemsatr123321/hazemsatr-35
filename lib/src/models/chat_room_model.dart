class ChatRoom {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      participant1Id: json['participant1_id'] as String,
      participant2Id: json['participant2_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
