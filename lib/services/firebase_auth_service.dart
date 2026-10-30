import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return await _fetchUserFromFirestore(fbUser.uid);
    });
  }

  Future<AppUser?> _fetchUserFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      // Document missing in Firestore — auth user exists but no profile
      dev.log('FirebaseAuthService: No Firestore profile found for uid=$uid', name: 'Auth');
      return null;
    } catch (e) {
      // Rethrow so callers can surface the real error (e.g. permission-denied)
      dev.log('FirebaseAuthService: Firestore fetch failed for uid=$uid: $e', name: 'Auth');
      rethrow;
    }
  }

  @override
  Future<AppUser?> login(String username, String password) async {
    final email = username.contains('@') ? username : '$username@carecampus.org';
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return await _fetchUserFromFirestore(credential.user!.uid);
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      dev.log('FirebaseAuthService: Auth error [${e.code}]: ${e.message}', name: 'Auth');
      // These codes mean wrong credentials — return null so UI shows login error
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        return null;
      }
      // Any other Firebase Auth error (network, too-many-requests, etc.) → rethrow
      rethrow;
    }
    // Note: Firestore errors from _fetchUserFromFirestore are NOT caught here;
    // they propagate up so the login screen shows the real error message.
  }


  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return await _fetchUserFromFirestore(fbUser.uid);
  }

  @override
  Future<AppUser> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    // Create in Firebase Auth
    final email = username.contains('@') ? username : '$username@carecampus.org';
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final uid = credential.user!.uid;
    final newUser = AppUser(
      uid: uid,
      name: name,
      username: email,
      role: role,
      createdAt: DateTime.now(),
    );
    
    // Save profile to Firestore
    await _db.collection('users').doc(uid).set(newUser.toMap());
    return newUser;
  }

  @override
  Future<void> deleteUser(String uid) async {
    // Delete from Firestore first
    final targetUid = uid.trim();
    if (targetUid.isEmpty) {
      throw ArgumentError('Cannot delete user: user ID is empty.');
    }
    await _db.collection('users').doc(targetUid).delete();
    // Note: Deleting from Firebase Auth requires Admin SDK or re-authentication.
    // For now, we just remove the Firestore profile (user cannot log in without profile).
  }
}
