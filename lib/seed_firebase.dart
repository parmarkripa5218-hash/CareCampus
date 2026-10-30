import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Run this once after Firebase setup to seed the database with demo data.
/// Usage: flutter run -t lib/seed_firebase.dart -d chrome
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = fb.FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  print('🌱 Starting Firebase seeder...');

  // --- Create Users in Auth + Firestore ---
  final users = [
    {
      'email': 'student@carecampus.org',
      'password': 'StudentPassword\u0040123',
      'name': 'Jane Doe',
      'role': 'student',
      'shortKey': 'student',
    },
    {
      'email': 'counsellor@carecampus.org',
      'password': 'CounsellorPassword\u0040123',
      'name': 'Dr. Sarah Jenkins',
      'role': 'counsellor',
      'shortKey': 'counsellor',
    },
    {
      'email': 'admin@carecampus.org',
      'password': 'AdminPassword\u0040123',
      'name': 'Campus Admin',
      'role': 'admin',
      'shortKey': 'admin',
    },
  ];

  final Map<String, String> uidMap = {};

  for (final user in users) {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: user['email']!,
        password: user['password']!,
      );
      final uid = credential.user!.uid;
      uidMap[user['shortKey']!] = uid;

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': user['name'],
        'username': user['email'],
        'role': user['role'],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Created ${user['role']}: ${user['email']} (uid: $uid)');
    } catch (e) {
      print('⚠️  ${user['email']} already exists or error: $e');
      // Try to get existing UID
      try {
        final cred = await auth.signInWithEmailAndPassword(
          email: user['email']!,
          password: user['password']!,
        );
        uidMap[user['shortKey']!] = cred.user!.uid;
        print('   → Found existing uid: ${cred.user!.uid}');
        await auth.signOut();
      } catch (_) {}
    }
  }

  final studentUid = uidMap['student'] ?? 'std-1';
  final counsellorUid = uidMap['counsellor'] ?? 'cns-1';

  // --- Seed Appointments ---
  await db.collection('appointments').doc('apt-seed-1').set({
    'id': 'apt-seed-1',
    'studentId': studentUid,
    'studentPseudonym': 'Jane Doe',
    'counsellorId': counsellorUid,
    'counsellorName': 'Dr. Sarah Jenkins',
    'status': 'completed',
    'bookingDate': DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch,
    'scheduledDateTime': '2026-07-10 10:00 AM',
    'sessionNotes': 'Student discussed academic anxiety. Shared breathing techniques.',
    'isAnonymous': false,
  });
  print('✅ Seeded appointments');

  // --- Seed Forum Posts ---
  await db.collection('forum_posts').doc('post-seed-1').set({
    'id': 'post-seed-1',
    'studentId': studentUid,
    'studentPseudonym': 'GentleSky-482',
    'title': 'Managing academic stress',
    'content': 'Hey guys, I have been feeling super overwhelmed by assignments lately. How do you all cope?',
    'status': 'approved',
    'createdAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
  });
  print('✅ Seeded forum posts');

  // --- Seed Resources ---
  await db.collection('resources').doc('res-seed-1').set({
    'id': 'res-seed-1',
    'title': '5-Minute Guided Meditation',
    'description': 'A soothing guided meditation to relieve stress.',
    'category': 'Audio',
    'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'uploadedBy': counsellorUid,
    'uploadedByName': 'Dr. Sarah Jenkins',
    'createdAt': DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch,
  });
  print('✅ Seeded resources');

  // --- Seed Chatbot Session ---
  await db.collection('chatbot_sessions').doc('chat-seed-1').set({
    'id': 'chat-seed-1',
    'studentId': studentUid,
    'studentPseudonym': 'BraveRiver-123',
    'concern': 'Academic Stress',
    'severity': 'Moderate',
    'createdAt': DateTime.now().subtract(const Duration(days: 4)).millisecondsSinceEpoch,
  });
  print('✅ Seeded chatbot sessions');

  // --- Seed Assessment ---
  await db.collection('assessments').doc('asmt-seed-1').set({
    'id': 'asmt-seed-1',
    'studentId': studentUid,
    'studentPseudonym': 'ResilientSun-891',
    'type': 'PHQ-9',
    'score': 16,
    'severity': 'Severe',
    'answers': {'q1': 2, 'q2': 3, 'q3': 2, 'q4': 1, 'q5': 2, 'q6': 3, 'q7': 1, 'q8': 1, 'q9': 1},
    'createdAt': DateTime.now().subtract(const Duration(days: 6)).millisecondsSinceEpoch,
  });
  print('✅ Seeded assessments');

  print('');
  print('🎉 Seeding complete!');
  print('Login credentials:');
  print('  Student:    student@carecampus.org / StudentPassword@123');
  print('  Counsellor: counsellor@carecampus.org / CounsellorPassword@123');
  print('  Admin:      admin@carecampus.org / AdminPassword@123');

  print('Done. You can close this browser tab now.');
}
