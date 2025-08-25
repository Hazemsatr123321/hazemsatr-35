class Notification {
  final int id;
  final DateTime createdAt;
  final String recipientId;
  final String title;
  final String? body;
  final bool isRead;
  final String type;
  final String referenceId;

  Notification({
    required this.id,
    required this.createdAt,
    required this.recipientId,
    required this.title,
    this.body,
    required this.isRead,
    required this.type,
    required this.referenceId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      recipientId: json['recipient_id'],
      title: json['title'],
      body: json['body'],
      isRead: json['is_read'],
      type: json['type'],
      referenceId: json['reference_id'],
    );
  }

  Notification copyWith({bool? isRead}) {
    return Notification(
      id: id,
      createdAt: createdAt,
      recipientId: recipientId,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      type: type,
      referenceId: referenceId,
    );
  }
}
