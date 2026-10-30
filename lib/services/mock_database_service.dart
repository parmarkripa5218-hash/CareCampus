import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/post_model.dart';
import '../models/resource_model.dart';
import '../models/assessment_model.dart';
import '../models/chatbot_session_model.dart';
import 'database_service.dart';

class MockDatabaseService implements DatabaseService {
  static final MockDatabaseService _instance = MockDatabaseService._internal();
  factory MockDatabaseService() => _instance;
  MockDatabaseService._internal();

  // Local lists
  final List<AppUser> _users = [];
  final Map<String, String> _passwords = {}; // username -> password
  final List<Appointment> _appointments = [];
  final List<ForumPost> _posts = [];
  final List<Resource> _resources = [];
  final List<ChatbotSession> _chatbotSessions = [];
  final List<AssessmentReport> _assessmentReports = [];
  final Map<String, List<String>> _warnings = {}; // studentId -> list of warning messages

  bool _isInitialized = false;

  /// Seed initial database data and load stored data from SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load or Seed Users
    final usersJson = prefs.getString('mock_users');
    final pwdJson = prefs.getString('mock_passwords');
    if (usersJson != null && pwdJson != null) {
      final List decodedUsers = jsonDecode(usersJson);
      _users.clear();
      _users.addAll(decodedUsers.map((e) => AppUser.fromMap(e)).toList());
      
      final Map<String, dynamic> decodedPwds = jsonDecode(pwdJson);
      _passwords.clear();
      decodedPwds.forEach((k, v) => _passwords[k] = v.toString());
    } else {
      // Seed default accounts
      _seedDefaultUsers();
      await _saveUsersState();
    }

    // 2. Load Appointments
    final apptsJson = prefs.getString('mock_appointments');
    if (apptsJson != null) {
      final List decoded = jsonDecode(apptsJson);
      _appointments.clear();
      _appointments.addAll(decoded.map((e) => Appointment.fromMap(e)).toList());
    } else {
      _seedDefaultAppointments();
      await _saveAppointmentsState();
    }

    // 3. Load Forum Posts
    final postsJson = prefs.getString('mock_posts');
    if (postsJson != null) {
      final List decoded = jsonDecode(postsJson);
      _posts.clear();
      _posts.addAll(decoded.map((e) => ForumPost.fromMap(e)).toList());
    } else {
      _seedDefaultPosts();
      await _savePostsState();
    }

    // 4. Load Resources
    final resJson = prefs.getString('mock_resources');
    if (resJson != null) {
      final List decoded = jsonDecode(resJson);
      _resources.clear();
      _resources.addAll(decoded.map((e) => Resource.fromMap(e)).toList());
    } else {
      _seedDefaultResources();
      await _saveResourcesState();
    }

    // 5. Load Chatbot Sessions
    final chatbotJson = prefs.getString('mock_chatbot_sessions');
    if (chatbotJson != null) {
      final List decoded = jsonDecode(chatbotJson);
      _chatbotSessions.clear();
      _chatbotSessions.addAll(decoded.map((e) => ChatbotSession.fromMap(e)).toList());
    } else {
      _seedDefaultChatbotSessions();
      await _saveChatbotSessionsState();
    }

    // 6. Load Assessments
    final assessmentsJson = prefs.getString('mock_assessments');
    if (assessmentsJson != null) {
      final List decoded = jsonDecode(assessmentsJson);
      _assessmentReports.clear();
      _assessmentReports.addAll(decoded.map((e) => AssessmentReport.fromMap(e)).toList());
    } else {
      _seedDefaultAssessments();
      await _saveAssessmentsState();
    }

    // 7. Load Warnings
    final warningsJson = prefs.getString('mock_warnings');
    if (warningsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(warningsJson);
      _warnings.clear();
      decoded.forEach((k, v) {
        _warnings[k] = List<String>.from(v);
      });
    }

