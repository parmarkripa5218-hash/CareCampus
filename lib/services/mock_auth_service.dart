import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'mock_database_service.dart';

class MockAuthService implements AuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  final _dbService = MockDatabaseService();
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> get onAuthStateChanged async* {
    // Immediately yield current state so StreamBuilder doesn't wait forever.
    // This is needed because init() runs before the StreamBuilder subscribes,
    // and broadcast streams don't replay past events.
    yield _currentUser;
    yield* _authStateController.stream;
  }

  /// Load session from SharedPreferences on app launch.
  /// Sets _currentUser so onAuthStateChanged yields it immediately on subscribe.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('current_session_username');
    if (currentUsername != null) {
      final allUsers = await _dbService.getAllUsers();
      final userIndex = allUsers.indexWhere((u) => u.username == currentUsername);
      if (userIndex != -1) {
        _currentUser = allUsers[userIndex];
        return;
      }
    }
    // No valid session — _currentUser stays null (login screen will be shown)
  }

  @override
  Future<AppUser?> login(String username, String password) async {
    final user = await _dbService.authenticate(username, password);
    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_session_username', user.username);
      _authStateController.add(_currentUser);
    }
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_session_username');
    _authStateController.add(null);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (_currentUser == null) {
      await init();
    }
    return _currentUser;
  }

  @override
  Future<AppUser> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    final newUser = AppUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: username,
      role: role,
      createdAt: DateTime.now(),
    );
    await _dbService.registerUser(newUser, password);
    return newUser;
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _dbService.deleteUserByUid(uid);
  }
}
