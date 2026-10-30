import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/post_model.dart';
import '../models/resource_model.dart';
import '../models/assessment_model.dart';
import '../models/chatbot_session_model.dart';
import 'database_service.dart';

class FirebaseDatabaseService implements DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<AppUser>> getCounsellors() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'counsellor')
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      final rawUid = data['uid'];
      final effectiveUid = (rawUid is String && rawUid.isNotEmpty) ? rawUid : doc.id;
      return AppUser.fromMap({...data, 'uid': effectiveUid});
    }).toList();
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      final rawUid = data['uid'];
      final effectiveUid = (rawUid is String && rawUid.isNotEmpty) ? rawUid : doc.id;
      return AppUser.fromMap({...data, 'uid': effectiveUid});
    }).toList();
  }

  @override
  Future<List<Appointment>> getAppointments(String userId, String role) async {
    Query query = _db.collection('appointments');
    if (role == 'counsellor') {
      query = query.where('counsellorId', isEqualTo: userId);
    } else if (role == 'student') {
      query = query.where('studentId', isEqualTo: userId);
    }
    
    final snap = await query.get();
    final results = snap.docs
        .map((doc) => Appointment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    // Sort in Dart to avoid needing a Firestore composite index
    results.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return results;
  }

  @override
  Future<void> bookAppointment(Appointment appointment) async {
    await _db
        .collection('appointments')
        .doc(appointment.id)
        .set(appointment.toMap());
  }

  @override
  Future<void> updateAppointmentStatus(
    String id, 
    String status, {
    String? scheduledDateTime, 
    String? sessionNotes,
  }) async {
    final Map<String, dynamic> data = {'status': status};
    if (scheduledDateTime != null) data['scheduledDateTime'] = scheduledDateTime;
    if (sessionNotes != null) data['sessionNotes'] = sessionNotes;
    
    await _db.collection('appointments').doc(id).update(data);
  }

  @override
  Future<List<ForumPost>> getApprovedForumPosts() async {
    final snap = await _db
        .collection('forum_posts')
        .where('status', isEqualTo: 'approved')
        .get();
    final results = snap.docs.map((doc) => ForumPost.fromMap(doc.data())).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<List<ForumPost>> getPendingForumPosts() async {
    final snap = await _db
        .collection('forum_posts')
        .where('status', isEqualTo: 'pending')
        .get();
    final results = snap.docs.map((doc) => ForumPost.fromMap(doc.data())).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<List<ForumPost>> getAllForumPosts() async {
    final snap = await _db.collection('forum_posts').get();
    final results = snap.docs.map((doc) => ForumPost.fromMap(doc.data())).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<void> createForumPost(ForumPost post) async {
    await _db.collection('forum_posts').doc(post.id).set(post.toMap());
  }

  @override
  Future<void> approveForumPost(String postId) async {
    await _db.collection('forum_posts').doc(postId).update({'status': 'approved'});
  }

  @override
  Future<void> removeForumPost(String postId) async {
    await _db.collection('forum_posts').doc(postId).delete();
  }

  @override
  Future<void> warnUser(String studentId, String warningText) async {
    await _db.collection('users').doc(studentId).update({
      'warnings': FieldValue.arrayUnion([warningText])
    });
  }

  @override
  Future<List<String>> getUserWarnings(String studentId) async {
    final doc = await _db.collection('users').doc(studentId).get();
    if (doc.exists && doc.data() != null) {
      final warnings = doc.data()!['warnings'];
      if (warnings != null) {
        return List<String>.from(warnings);
      }
    }
    return [];
  }

  @override
  Future<List<Resource>> getResources() async {
    final snap = await _db
        .collection('resources')
        .get();
    final results = snap.docs.map((doc) => Resource.fromMap(doc.data())).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<void> createResource(Resource resource) async {
    await _db.collection('resources').doc(resource.id).set(resource.toMap());
  }

  @override
  Future<void> updateResource(Resource resource) async {
    await _db.collection('resources').doc(resource.id).set(resource.toMap());
  }

  @override
  Future<void> deleteResource(String id) async {
    await _db.collection('resources').doc(id).delete();
  }

  @override
  Future<List<ChatbotSession>> getChatbotSessions() async {
    final snap = await _db
        .collection('chatbot_sessions')
        .get();
    final results = snap.docs.map((doc) => ChatbotSession.fromMap(doc.data())).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<void> logChatbotSession(ChatbotSession session) async {
    await _db
        .collection('chatbot_sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  @override
  Future<List<AssessmentReport>> getAssessmentReports() async {
    final snap = await _db
        .collection('assessments')
        .get();
    final results = snap.docs.map((doc) => AssessmentReport.fromMap(doc.data())).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<void> submitAssessmentReport(AssessmentReport report) async {
    await _db.collection('assessments').doc(report.id).set(report.toMap());
  }
}
