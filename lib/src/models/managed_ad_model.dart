class ManagedAd {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;

  ManagedAd({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.isActive,
  });

  factory ManagedAd.fromJson(Map<String, dynamic> json) {
    return ManagedAd(
      id: json['id'].toString(),
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      targetUrl: json['target_url'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'is_active': isActive,
    };
  }
}
