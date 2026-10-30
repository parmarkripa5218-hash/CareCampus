import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/assessment_model.dart';
import '../models/user_model.dart';

/// Result of analyzing student distress and intent
class DistressAnalysis {
  final bool isCrisis;
  final String concern; // 'Academic Stress' | 'Anxiety' | 'Depression/Crisis' | 'Sleep issues' | 'Social Isolation' | 'General Support'
  final String severity; // 'Low' | 'Moderate' | 'Severe'
  final bool shouldSuggestCounsellor;
  final String? matchedCounsellorId;

  const DistressAnalysis({
    required this.isCrisis,
    required this.concern,
    required this.severity,
    required this.shouldSuggestCounsellor,
    this.matchedCounsellorId,
  });
}

/// Rich structured result returned from Gemini AI (or intelligent local fallback)
class GeminiChatResult {
  final String text;
  final bool isFromAI;
  final String? errorMessage;
  final String concern;
  final String severity;
  final bool shouldSuggestCounsellor;
  final String? matchedCounsellorId;
  final bool shouldSuggestBreathing;
  final bool shouldSuggestResource;
  final bool isCrisis;

  const GeminiChatResult({
    required this.text,
    required this.isFromAI,
    this.errorMessage,
    required this.concern,
    required this.severity,
    required this.shouldSuggestCounsellor,
    this.matchedCounsellorId,
    required this.shouldSuggestBreathing,
    required this.shouldSuggestResource,
    required this.isCrisis,
  });
}

/// Service managing Gemini AI interactions, security, personalized prompt engineering,
/// autonomous action detection, crisis safety nets, and offline wellness fallbacks.
class GeminiService {
  static const String _prefApiKey = 'gemini_api_key';
  static const String _prefModel = 'gemini_model';

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _activeApiKey;
  String? _activeModel;

