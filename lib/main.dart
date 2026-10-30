import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
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
  const CareCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthCheckScreen(),
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
          return const _SplashScreen();
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

// ── Branded Splash / Loading Screen ──────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.skyWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient logo box
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tealBlue.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Care',
                    style: GoogleFonts.nunito(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.mintGreen,
                    ),
                  ),
                  TextSpan(
                    text: 'Campus',
                    style: GoogleFonts.nunito(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.tealBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your safe space for mental wellness',
              style: GoogleFonts.nunito(
                color: AppTheme.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.tealBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
