import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carecampus/services/gemini_service.dart';
import 'package:carecampus/models/user_model.dart';
import 'package:carecampus/models/assessment_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GeminiService Crisis Detection Tests', () {
    final gemini = GeminiService();

    test('Immediate crisis keywords detection', () {
      expect(gemini.detectImmediateCrisis('I am thinking about suicide'), isTrue);
      expect(gemini.detectImmediateCrisis('I want to kill myself tonight'), isTrue);
      expect(gemini.detectImmediateCrisis('I want to end my life'), isTrue);
      expect(gemini.detectImmediateCrisis('feeling like I should hurt myself'), isTrue);
      expect(gemini.detectImmediateCrisis('planning to overdose on pills'), isTrue);
      expect(gemini.detectImmediateCrisis('I am better off dead'), isTrue);
      expect(gemini.detectImmediateCrisis('goodbye forever, can\'t live anymore'), isTrue);
    });

    test('Non-crisis expressions are not flagged as immediate crisis', () {
      expect(gemini.detectImmediateCrisis('I am stressed about my exam'), isFalse);
      expect(gemini.detectImmediateCrisis('I have not slept well for three days'), isFalse);
      expect(gemini.detectImmediateCrisis('Feeling anxious about presentations'), isFalse);
      expect(gemini.detectImmediateCrisis('Can I speak with a counsellor?'), isFalse);
    });

    test('Crisis distress analysis returns Severe and Depression/Crisis', () {
      final analysis = gemini.analyzeDistress(
        message: 'I want to kill myself, everything is hopeless',
      );
      expect(analysis.isCrisis, isTrue);
      expect(analysis.severity, equals('Severe'));
      expect(analysis.concern, equals('Depression/Crisis'));
      expect(analysis.shouldSuggestCounsellor, isTrue);
    });
  });

  group('GeminiService Topic & Distress Analysis Tests', () {
    final gemini = GeminiService();
    final counsellors = [
      AppUser(
        uid: 'cns-1',
        name: 'Dr. Sarah Jenkins',
        username: 'counsellor@carecampus.org',
        role: 'counsellor',
        createdAt: DateTime.now(),
      )
    ];

    test('Academic stress detection', () {
      final analysis = gemini.analyzeDistress(
        message: 'I have three exams this week and I feel like I will fail my assignment',
        counsellors: counsellors,
      );
      expect(analysis.concern, equals('Academic Stress'));
    });

    test('Anxiety and panic detection', () {
      final analysis = gemini.analyzeDistress(
        message: 'I am having a panic attack, my heart is racing and I feel anxious',
        counsellors: counsellors,
      );
      expect(analysis.concern, equals('Anxiety'));
      expect(analysis.shouldSuggestCounsellor, isTrue);
      expect(analysis.matchedCounsellorId, equals('cns-1'));
    });

    test('Sleep issues detection', () {
      final analysis = gemini.analyzeDistress(
        message: 'I have severe insomnia and cannot sleep at night',
        counsellors: counsellors,
      );
      expect(analysis.concern, equals('Sleep issues'));
    });

    test('Social isolation detection', () {
      final analysis = gemini.analyzeDistress(
        message: 'I feel so lonely and isolated on campus, I have no friends',
        counsellors: counsellors,
      );
      expect(analysis.concern, equals('Social Isolation'));
    });

    test('Direct counsellor request', () {
      final analysis = gemini.analyzeDistress(
        message: 'Can I book an appointment with a counsellor?',
        counsellors: counsellors,
      );
      expect(analysis.shouldSuggestCounsellor, isTrue);
      expect(analysis.matchedCounsellorId, equals('cns-1'));
    });
  });

  group('GeminiService System Instruction & Personalization Tests', () {
    final gemini = GeminiService();

    test('System instruction includes student and assessment context', () {
      final student = AppUser(
        uid: 'std-10',
        name: 'Jane Doe',
        username: 'jane@test.org',
        role: 'student',
        createdAt: DateTime.now(),
      );

      final assessments = [
        AssessmentReport(
          id: 'asmt-1',
          studentId: 'std-10',
          studentPseudonym: 'CalmRiver-102',
          type: 'GAD-7',
          score: 14,
          severity: 'Moderate',
          answers: {},
          createdAt: DateTime.now(),
        )
      ];

      final counsellors = [
        AppUser(
          uid: 'cns-1',
          name: 'Dr. Sarah Jenkins',
          username: 'sarah@test.org',
          role: 'counsellor',
          createdAt: DateTime.now(),
        )
      ];

      final instruction = gemini.buildSystemInstruction(
        student: student,
        recentAssessments: assessments,
        availableCounsellors: counsellors,
      );

      expect(instruction, contains('CareCampus Wellness Companion'));
      expect(instruction, contains('Jane Doe'));
      expect(instruction, contains('GAD-7 | Severity: Moderate'));
      expect(instruction, contains('Dr. Sarah Jenkins'));
      expect(instruction, contains('112'));
      expect(instruction, contains('[ACTION:COUNSELLOR]'));
      expect(instruction, contains('[ACTION:BREATHING]'));
    });
  });

  group('GeminiService Local Fallback Generator Tests', () {
    final gemini = GeminiService();

    test('Generates coping response for academic stress', () {
      final reply = gemini.generateLocalFallback(message: 'Stressed about finals and grades');
      expect(reply, contains('Pomodoro'));
      expect(reply, contains('Academic pressure'));
    });

    test('Generates 5-4-3-2-1 technique for anxiety', () {
      final reply = gemini.generateLocalFallback(message: 'I am so anxious and panicking');
      expect(reply, contains('5-4-3-2-1 Sensory Technique'));
      expect(reply, contains('things you can see'));
    });

    test('Generates crisis response with emergency hotlines', () {
      final reply = gemini.generateLocalFallback(message: 'I want to kill myself');
      expect(reply, contains('112 Emergency & Crisis Lifeline'));
      expect(reply, contains('Tele-MANAS'));
      expect(reply, contains('Book Anonymous Appointment Now'));
    });
  });

  group('GeminiService Key Storage & Detailed Result Tests', () {
    final gemini = GeminiService();

    test('Saving and clearing API key via SharedPreferences', () async {
      await gemini.saveApiKey('test-key-12345');
      final saved = await gemini.getApiKey();
      expect(saved, equals('test-key-12345'));

      await gemini.clearApiKey();
      final cleared = await gemini.getApiKey();
      expect(cleared, isNull);
    });

    test('sendMessageDetailed returns transparent status when no key is set', () async {
      await gemini.clearApiKey();
      final result = await gemini.sendMessageDetailed(
        message: 'I have anxiety about exams',
        conversationHistory: [],
      );

      expect(result.isFromAI, isFalse);
      expect(result.errorMessage, contains('Gemini API key is not configured'));
      expect(result.concern, equals('Academic Stress'));
      expect(result.text, contains('Academic pressure'));
    });

    test('testConnection handles empty key gracefully', () async {
      final err = await gemini.testConnection('');
      expect(err, equals('API Key is empty.'));
    });

    test('Defaults to gemini-3.5-flash-lite and migrates deprecated models', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gemini_model_name');

      // Default should be gemini-3.5-flash-lite
      final defaultModel = await gemini.getModelName();
      expect(defaultModel, equals('gemini-3.5-flash-lite'));

      // If a deprecated model like 1.5 was stored, it auto-migrates
      await prefs.setString('gemini_model_name', 'gemini-1.5-flash');
      final migratedModel = await gemini.getModelName();
      expect(migratedModel, equals('gemini-3.5-flash-lite'));
    });
  });
}
