// User Model representing Student, Counsellor, and Admin

class AppUser {
  final String uid;
  final String name;
  final String username;
  final String role; // 'student' | 'counsellor' | 'admin'
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    // Handle createdAt stored as int (ms epoch from seed script)
    // or as String (ISO 8601 from older createUser calls)
    DateTime createdAt;
    final raw = map['createdAt'];
    if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? 'student',
      createdAt: createdAt,
    );
  }
}
