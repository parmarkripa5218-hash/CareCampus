// Wellness Resource Model

class Resource {
  final String id;
  final String title;
  final String description;
  final String category; // 'Video' | 'Audio' | 'PDF' | 'Guide'
  final String url; // link to resource
  final String uploadedBy; // UID of admin or counsellor
  final String uploadedByName; // display name of admin or counsellor
  final DateTime createdAt;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.url,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'url': url,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    DateTime createdAt;
    if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return Resource(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Guide',
      url: map['url'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      createdAt: createdAt,
    );
  }
}
