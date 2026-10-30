// Application Configuration

class AppConfig {
  /// Toggle this to true if you want to connect to actual Firebase.
  /// If false, the application runs entirely offline using local memory
  /// and SharedPreferences, pre-seeded with student, counsellor, and admin users.
  static const bool useFirebase = true;
  
  // App Title
  static const String appName = 'CareCampus';

  /// Free-Tier Gemini API Configuration
  /// Security Best Practice:
  /// 1. Provide at compile-time via:
  ///    flutter run --dart-define=GEMINI_API_KEY=your_key_here
  /// 2. Or configure via in-app Settings in the Chatbot screen (persisted securely in local storage).
  ///
  /// Never hardcode personal production API keys into version control.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Gemini Model identifier (free tier includes 'gemini-3.5-flash-lite', 'gemini-3.8-flash')
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );
}
