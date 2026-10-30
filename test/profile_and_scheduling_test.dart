import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carecampus/models/user_model.dart';
import 'package:carecampus/models/appointment_model.dart';
import 'package:carecampus/services/services.dart';
import 'package:carecampus/utils/theme.dart';
import 'package:carecampus/widgets/user_profile_dialog.dart';
import 'package:carecampus/screens/counsellor/appointment_requests.dart';
import 'package:carecampus/screens/student/student_dashboard.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await Services.initialize(forceMock: true);
  });

  testWidgets('showUserProfileDialog renders student profile with theme and details', (WidgetTester tester) async {
    final student = AppUser(
      uid: 'std-test-1',
      name: 'Jane Doe',
      username: 'student@carecampus.org',
      role: 'student',
      createdAt: DateTime(2026, 1, 15),
    );

    bool loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showUserProfileDialog(
                    context,
                    user: student,
                    onLogout: () => loggedOut = true,
                  );
                },
                child: const Text('Open Profile'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open profile dialog
    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();

    // Verify dialog contents
    expect(find.text('CareCampus Profile'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('student@carecampus.org'), findsOneWidget);
    expect(find.text('Student Member'), findsOneWidget);
    expect(find.textContaining('Anonymity Shield'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Scroll and tap Sign Out
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });

  testWidgets('showUserProfileDialog renders counsellor profile with verified status', (WidgetTester tester) async {
    final counsellor = AppUser(
      uid: 'cns-test-1',
      name: 'Dr. Sarah Jenkins',
      username: 'counsellor@carecampus.org',
      role: 'counsellor',
      createdAt: DateTime(2026, 2, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showUserProfileDialog(
                    context,
                    user: counsellor,
                    onLogout: () {},
                  );
                },
                child: const Text('Open Counsellor Profile'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Counsellor Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Sarah Jenkins'), findsOneWidget);
    expect(find.text('Campus Counsellor'), findsOneWidget);
    expect(find.textContaining('Verified Practitioner'), findsOneWidget);
  });

  testWidgets('showUserProfileDialog renders admin profile with admin privileges', (WidgetTester tester) async {
    final admin = AppUser(
      uid: 'adm-test-1',
      name: 'Campus Administrator',
      username: 'admin@carecampus.org',
      role: 'admin',
      createdAt: DateTime(2026, 3, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showUserProfileDialog(
                    context,
                    user: admin,
                    onLogout: () {},
                  );
                },
                child: const Text('Open Admin Profile'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Admin Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Campus Administrator'), findsWidgets);
    expect(find.textContaining('Administrator Privileges'), findsOneWidget);
  });

  testWidgets('AppointmentRequests scheduling dialog renders themed date/time cards', (WidgetTester tester) async {
    await Services.auth.login('counsellor@carecampus.org', 'CounsellorPassword@123');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppointmentRequests(),
      ),
    );
    await tester.pumpAndSettle();

    // Look for pending request or book a test one if none
    if (find.text('Schedule & Accept').evaluate().isEmpty) {
      await Services.db.bookAppointment(Appointment(
        id: 'test-appt-123',
        studentId: 'std-1',
        studentPseudonym: 'Calm River',
        counsellorId: 'cns-1',
        counsellorName: 'Dr. Sarah Jenkins',
        status: 'pending',
        bookingDate: DateTime.now(),
        isAnonymous: true,
        anonymousAlertReason: 'Exam stress & sleep difficulty',
      ));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppointmentRequests(),
        ),
      );
      await tester.pumpAndSettle();
    }

    final scheduleBtn = find.text('Schedule & Accept');
    if (scheduleBtn.evaluate().isNotEmpty) {
      await tester.tap(scheduleBtn.first);
      await tester.pumpAndSettle();

      // Verify the new themed schedule dialog
      expect(find.text('Schedule Session'), findsOneWidget);
      expect(find.text('SESSION DATE'), findsOneWidget);
      expect(find.text('SESSION TIME'), findsOneWidget);
      expect(find.text('Confirm & Schedule'), findsOneWidget);
      expect(find.text('Tap to select date'), findsOneWidget);
      expect(find.text('Tap to select time'), findsOneWidget);
    }
  });

  testWidgets('Tapping profile avatar in StudentDashboard opens UserProfileDialog', (WidgetTester tester) async {
    await Services.auth.login('student@carecampus.org', 'StudentPassword@123');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const StudentDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap profile avatar in AppBar
    final profileIcon = find.byTooltip('My Profile');
    expect(profileIcon, findsOneWidget);
    await tester.tap(profileIcon);
    await tester.pumpAndSettle();

    // Profile dialog should be open
    expect(find.text('CareCampus Profile'), findsOneWidget);
    expect(find.text('Student Member'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Tap Close icon at the top
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('CareCampus Profile'), findsNothing);
  });
}
