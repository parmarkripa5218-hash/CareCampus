// Appointment Model for Counselling Bookings

class Appointment {
  final String id;
  final String studentId;
  final String studentPseudonym; // Used for anonymity
  final String counsellorId;
  final String counsellorName;
  final String status; // 'pending' | 'accepted' | 'rejected' | 'completed'
  final DateTime bookingDate;
  final String? scheduledDateTime; // Selected by counsellor on approval
  final String? sessionNotes; // Notes from the counsellor after session completion
  final bool isAnonymous; // True if booked through severe chatbot/assessment flags
  final String? anonymousAlertReason; // e.g. "Severe depression (PHQ-9: 21)" or "AI Chatbot critical flag"

  Appointment({
    required this.id,
    required this.studentId,
    required this.studentPseudonym,
    required this.counsellorId,
    required this.counsellorName,
    required this.status,
    required this.bookingDate,
    this.scheduledDateTime,
    this.sessionNotes,
    required this.isAnonymous,
    this.anonymousAlertReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentPseudonym': studentPseudonym,
      'counsellorId': counsellorId,
      'counsellorName': counsellorName,
      'status': status,
      'bookingDate': bookingDate.millisecondsSinceEpoch,
      'scheduledDateTime': scheduledDateTime,
      'sessionNotes': sessionNotes,
      'isAnonymous': isAnonymous,
      'anonymousAlertReason': anonymousAlertReason,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    final raw = map['bookingDate'];
    DateTime bookingDate;
    if (raw is int) {
      bookingDate = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      bookingDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      bookingDate = DateTime.now();
    }
    return Appointment(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentPseudonym: map['studentPseudonym'] ?? 'Anonymous Student',
      counsellorId: map['counsellorId'] ?? '',
      counsellorName: map['counsellorName'] ?? '',
      status: map['status'] ?? 'pending',
      bookingDate: bookingDate,
      scheduledDateTime: map['scheduledDateTime'],
      sessionNotes: map['sessionNotes'],
      isAnonymous: map['isAnonymous'] ?? false,
      anonymousAlertReason: map['anonymousAlertReason'],
    );
  }
  
  Appointment copyWith({
    String? status,
    String? scheduledDateTime,
    String? sessionNotes,
  }) {
    return Appointment(
      id: id,
      studentId: studentId,
      studentPseudonym: studentPseudonym,
      counsellorId: counsellorId,
      counsellorName: counsellorName,
      status: status ?? this.status,
      bookingDate: bookingDate,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      isAnonymous: isAnonymous,
      anonymousAlertReason: anonymousAlertReason,
    );
  }
}
