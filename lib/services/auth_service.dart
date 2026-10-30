import '../models/user_model.dart';

abstract class AuthService {
  /// Stream to listen to auth state changes
  Stream<AppUser?> get onAuthStateChanged;

  /// Log in with credentials
  Future<AppUser?> login(String username, String password);

  /// Log out securely
  Future<void> logout();

  /// Retrieve currently logged in user
  Future<AppUser?> getCurrentUser();

  /// Create a new user (called by Admin)
  Future<AppUser> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
  });

  /// Delete an existing user by uid (called by Admin)
  Future<void> deleteUser(String uid);
}
