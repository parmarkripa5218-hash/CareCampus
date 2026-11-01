import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'services/services.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/counsellor/counsellor_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe Firebase Initialization check
  if (AppConfig.useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  // Initialize service registry (Mock or Firebase databases)
  await Services.initialize();

  runApp(const CareCampusApp());
}

class CareCampusApp extends StatelessWidget {
  final Widget? home;
  const CareCampusApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home ?? const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Services.auth.onAuthStateChanged,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.skyWhite,
            body: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppTheme.tealBlue),
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // Guard redirect according to account role type
          if (user.role == 'admin') {
            return const AdminDashboard();
          } else if (user.role == 'counsellor') {
            return const CounsellorDashboard();
          } else {
            return const StudentDashboard();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
