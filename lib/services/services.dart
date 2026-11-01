import 'package:firebase_core/firebase_core.dart';
import '../config.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_database_service.dart';
import 'mock_auth_service.dart';
import 'mock_database_service.dart';

class Services {
  static late AuthService auth;
  static late DatabaseService db;
  static bool isFirebaseActive = false;

  static Future<void> initialize({bool? forceMock}) async {
    bool canUseFirebase = AppConfig.useFirebase && (forceMock != true);
    if (canUseFirebase) {
      try {
        canUseFirebase = Firebase.apps.isNotEmpty;
      } catch (_) {
        canUseFirebase = false;
      }
    }

    if (canUseFirebase) {
      auth = FirebaseAuthService();
      db = FirebaseDatabaseService();
      isFirebaseActive = true;
    } else {
      final mockAuth = MockAuthService();
      final mockDb = MockDatabaseService();
      
      // Initialize persistent mock database and session
      await mockDb.init();
      await mockAuth.init();
      
      auth = mockAuth;
      db = mockDb;
      isFirebaseActive = false;
    }
  }
}
