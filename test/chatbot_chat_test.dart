import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carecampus/screens/admin/chatbot_reports.dart';
import 'package:carecampus/screens/student/chatbot_chat.dart';
import 'package:carecampus/services/services.dart';
import 'package:carecampus/utils/theme.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await Services.initialize(forceMock: true);
  });

  Widget createChatScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ChatbotChat(),
    );
  }

  testWidgets('ChatbotChat renders UI elements and welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(createChatScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check AppBar and initial elements
    expect(find.text('AI Wellness Companion'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Welcome message should be visible
    expect(find.textContaining('CareCampus Wellness Companion'), findsOneWidget);

    // Suggestion chips should be visible
    expect(find.text('🌬️ Box Breathing'), findsOneWidget);
    expect(find.text('📝 Exam Stress'), findsOneWidget);
  });

  testWidgets('Sending a crisis message triggers Crisis Emergency Banner', (WidgetTester tester) async {
    await tester.pumpWidget(createChatScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Type a critical distress message
    final textField = find.byType(TextField);
    await tester.enterText(textField, 'I feel hopeless and want to end my life');
    await tester.pump();

    // Tap send
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Crisis Banner should now appear
    expect(find.text('Immediate Support: You are not alone.'), findsOneWidget);
    expect(find.text('Call 112 Lifeline'), findsOneWidget);
    expect(find.text('Book Counsellor Appointment'), findsOneWidget);
  });

  testWidgets('Settings button opens Gemini API settings modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createChatScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap settings gear icon
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog should be displayed
    expect(find.text('Gemini AI Settings'), findsOneWidget);
    expect(find.text('Save & Apply'), findsOneWidget);
    expect(find.textContaining('free-tier Google Gemini API'), findsOneWidget);
  });

  testWidgets('Box breathing button opens breathing modal', (WidgetTester tester) async {
    await tester.pumpWidget(createChatScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap box breathing icon in AppBar
    await tester.tap(find.byIcon(Icons.air_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Modal should be visible
    expect(find.text('Box Breathing (4-4-4-4)'), findsOneWidget);
    expect(find.textContaining('Inhale slowly through your nose'), findsOneWidget);

    // Tap Done to close modal
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('ChatbotChat renders without overflow on narrow mobile screens (320px)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createChatScreen());
    await tester.pumpAndSettle();

    // Verify no RenderFlex overflow exception
    expect(tester.takeException(), isNull);
    expect(find.text('AI Wellness Companion'), findsOneWidget);
  });

  testWidgets('Admin ChatbotReports renders KPI count boxes without overflow on mobile screen (360px)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ChatbotReports(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no RenderFlex overflow exception
    expect(tester.takeException(), isNull);
    expect(find.text('AI Conversation Analytics'), findsOneWidget);
    expect(find.text('Total Conversations'), findsOneWidget);
  });

  testWidgets('Gear settings modal renders without overflow on 320px screen with API key active', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'gemini_api_key': 'AIzaSyTestKey12345',
    });

    await tester.pumpWidget(createChatScreen());
    await tester.pumpAndSettle();

    // Tap gear button
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Gemini AI Settings'), findsOneWidget);
    expect(find.text('Clear Key'), findsOneWidget);
    expect(find.text('Save & Apply'), findsOneWidget);
  });
}