    _isInitialized = true;
  }

  // --- Seed Functions ---

  void _seedDefaultUsers() {
    _users.clear();
    _passwords.clear();

    // Student
    _users.add(AppUser(
      uid: 'std-1',
      name: 'Jane Doe',
      username: 'student@carecampus.org',
      role: 'student',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ));
    _passwords['student@carecampus.org'] = 'StudentPassword@123';
    _passwords['student'] = 'StudentPassword@123'; // allow shortcut

    // Counsellor
    _users.add(AppUser(
      uid: 'cns-1',
      name: 'Dr. Sarah Jenkins',
      username: 'counsellor@carecampus.org',
      role: 'counsellor',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ));
    _passwords['counsellor@carecampus.org'] = 'CounsellorPassword@123';
    _passwords['counsellor'] = 'CounsellorPassword@123'; // allow shortcut

    // Admin
    _users.add(AppUser(
      uid: 'adm-1',
      name: 'Campus Admin',
      username: 'admin@carecampus.org',
      role: 'admin',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ));
    _passwords['admin@carecampus.org'] = 'AdminPassword@123';
    _passwords['admin'] = 'AdminPassword@123'; // allow shortcut
  }

  void _seedDefaultAppointments() {
    _appointments.clear();
    _appointments.add(Appointment(
      id: 'apt-1',
      studentId: 'std-1',
      studentPseudonym: 'Jane Doe',
      counsellorId: 'cns-1',
      counsellorName: 'Dr. Sarah Jenkins',
      status: 'completed',
      bookingDate: DateTime.now().subtract(const Duration(days: 5)),
      scheduledDateTime: '2026-07-10 10:00 AM',
      sessionNotes: 'Student discussed academic anxiety and stress regarding exams. Shared breathing techniques.',
      isAnonymous: false,
    ));
  }

  void _seedDefaultPosts() {
    _posts.clear();
    _posts.add(ForumPost(
      id: 'post-1',
      studentId: 'std-1',
      studentPseudonym: 'GentleSky-482',
      title: 'Managing academic stress',
      content: 'Hey guys, I have been feeling super overwhelmed by assignments lately. How do you all cope?',
      status: 'approved',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ));
    _posts.add(ForumPost(
      id: 'post-2',
      studentId: 'std-1',
      studentPseudonym: 'CalmMeadow-290',
      title: 'Lonely on campus',
      content: 'It feels like everyone has their group figured out except me. Just writing this to feel heard.',
      status: 'approved',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ));
  }

  void _seedDefaultResources() {
    _resources.clear();
    _resources.add(Resource(
      id: 'res-1',
      title: '5-Minute Guided Meditation',
      description: 'A soothing guided meditation to relieve stress and re-center yourself.',
      category: 'Audio',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      uploadedBy: 'cns-1',
      uploadedByName: 'Dr. Sarah Jenkins',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ));
    _resources.add(Resource(
      id: 'res-2',
      title: 'Coping with Depression Guide',
      description: 'A comprehensive handbook of practical self-care steps for depression.',
      category: 'PDF',
      url: 'https://pdfobject.com/pdf/sample.pdf',
      uploadedBy: 'adm-1',
      uploadedByName: 'Campus Admin',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ));
  }

  void _seedDefaultChatbotSessions() {
    _chatbotSessions.clear();
    _chatbotSessions.add(ChatbotSession(
      id: 'chat-1',
      studentId: 'std-1',
      studentPseudonym: 'BraveRiver-123',
      concern: 'Academic Stress',
      severity: 'Moderate',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ));
    _chatbotSessions.add(ChatbotSession(
      id: 'chat-2',
      studentId: 'std-1',
      studentPseudonym: 'BraveRiver-123',
      concern: 'Depression',
      severity: 'Severe',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ));
  }

  void _seedDefaultAssessments() {
    _assessmentReports.clear();
    _assessmentReports.add(AssessmentReport(
      id: 'asmt-1',
      studentId: 'std-1',
      studentPseudonym: 'ResilientSun-891',
      type: 'PHQ-9',
      score: 16,
      severity: 'Severe',
      answers: {'q1': 2, 'q2': 3, 'q3': 2, 'q4': 1, 'q5': 2, 'q6': 3, 'q7': 1, 'q8': 1, 'q9': 1},
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ));
  }

  // --- Persistence Save Helpers ---

  Future<void> _saveUsersState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_users', jsonEncode(_users.map((e) => e.toMap()).toList()));
    await prefs.setString('mock_passwords', jsonEncode(_passwords));
  }

  Future<void> _saveAppointmentsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_appointments', jsonEncode(_appointments.map((e) => e.toMap()).toList()));
  }

  Future<void> _savePostsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_posts', jsonEncode(_posts.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveResourcesState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_resources', jsonEncode(_resources.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveChatbotSessionsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_chatbot_sessions', jsonEncode(_chatbotSessions.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveAssessmentsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_assessments', jsonEncode(_assessmentReports.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveWarningsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_warnings', jsonEncode(_warnings));
  }

  // --- Internal Auth Helpers ---

  Future<AppUser?> authenticate(String username, String password) async {
    await init();
    final trimmedUser = username.trim();
    if (_passwords.containsKey(trimmedUser) && _passwords[trimmedUser] == password) {
      // Find matching AppUser
      return _users.firstWhere(
        (u) => u.username == trimmedUser || (trimmedUser == 'student' && u.uid == 'std-1') || (trimmedUser == 'counsellor' && u.uid == 'cns-1') || (trimmedUser == 'admin' && u.uid == 'adm-1'),
        orElse: () => AppUser(
          uid: 'temp-uid',
          name: trimmedUser,
          username: trimmedUser,
          role: trimmedUser == 'admin' ? 'admin' : (trimmedUser == 'counsellor' ? 'counsellor' : 'student'),
          createdAt: DateTime.now(),
        ),
      );
    }
    return null;
  }

  Future<AppUser> registerUser(AppUser user, String password) async {
    await init();
    // Prevent duplicate usernames
    if (_users.any((u) => u.username.toLowerCase() == user.username.toLowerCase())) {
      throw Exception('Username already exists.');
    }
    _users.add(user);
    _passwords[user.username] = password;
    await _saveUsersState();
    return user;
  }

  // --- DatabaseService Interface Implementations ---

  Future<void> deleteUserByUid(String uid) async {
    await init();
    final user = _users.firstWhere((u) => u.uid == uid, orElse: () => throw Exception('User not found'));
    _users.removeWhere((u) => u.uid == uid);
    _passwords.remove(user.username);
    await _saveUsersState();
  }

  @override
  Future<List<AppUser>> getCounsellors() async {
    await init();
    return _users.where((u) => u.role == 'counsellor').toList();
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    await init();
    return List.from(_users);
  }

  @override
  Future<List<Appointment>> getAppointments(String userId, String role) async {
    await init();
    if (role == 'admin') {
      return List.from(_appointments);
    } else if (role == 'counsellor') {
      return _appointments.where((a) => a.counsellorId == userId).toList();
    } else {
      return _appointments.where((a) => a.studentId == userId).toList();
    }
  }

  @override
  Future<void> bookAppointment(Appointment appointment) async {
    await init();
    _appointments.add(appointment);
    await _saveAppointmentsState();
  }

  @override
  Future<void> updateAppointmentStatus(
    String id, 
    String status, {
    String? scheduledDateTime, 
    String? sessionNotes,
  }) async {
    await init();
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(
        status: status,
        scheduledDateTime: scheduledDateTime,
        sessionNotes: sessionNotes,
      );
      await _saveAppointmentsState();
    }
  }

  @override
  Future<List<ForumPost>> getApprovedForumPosts() async {
    await init();
    return _posts.where((p) => p.status == 'approved').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ForumPost>> getPendingForumPosts() async {
    await init();
    return _posts.where((p) => p.status == 'pending').toList();
  }

  @override
  Future<List<ForumPost>> getAllForumPosts() async {
    await init();
    final all = List<ForumPost>.from(_posts);
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<void> createForumPost(ForumPost post) async {
    await init();
    _posts.add(post);
    await _savePostsState();
  }

  @override
  Future<void> approveForumPost(String postId) async {
    await init();
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final p = _posts[index];
      _posts[index] = ForumPost(
        id: p.id,
        studentId: p.studentId,
        studentPseudonym: p.studentPseudonym,
        title: p.title,
        content: p.content,
        status: 'approved',
        createdAt: p.createdAt,
      );
      await _savePostsState();
    }
  }

  @override
  Future<void> removeForumPost(String postId) async {
    await init();
    _posts.removeWhere((p) => p.id == postId);
    await _savePostsState();
  }

  @override
  Future<void> warnUser(String studentId, String warningText) async {
    await init();
    if (!_warnings.containsKey(studentId)) {
      _warnings[studentId] = [];
    }
    _warnings[studentId]!.add(warningText);
    await _saveWarningsState();
  }

  @override
  Future<List<String>> getUserWarnings(String studentId) async {
    await init();
    return _warnings[studentId] ?? [];
  }

  @override
  Future<List<Resource>> getResources() async {
    await init();
    return List.from(_resources);
  }

  @override
  Future<void> createResource(Resource resource) async {
    await init();
    _resources.add(resource);
    await _saveResourcesState();
  }

  @override
  Future<void> updateResource(Resource resource) async {
    await init();
    final index = _resources.indexWhere((r) => r.id == resource.id);
    if (index != -1) {
      _resources[index] = resource;
      await _saveResourcesState();
    }
  }

  @override
  Future<void> deleteResource(String id) async {
    await init();
    _resources.removeWhere((r) => r.id == id);
    await _saveResourcesState();
  }

  @override
  Future<List<ChatbotSession>> getChatbotSessions() async {
    await init();
    return List.from(_chatbotSessions);
  }

  @override
  Future<void> logChatbotSession(ChatbotSession session) async {
    await init();
    _chatbotSessions.add(session);
    await _saveChatbotSessionsState();
  }

  @override
  Future<List<AssessmentReport>> getAssessmentReports() async {
    await init();
    return List.from(_assessmentReports);
  }

  @override
  Future<void> submitAssessmentReport(AssessmentReport report) async {
    await init();
    _assessmentReports.add(report);
    await _saveAssessmentsState();
  }
}
