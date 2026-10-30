// Mental Health Assessment Model

class AssessmentReport {
  final String id;
  final String studentId;
  final String studentPseudonym; // Used for analytics anonymization
  final String type; // 'PHQ-9' | 'GAD-7' | 'GHQ-12'
  final int score;
  final String severity; // 'Minimal' | 'Mild' | 'Moderate' | 'Severe'
  final Map<String, int> answers; // Question key -> Answer index
  final DateTime createdAt;

  AssessmentReport({
    required this.id,
    required this.studentId,
    required this.studentPseudonym,
    required this.type,
    required this.score,
    required this.severity,
    required this.answers,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentPseudonym': studentPseudonym,
      'type': type,
      'score': score,
      'severity': severity,
      'answers': answers,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AssessmentReport.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    DateTime createdAt;
    if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return AssessmentReport(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentPseudonym: map['studentPseudonym'] ?? 'Anonymous Student',
      type: map['type'] ?? '',
      score: map['score'] ?? 0,
      severity: map['severity'] ?? 'Minimal',
      answers: Map<String, int>.from(map['answers'] ?? {}),
      createdAt: createdAt,
    );
  }
}
