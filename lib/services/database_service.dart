import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/post_model.dart';
import '../models/resource_model.dart';
import '../models/assessment_model.dart';
import '../models/chatbot_session_model.dart';

abstract class DatabaseService {
  // User Management
  Future<List<AppUser>> getCounsellors();
  Future<List<AppUser>> getAllUsers();
  
  // Appointments / Counselling
  Future<List<Appointment>> getAppointments(String userId, String role);
  Future<void> bookAppointment(Appointment appointment);
  Future<void> updateAppointmentStatus(
    String id, 
    String status, {
    String? scheduledDateTime, 
    String? sessionNotes,
  });
  
  // Peer Forum
  Future<List<ForumPost>> getApprovedForumPosts();
  Future<List<ForumPost>> getPendingForumPosts();
  Future<List<ForumPost>> getAllForumPosts();
  Future<void> createForumPost(ForumPost post);
  Future<void> approveForumPost(String postId);
  Future<void> removeForumPost(String postId);
  Future<void> warnUser(String studentId, String warningText);
  Future<List<String>> getUserWarnings(String studentId);

  // Wellness Resources
  Future<List<Resource>> getResources();
  Future<void> createResource(Resource resource);
  Future<void> updateResource(Resource resource);
  Future<void> deleteResource(String id);

  // Chatbot Reports
  Future<List<ChatbotSession>> getChatbotSessions();
  Future<void> logChatbotSession(ChatbotSession session);

  // Assessments
  Future<List<AssessmentReport>> getAssessmentReports();
  Future<void> submitAssessmentReport(AssessmentReport report);
}
