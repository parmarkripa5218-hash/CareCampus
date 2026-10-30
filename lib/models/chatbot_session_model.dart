// AI Chatbot Session Model for Analytics Reports

class ChatbotSession {
  final String id;
  final String studentId;
  final String studentPseudonym;
  final String concern; // e.g. "Academic Stress", "Anxiety", "Depression"
  final String severity; // 'Low' | 'Moderate' | 'Severe'
  final DateTime createdAt;

  ChatbotSession({
    required this.id,
    required this.studentId,
    required this.studentPseudonym,
    required this.concern,
    required this.severity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentPseudonym': studentPseudonym,
      'concern': concern,
      'severity': severity,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ChatbotSession.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    DateTime createdAt;
    if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return ChatbotSession(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentPseudonym: map['studentPseudonym'] ?? 'Anonymous Student',
      concern: map['concern'] ?? 'General',
      severity: map['severity'] ?? 'Low',
      createdAt: createdAt,
    );
  }
}
