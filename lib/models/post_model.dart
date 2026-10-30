// Peer Forum Post Model

class ForumPost {
  final String id;
  final String studentId; // Hidden internally for admin actions
  final String studentPseudonym; // Displayed on the public UI
  final String title;
  final String content;
  final String status; // 'pending' | 'approved' | 'removed'
  final DateTime createdAt;

  ForumPost({
    required this.id,
    required this.studentId,
    required this.studentPseudonym,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentPseudonym': studentPseudonym,
      'title': title,
      'content': content,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ForumPost.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    DateTime createdAt;
    if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return ForumPost(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentPseudonym: map['studentPseudonym'] ?? 'Anonymous Student',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: createdAt,
    );
  }
}