  /// Supported free-tier models in priority order
  static const List<String> supportedModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-2.5-flash',
  ];

  /// Emergency crisis phone hotlines and support resources
  static const Map<String, String> emergencyHotlines = {
    'Emergency & Crisis Lifeline': '112',
    'Campus Security & Crisis Line': '911',
    'Tele-MANAS Mental Health Support': '14416',
    'Crisis Text Line': 'Text HOME to 741741',
  };

  /// Retrieve the active API key:
  /// 1. SharedPreferences (in-app configuration override)
  /// 2. AppConfig.geminiApiKey (compile-time --dart-define=GEMINI_API_KEY=...)
  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString(_prefApiKey);
      if (storedKey != null && storedKey.trim().isNotEmpty) {
        return storedKey.trim();
      }
    } catch (_) {}

    final configKey = AppConfig.geminiApiKey.trim();
    if (configKey.isNotEmpty) {
      return configKey;
    }

    return null;
  }

  /// Check whether an API key is available
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Save or update user's Gemini API key in local persistent storage
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove(_prefApiKey);
    } else {
      await prefs.setString(_prefApiKey, key.trim());
    }
    _model = null;
    _chatSession = null;
    _activeApiKey = null;
  }

  /// Remove user's Gemini API key from local storage
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
    _model = null;
    _chatSession = null;
    _activeApiKey = null;
  }

  /// Get model name (defaults to 'gemini-3.5-flash-lite' on free tier)
  /// Automatically migrates deprecated models (like 'gemini-1.5-flash')
  Future<String> getModelName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedModel = prefs.getString(_prefModel);
      if (storedModel != null && storedModel.trim().isNotEmpty) {
        final trimmed = storedModel.trim();
        // If a previously stored model is deprecated (e.g. 1.5 or 2.0), migrate automatically!
        if (trimmed.contains('1.5') || trimmed.contains('2.0')) {
          await prefs.setString(_prefModel, 'gemini-3.5-flash-lite');
          return 'gemini-3.5-flash-lite';
        }
        return trimmed;
      }
    } catch (_) {}

    final configModel = AppConfig.geminiModel.trim();
    if (configModel.isNotEmpty && !configModel.contains('1.5') && !configModel.contains('2.0')) {
      return configModel;
    }

    return 'gemini-3.5-flash-lite';
  }

  /// Set preferred model name
  Future<void> setModelName(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefModel, model.trim());
    _model = null;
    _chatSession = null;
    _activeModel = null;
  }

  /// Validation test that verifies API connectivity and identifies a supported model
  Future<String?> testConnection(String apiKey, {String? modelName}) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return 'API Key is empty.';

    String targetModel = modelName ?? await getModelName();
    if (targetModel.contains('1.5') || targetModel.contains('2.0')) {
      targetModel = 'gemini-3.5-flash-lite';
    }

    final candidateModels = [
      targetModel,
      if (targetModel != 'gemini-3.5-flash-lite') 'gemini-3.5-flash-lite',
      'gemini-3.8-flash',
      'gemini-2.5-flash',
    ];

    String lastError = '';
    for (final candidate in candidateModels.toSet()) {
      try {
        final testModel = GenerativeModel(
          model: candidate,
          apiKey: trimmed,
        );
        final response = await testModel.generateContent([
          Content.text('Respond with "OK".'),
        ]);
        if (response.text != null && response.text!.isNotEmpty) {
          await setModelName(candidate);
          return null; // Success!
        }
      } catch (e) {
        lastError = e.toString();
        if (lastError.contains('API_KEY_INVALID')) {
          return 'Invalid API key. Please check the key from Google AI Studio.';
        }
      }
    }

    if (lastError.contains('404') || lastError.contains('not found')) {
      return 'Model not found: $lastError';
    } else if (lastError.contains('quota') || lastError.contains('429')) {
      return 'Quota exceeded or rate limited. Please wait a minute.';
    }
    return 'Connection failed: $lastError';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. FAST LOCAL DETERMINISTIC CRISIS DETECTION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Immediate safety check for explicit self-harm or suicide expressions.
  bool detectImmediateCrisis(String message) {
    final lower = message.toLowerCase().trim();

    final highRiskPatterns = [
      'suicide',
      'kill myself',
      'killing myself',
      'end my life',
      'ending my life',
      'want to die',
      'wanna die',
      'wish i was dead',
      'wish i were dead',
      'better off dead',
      'self-harm',
      'self harm',
      'hurt myself',
      'hurting myself',
      'cut myself',
      'slit my wrist',
      'overdose',
      'take all my pills',
      'hang myself',
      'jump off',
      'no reason to live',
      'can\'t live anymore',
      'cant live anymore',
      'goodbye forever',
      'tired of living',
    ];

    for (final pattern in highRiskPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. CONCERN & SEVERITY CLASSIFICATION (HEURISTIC BACKUP)
  // ─────────────────────────────────────────────────────────────────────────────

  DistressAnalysis analyzeDistress({
    required String message,
    String currentSeverity = 'Low',
    List<AppUser>? counsellors,
  }) {
    final lower = message.toLowerCase();

    // Critical crisis check
    if (detectImmediateCrisis(message)) {
      String? counsellorId;
      if (counsellors != null && counsellors.isNotEmpty) {
        counsellorId = counsellors.first.uid;
      }
      return DistressAnalysis(
        isCrisis: true,
        concern: 'Depression/Crisis',
        severity: 'Severe',
        shouldSuggestCounsellor: true,
        matchedCounsellorId: counsellorId,
      );
    }

    String concern = 'General Support';
    String severity = currentSeverity == 'Severe' ? 'Severe' : 'Low';
    bool suggestCounsellor = false;

    // Academic Stress
    if (lower.contains('exam') ||
        lower.contains('study') ||
        lower.contains('test') ||
        lower.contains('assignment') ||
        lower.contains('grade') ||
        lower.contains('gpa') ||
        lower.contains('academic') ||
        lower.contains('coursework') ||
        lower.contains('deadline') ||
        lower.contains('professor') ||
        lower.contains('fail')) {
      concern = 'Academic Stress';
      if (lower.contains('failing') || lower.contains('overwhelmed') || lower.contains('burnout') || lower.contains('cannot cope')) {
        severity = severity == 'Severe' ? 'Severe' : 'Moderate';
      }
    }
    // Anxiety / Panic
    else if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('panic') ||
        lower.contains('racing heart') ||
        lower.contains('can\'t breathe') ||
        lower.contains('shaking') ||
        lower.contains('nervous') ||
        lower.contains('fear') ||
        lower.contains('terrified') ||
        lower.contains('worry') ||
        lower.contains('stress')) {
      concern = 'Anxiety';
      if (lower.contains('panic attack') || lower.contains('cannot breathe') || lower.contains('overwhelming')) {
        severity = severity == 'Severe' ? 'Severe' : 'Moderate';
        suggestCounsellor = true;
      }
    }
    // Sleep issues
    else if (lower.contains('sleep') ||
        lower.contains('insomnia') ||
        lower.contains('nightmare') ||
        lower.contains('can\'t sleep') ||
        lower.contains('tired') ||
        lower.contains('exhausted') ||
        lower.contains('awake') ||
        lower.contains('night')) {
      concern = 'Sleep issues';
      if (lower.contains('days without sleep') || lower.contains('exhausted for weeks')) {
        severity = severity == 'Severe' ? 'Severe' : 'Moderate';
      }
    }
    // Social Isolation
    else if (lower.contains('lonely') ||
        lower.contains('alone') ||
        lower.contains('no friends') ||
        lower.contains('isolated') ||
        lower.contains('homesick') ||
        lower.contains('nobody cares') ||
        lower.contains('fit in') ||
        lower.contains('social')) {
      concern = 'Social Isolation';
      if (lower.contains('nobody') || lower.contains('completely alone')) {
        severity = severity == 'Severe' ? 'Severe' : 'Moderate';
      }
    }
    // Depression / Deep Sadness
    else if (lower.contains('depressed') ||
        lower.contains('depression') ||
        lower.contains('sad') ||
        lower.contains('crying') ||
        lower.contains('empty') ||
        lower.contains('numb') ||
        lower.contains('pointless') ||
        lower.contains('unhappy') ||
        lower.contains('miserable')) {
      concern = 'Depression/Crisis';
      severity = severity == 'Severe' ? 'Severe' : 'Moderate';
      suggestCounsellor = true;
    }

    // Direct request to talk to a human / counsellor
    if (lower.contains('counsellor') ||
        lower.contains('counselor') ||
        lower.contains('therapist') ||
        lower.contains('talk to someone') ||
        lower.contains('book appointment') ||
        lower.contains('human help') ||
        lower.contains('real person')) {
      suggestCounsellor = true;
      if (severity == 'Low') severity = 'Moderate';
    }

    String? matchedCounsellorId;
    if (suggestCounsellor && counsellors != null && counsellors.isNotEmpty) {
      matchedCounsellorId = counsellors.first.uid;
    }

    return DistressAnalysis(
      isCrisis: false,
      concern: concern,
      severity: severity,
      shouldSuggestCounsellor: suggestCounsellor,
      matchedCounsellorId: matchedCounsellorId,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. PERSONALIZED SYSTEM INSTRUCTION WITH AUTONOMOUS ACTION TAGS
  // ─────────────────────────────────────────────────────────────────────────────

  String buildSystemInstruction({
    AppUser? student,
    List<AssessmentReport>? recentAssessments,
    List<AppUser>? availableCounsellors,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('You are the CareCampus Wellness Companion, an empathetic, supportive, active-listening mental wellness assistant designed specifically for higher education students.');
    buffer.writeln();
    buffer.writeln('CORE MISSION & TONE:');
    buffer.writeln('- Speak naturally, conversationally, and warmly. You are NOT a scripted robot or rigid questionnaire.');
    buffer.writeln('- Offer thoughtful, individualized responses that directly address what the student actually said.');
    buffer.writeln('- Provide practical, evidence-based coping exercises: 5-4-3-2-1 grounding, Box Breathing (4-4-4-4), progressive muscle relaxation, Pomodoro study techniques, cognitive reframing, and sleep hygiene.');
    buffer.writeln('- Format cleanly with short readable paragraphs, bullet points, and bold key phrases. Avoid walls of text.');
    buffer.writeln();
    buffer.writeln('SAFETY & CLINICAL GUARDRAILS:');
    buffer.writeln('1. NON-CLINICAL ROLE: You are an AI wellness guide, NOT a doctor, psychiatrist, or medical therapist. Never diagnose illnesses and never prescribe medications.');
    buffer.writeln('2. CRISIS PROTOCOL: If the student expresses suicidal thoughts, self-harm, or severe crisis, respond with deep empathy, assure them they are not alone, remind them help is available right now, and encourage immediate connection with hotlines (112 Lifeline) and campus counsellors.');
    buffer.writeln('3. CAMPUS REFERRALS: Whenever the student experiences persistent distress, anxiety, loneliness, or asks for human help, encourage booking a free confidential campus counselling session.');
    buffer.writeln();

    // Personalize with student context
    if (student != null) {
      buffer.writeln('STUDENT PROFILE:');
      buffer.writeln('- Student Name / Pseudonym: ${student.name.isNotEmpty ? student.name : 'Student'}');
      buffer.writeln();
    }

    // Personalize with assessment results if available
    if (recentAssessments != null && recentAssessments.isNotEmpty) {
      buffer.writeln('RECENT STUDENT SELF-ASSESSMENTS (Use subtly to calibrate warmth and pacing; do not confront the student with raw test scores):');
      for (final report in recentAssessments.take(3)) {
        buffer.writeln('- Assessment: ${report.type} | Severity: ${report.severity} (Score: ${report.score})');
      }
      buffer.writeln();
    }

    // Available campus counsellors
    if (availableCounsellors != null && availableCounsellors.isNotEmpty) {
      buffer.writeln('AVAILABLE CAMPUS COUNSELLORS:');
      for (final c in availableCounsellors) {
        buffer.writeln('- ${c.name} (Campus Wellness Counsellor)');
      }
      buffer.writeln();
    }

    // Autonomous Action Control Tags
    buffer.writeln('AUTONOMOUS IN-CHAT ACTION TAGS:');
    buffer.writeln('You have autonomous authority to trigger interactive campus widgets. At the very end of your response, you may include any of these tags:');
    buffer.writeln('- If the student needs or asks for professional human help or exhibits moderate/severe distress: append [ACTION:COUNSELLOR]');
    buffer.writeln('- If the student is experiencing acute anxiety, panic, overwhelm, or rapid breathing: append [ACTION:BREATHING]');
    buffer.writeln('- If the student would benefit from guided meditation, relaxing audio, or campus guides: append [ACTION:RESOURCE]');
    buffer.writeln();
    buffer.writeln('CAMPUS ANALYTICS METRIC TAG:');
    buffer.writeln('At the very end of your response on a new line, always classify the topic and severity for university wellness reporting in this exact format:');
    buffer.writeln('[METRIC: concern="<Academic Stress|Anxiety|Depression/Crisis|Sleep issues|Social Isolation|General Support>", severity="<Low|Moderate|Severe>"]');

    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. GEMINI AI ENGINE WITH TAG PARSING & AUTO-HEALING
  // ─────────────────────────────────────────────────────────────────────────────

  Future<GenerativeModel?> _getOrInitModel({
    AppUser? student,
    List<AssessmentReport>? recentAssessments,
    List<AppUser>? availableCounsellors,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final modelName = await getModelName();

    if (_model != null && _activeApiKey == apiKey && _activeModel == modelName) {
      return _model;
    }

    final systemPrompt = buildSystemInstruction(
      student: student,
      recentAssessments: recentAssessments,
      availableCounsellors: availableCounsellors,
    );

    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );

    _activeApiKey = apiKey;
    _activeModel = modelName;
    _chatSession = null;

    return _model;
  }

  Future<void> startNewChat({
    AppUser? student,
    List<AssessmentReport>? recentAssessments,
    List<AppUser>? availableCounsellors,
  }) async {
    final model = await _getOrInitModel(
      student: student,
      recentAssessments: recentAssessments,
      availableCounsellors: availableCounsellors,
    );
    if (model != null) {
      _chatSession = model.startChat();
    } else {
      _chatSession = null;
    }
  }

  /// Sends a message and returns a rich [GeminiChatResult].
  /// Explicitly reports whether the response came from live AI or offline fallback.
  Future<GeminiChatResult> sendMessageDetailed({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
    AppUser? student,
    List<AssessmentReport>? recentAssessments,
    List<AppUser>? availableCounsellors,
  }) async {
    final isCrisisImmediate = detectImmediateCrisis(message);
    final fallbackAnalysis = analyzeDistress(
      message: message,
      counsellors: availableCounsellors,
    );

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      final reply = generateLocalFallback(
        message: message,
        student: student,
        recentAssessments: recentAssessments,
        availableCounsellors: availableCounsellors,
      );
      return GeminiChatResult(
        text: reply,
        isFromAI: false,
        errorMessage: 'Gemini API key is not configured. Running in offline rule-based mode.',
        concern: fallbackAnalysis.concern,
        severity: fallbackAnalysis.severity,
        shouldSuggestCounsellor: fallbackAnalysis.shouldSuggestCounsellor,
        matchedCounsellorId: fallbackAnalysis.matchedCounsellorId,
        shouldSuggestBreathing: fallbackAnalysis.concern == 'Anxiety',
        shouldSuggestResource: message.toLowerCase().contains('guide') || message.toLowerCase().contains('meditation'),
        isCrisis: isCrisisImmediate,
      );
    }

    try {
      final model = await _getOrInitModel(
        student: student,
        recentAssessments: recentAssessments,
        availableCounsellors: availableCounsellors,
      );

      if (model != null) {
        if (_chatSession == null) {
          final historyContents = <Content>[];
          for (final msg in conversationHistory) {
            final text = msg['text'] as String? ?? '';
            final isUser = msg['isUser'] as bool? ?? false;
            if (text.isNotEmpty) {
              if (isUser) {
                historyContents.add(Content.text(text));
              } else {
                historyContents.add(Content.model([TextPart(text)]));
              }
            }
          }
          _chatSession = model.startChat(history: historyContents);
        }

        final response = await _chatSession!.sendMessage(Content.text(message));
        final rawResponse = response.text?.trim() ?? '';

        if (rawResponse.isNotEmpty) {
          final bool suggestCounsellor = rawResponse.contains('[ACTION:COUNSELLOR]') || fallbackAnalysis.shouldSuggestCounsellor;
          final bool suggestBreathing = rawResponse.contains('[ACTION:BREATHING]');
          final bool suggestResource = rawResponse.contains('[ACTION:RESOURCE]');

          String detectedConcern = fallbackAnalysis.concern;
          String detectedSeverity = fallbackAnalysis.severity;

          final metricMatch = RegExp(r'\[METRIC:\s*concern="([^"]+)",\s*severity="([^"]+)"\]').firstMatch(rawResponse);
          if (metricMatch != null) {
            final c = metricMatch.group(1);
            final s = metricMatch.group(2);
            if (c != null && c.isNotEmpty) detectedConcern = c;
            if (s != null && s.isNotEmpty) detectedSeverity = s;
          }

          final cleanText = rawResponse
              .replaceAll(RegExp(r'\[ACTION:[^\]]+\]'), '')
              .replaceAll(RegExp(r'\[METRIC:[^\]]+\]'), '')
              .trim();

          String? counsellorId = fallbackAnalysis.matchedCounsellorId;
          if (suggestCounsellor && counsellorId == null && availableCounsellors != null && availableCounsellors.isNotEmpty) {
            counsellorId = availableCounsellors.first.uid;
          }

          return GeminiChatResult(
            text: cleanText,
            isFromAI: true,
            concern: isCrisisImmediate ? 'Depression/Crisis' : detectedConcern,
            severity: isCrisisImmediate ? 'Severe' : detectedSeverity,
            shouldSuggestCounsellor: suggestCounsellor || isCrisisImmediate,
            matchedCounsellorId: counsellorId,
            shouldSuggestBreathing: suggestBreathing,
            shouldSuggestResource: suggestResource,
            isCrisis: isCrisisImmediate,
          );
        }
      }
    } catch (e) {
      debugPrint('Gemini API call failed: $e');
      String errorMsg = e.toString();

      // Auto-healing: If model was not found (404), migrate to an alternative supported model and retry once!
      if (errorMsg.contains('404') || errorMsg.contains('not found')) {
        final current = await getModelName();
        final altModel = current == 'gemini-3.5-flash-lite' ? 'gemini-3.8-flash' : 'gemini-3.5-flash-lite';
        await setModelName(altModel);
        try {
          final fallbackModel = await _getOrInitModel(
            student: student,
            recentAssessments: recentAssessments,
            availableCounsellors: availableCounsellors,
          );
          if (fallbackModel != null) {
            _chatSession = fallbackModel.startChat();
            final retryResponse = await _chatSession!.sendMessage(Content.text(message));
            final retryText = retryResponse.text?.trim() ?? '';
            if (retryText.isNotEmpty) {
              return GeminiChatResult(
                text: retryText.replaceAll(RegExp(r'\[ACTION:[^\]]+\]'), '').replaceAll(RegExp(r'\[METRIC:[^\]]+\]'), '').trim(),
                isFromAI: true,
                concern: fallbackAnalysis.concern,
                severity: fallbackAnalysis.severity,
                shouldSuggestCounsellor: fallbackAnalysis.shouldSuggestCounsellor,
                matchedCounsellorId: fallbackAnalysis.matchedCounsellorId,
                shouldSuggestBreathing: false,
                shouldSuggestResource: false,
                isCrisis: isCrisisImmediate,
              );
            }
          }
        } catch (_) {}
      }

      if (errorMsg.contains('API_KEY_INVALID')) {
        errorMsg = 'Invalid Gemini API key. Please check your key in Settings.';
      } else if (errorMsg.contains('quota') || errorMsg.contains('429')) {
        errorMsg = 'Gemini free-tier rate limit reached. Using offline fallback.';
      } else if (errorMsg.contains('SAFETY')) {
        errorMsg = 'AI safety response filter triggered. Using safe clinical response.';
      }

      final fallbackReply = generateLocalFallback(
        message: message,
        student: student,
        recentAssessments: recentAssessments,
        availableCounsellors: availableCounsellors,
      );

      return GeminiChatResult(
        text: fallbackReply,
        isFromAI: false,
        errorMessage: errorMsg,
        concern: fallbackAnalysis.concern,
        severity: fallbackAnalysis.severity,
        shouldSuggestCounsellor: fallbackAnalysis.shouldSuggestCounsellor,
        matchedCounsellorId: fallbackAnalysis.matchedCounsellorId,
        shouldSuggestBreathing: fallbackAnalysis.concern == 'Anxiety',
        shouldSuggestResource: false,
        isCrisis: isCrisisImmediate,
      );
    }

    final defaultReply = generateLocalFallback(
      message: message,
      student: student,
      recentAssessments: recentAssessments,
      availableCounsellors: availableCounsellors,
    );
    return GeminiChatResult(
      text: defaultReply,
      isFromAI: false,
      concern: fallbackAnalysis.concern,
      severity: fallbackAnalysis.severity,
      shouldSuggestCounsellor: fallbackAnalysis.shouldSuggestCounsellor,
      matchedCounsellorId: fallbackAnalysis.matchedCounsellorId,
      shouldSuggestBreathing: false,
      shouldSuggestResource: false,
      isCrisis: isCrisisImmediate,
    );
  }

  /// Backward-compatible string-returning helper
  Future<String> sendMessage({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
    AppUser? student,
    List<AssessmentReport>? recentAssessments,
    List<AppUser>? availableCounsellors,
  }) async {
    final result = await sendMessageDetailed(
      message: message,
      conversationHistory: conversationHistory,
      student: student,
      recentAssessments: recentAssessments,
      availableCounsellors: availableCounsellors,
    );
    return result.text;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. EMPATHETIC LOCAL FALLBACK ENGINE (Used Only When Offline Or No Key)
  // ─────────────────────────────────────────────────────────────────────────────

  String generateLocalFallback({
    required String message,
    AppUser? student,
    List<AssessmentReport>? recentAssessments,
    List<AppUser>? availableCounsellors,
  }) {
    final lower = message.toLowerCase();
    final studentName = (student?.name.isNotEmpty ?? false) ? student!.name : 'friend';
    final counsellorName = (availableCounsellors != null && availableCounsellors.isNotEmpty)
        ? availableCounsellors.first.name
        : 'our campus wellness team';

    // Crisis
    if (detectImmediateCrisis(message)) {
      return _generateCrisisResponse(availableCounsellors);
    }

    // Direct request to talk to counsellor
    if (lower.contains('counsellor') ||
        lower.contains('counselor') ||
        lower.contains('therapist') ||
        lower.contains('appointment') ||
        lower.contains('book')) {
      return "I would be glad to help you connect with human support! Speaking with a counsellor is completely free, safe, and confidential. \n\n"
          "You can connect directly with **$counsellorName** or choose another team member. "
          "You can also choose to keep the booking completely anonymous if you prefer privacy. "
          "Tap the **Book Counsellor** card below to reserve a session.";
    }

    // Academic Stress / Exams
    if (lower.contains('exam') ||
        lower.contains('study') ||
        lower.contains('assignment') ||
        lower.contains('grade') ||
        lower.contains('test') ||
        lower.contains('fail') ||
        lower.contains('deadline') ||
        lower.contains('overwhelm')) {
      return "Academic pressure can feel overwhelmingly heavy, $studentName. Please remember that your grades and deadlines do not define your inherent worth as a person.\n\n"
          "Here is a 3-step action plan to regain clarity right now:\n"
          "1. **Breathe & Pause**: Put your pen or keyboard down, close your eyes, and take three slow, deep breaths.\n"
          "2. **The 25-Minute Rule (Pomodoro)**: Pick just ONE small chunk of your task. Commit to working on it for only 25 minutes, then take a full 5-minute break.\n"
          "3. **Brain Dump**: Write down everything swirling in your mind onto a piece of paper to take it out of your head.\n\n"
          "Would you like to try a 1-minute box breathing exercise together, or would you like me to guide you through another coping technique?";
    }

    // Anxiety & Panic
    if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('panic') ||
        lower.contains('fear') ||
        lower.contains('worry') ||
        lower.contains('racing') ||
        lower.contains('scared')) {
      return "I hear how uncomfortable and intense that anxiety feels right now. Anxiety is your nervous system's alarm going off, but you are safe in this moment.\n\n"
          "Let's ground your body using the **5-4-3-2-1 Sensory Technique**:\n"
          "• **5 things you can see**: Look around the room and name 5 distinct objects.\n"
          "• **4 things you can physically feel**: Notice your feet on the floor, your back against the chair, or the fabric of your sleeve.\n"
          "• **3 things you can hear**: Listen for the hum of a fan, birds outside, or distant footsteps.\n"
          "• **2 things you can smell**: Notice any scent in the air or on your wrists.\n"
          "• **1 thing you can taste**: Sip a glass of cold water.\n\n"
          "Feel free to tap the **Box Breathing** tool below whenever you need to steady your rhythm.";
    }

    // Sleep issues / Insomnia
    if (lower.contains('sleep') ||
        lower.contains('insomnia') ||
        lower.contains('tired') ||
        lower.contains('awake') ||
        lower.contains('night')) {
      return "Struggling to sleep is exhausting, and it has an immediate impact on emotional well-being. Let's try to reset your body's relaxation response:\n\n"
          "• **The 20-Minute Rule**: If you have been tossing and turning for more than 20 minutes, gently get out of bed. Sit in dim light and do something calming (like reading a physical book) until you feel drowsy.\n"
          "• **4-7-8 Breathing**: Inhale silently through your nose for 4 seconds, gently hold for 7 seconds, and exhale slowly through your mouth for 8 seconds. Repeat 4 times.\n"
          "• **Screen Curfew**: Blue light signals your brain that it's daytime. Dim your phone screen and try placing it out of arm's reach.\n\n"
          "You can also explore relaxing audio tracks in our campus **Resource Hub**.";
    }

    // Loneliness / Social Isolation
    if (lower.contains('lonely') ||
        lower.contains('alone') ||
        lower.contains('friend') ||
        lower.contains('isolate') ||
        lower.contains('nobody')) {
      return "Feeling lonely or disconnected at university is painful, but you are far from alone in feeling this way. So many students feel isolated while pretending everything is fine on the surface.\n\n"
          "Some gentle steps to consider today:\n"
          "• **Micro-connections**: Simply studying in a shared space like the campus library or coffee shop can provide gentle social energy without pressure to perform.\n"
          "• **Anonymous Peer Forum**: Check out our CareCampus Peer Forum where fellow students share their experiences anonymously.\n"
          "• **Reach out**: Send a simple low-stakes text to someone you haven't spoken to in a while, or speak with **$counsellorName**.";
    }

    // Depression / Sadness / Low Mood
    if (lower.contains('depressed') ||
        lower.contains('depression') ||
        lower.contains('sad') ||
        lower.contains('empty') ||
        lower.contains('cry') ||
        lower.contains('hopeless') ||
        lower.contains('exhausted')) {
      return "Thank you for trusting me with how you are feeling, $studentName. When you're feeling down or empty, even getting out of bed or replying to a message can take monumental effort.\n\n"
          "Please be gentle with yourself today. You don't have to fix everything all at once. What is one tiny act of self-care you can offer yourself right now? For example:\n"
          "• Drinking a cold glass of water\n"
          "• Stepping outside for 3 minutes of fresh air\n"
          "• Wrapping yourself in a warm blanket\n\n"
          "If this feeling has been sticking around for more than two weeks, I strongly encourage booking a chat with **$counsellorName**. You don't have to carry this alone.";
    }

    // Default welcoming response
    return "Thank you for sharing that with me. It sounds like you are carrying a lot on your mind right now. \n\n"
        "I'm here to listen and support you. To help us work through this together, what feels like the heaviest part of your day right now? (For example: academic deadlines, anxiety, sleep trouble, or feeling alone?)";
  }

  String _generateCrisisResponse(List<AppUser>? counsellors) {
    final counsellorName = (counsellors != null && counsellors.isNotEmpty)
        ? counsellors.first.name
        : 'our campus wellness team';

    return "### ⚠️ I hear how deeply you are hurting, and you are not alone.\n\n"
        "I am an AI companion, but your life is precious and there are caring professionals ready to support you right this second without judgment.\n\n"
        "**Immediate 24/7 Free Support Hotlines:**\n"
        "• **112 Emergency & Crisis Lifeline**: Dial **112** (Free, confidential, 24/7)\n"
        "• **Tele-MANAS**: Dial **14416** (National toll-free helpline)\n"
        "• **Crisis Text Line**: Text **HOME** to **741741**\n"
        "• **Campus Emergency Security**: Call your campus security or **911**\n\n"
        "Please connect with **$counsellorName** or one of our campus counsellors immediately. "
        "You can tap the **'Book Anonymous Appointment Now'** button below to schedule an urgent confidential session with complete privacy.";
  }
}
