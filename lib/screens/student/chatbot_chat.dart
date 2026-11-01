import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../../models/chatbot_session_model.dart';
import '../../models/user_model.dart';
import '../../models/assessment_model.dart';
import '../../models/resource_model.dart';
import '../../services/services.dart';
import '../../services/gemini_service.dart';
import '../../utils/theme.dart';
import '../../utils/security.dart';
import 'book_counsellor.dart';

class ChatbotChat extends StatefulWidget {
  const ChatbotChat({super.key});

  @override
  State<ChatbotChat> createState() => _ChatbotChatState();
}

class _ChatbotChatState extends State<ChatbotChat> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _severityFlagged = false;
  bool _hasApiKey = false;
  String _activeModel = 'gemini-3.5-flash-lite';
  String _detectedConcern = 'General Support';
  String _detectedSeverity = 'Low';
  String? _lastErrorNotice;

  AppUser? _currentUser;
  List<AssessmentReport> _recentAssessments = [];
  List<AppUser> _counsellors = [];
  List<Resource> _resources = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final hasKey = await _gemini.hasApiKey();
    final modelName = await _gemini.getModelName();

    try {
      final user = await Services.auth.getCurrentUser();
      List<AssessmentReport> assessments = [];
      List<AppUser> counsellors = [];
      List<Resource> resources = [];

      try {
        assessments = await Services.db.getAssessmentReports();
        if (user != null) {
          assessments = assessments.where((a) => a.studentId == user.uid).toList();
        }
      } catch (_) {}

      try {
        counsellors = await Services.db.getCounsellors();
      } catch (_) {}

      try {
        resources = await Services.db.getResources();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _hasApiKey = hasKey;
          _activeModel = modelName;
          _currentUser = user;
          _recentAssessments = assessments;
          _counsellors = counsellors;
          _resources = resources;
        });

        await _gemini.startNewChat(
          student: user,
          recentAssessments: assessments,
          availableCounsellors: counsellors,
        );

        final studentName = user != null && user.name.isNotEmpty ? user.name : 'there';
        _messages.add({
          'text': "Hello $studentName! I am your CareCampus Wellness Companion, powered by Google Gemini AI. "
              "I'm here to listen, offer personalized coping exercises, guide breathing, or help you connect with campus support. "
              "How are you feeling today?",
          'isUser': false,
          'isFromAI': hasKey,
          'timestamp': DateTime.now(),
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasApiKey = hasKey;
          _activeModel = modelName;
        });
        _messages.add({
          'text': "Hello! I am your CareCampus Wellness Companion. I'm here to listen, offer coping strategies, and suggest mindfulness guides. What is on your mind today?",
          'isUser': false,
          'isFromAI': false,
          'timestamp': DateTime.now(),
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? prefilledText]) async {
    final text = prefilledText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (prefilledText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
      _lastErrorNotice = null;
    });
    _scrollToBottom();

    final result = await _gemini.sendMessageDetailed(
      message: text,
      conversationHistory: _messages,
      student: _currentUser,
      recentAssessments: _recentAssessments,
      availableCounsellors: _counsellors,
    );

    _detectedConcern = result.concern;
    if (result.severity == 'Severe' || result.isCrisis) {
      _detectedSeverity = 'Severe';
      _severityFlagged = true;
    } else if (result.severity == 'Moderate' && _detectedSeverity != 'Severe') {
      _detectedSeverity = 'Moderate';
    }

    AppUser? suggestedCounsellor;
    if (result.shouldSuggestCounsellor && _counsellors.isNotEmpty) {
      if (result.matchedCounsellorId != null) {
        suggestedCounsellor = _counsellors.firstWhere(
          (c) => c.uid == result.matchedCounsellorId,
          orElse: () => _counsellors.first,
        );
      } else {
        suggestedCounsellor = _counsellors.first;
      }
    }

    Resource? suggestedResource;
    if (result.shouldSuggestResource && _resources.isNotEmpty) {
      suggestedResource = _resources.first;
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _lastErrorNotice = result.errorMessage;
        _messages.add({
          'text': result.text,
          'isUser': false,
          'isFromAI': result.isFromAI,
          'errorMessage': result.errorMessage,
          'timestamp': DateTime.now(),
          'suggestedCounsellor': suggestedCounsellor,
          'suggestedResource': suggestedResource,
          'suggestedBreathing': result.shouldSuggestBreathing,
          'isCrisis': result.isCrisis,
        });
      });
      _scrollToBottom();

      _logSessionMetrics();
    }
  }

  void _logSessionMetrics() async {
    try {
      final student = _currentUser ?? await Services.auth.getCurrentUser();
      if (student == null) return;

      final pName = SecurityUtils.generatePseudonym(student.uid);

      final session = ChatbotSession(
        id: 'chat-${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.uid,
        studentPseudonym: pName,
        concern: _detectedConcern,
        severity: _detectedSeverity,
        createdAt: DateTime.now(),
      );

      await Services.db.logChatbotSession(session);
    } catch (_) {}
  }

  void _navigateToBooking({bool isAnonymous = false, String? counsellorId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookCounsellor(
          isAnonymous: isAnonymous,
          preselectedCounsellorId: counsellorId,
          anonymousAlertReason:
              'AI Chatbot flagged distress: $_detectedConcern ($_detectedSeverity)',
        ),
      ),
    );
  }

  Future<void> _callHelpline(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
      } else {
        throw 'Could not dial $number';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Helpline number: $number. Please dial directly.'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    }
  }

  Future<void> _openResourceUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open resource link: $url'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    }
  }

  void _showBoxBreathingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BoxBreathingModal(),
    );
  }

  void _showSettingsDialog() async {
    final currentKey = await _gemini.getApiKey();
    final currentModel = await _gemini.getModelName();
    if (!mounted) return;

    final controller = TextEditingController(text: currentKey ?? '');
    String selectedModel = currentModel;
    bool obscure = true;
    bool isTesting = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actionsOverflowButtonSpacing: 8,
          actionsOverflowDirection: VerticalDirection.down,
          actionsAlignment: MainAxisAlignment.end,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tealBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.tealBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gemini AI Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyText),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CareCampus uses the free-tier Google Gemini API for real, personalized AI conversations. '
                  'Zero paid services or credit cards required.',
                  style: TextStyle(color: AppTheme.slateText, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Model Selector Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedModel,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Gemini Model (Free Tier)',
                    labelStyle: const TextStyle(fontSize: 12, color: AppTheme.slateText),
                    prefixIcon: const Icon(Icons.bolt_rounded, color: AppTheme.mintGreen, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'gemini-3.5-flash-lite',
                      child: Text(
                        'gemini-3.5-flash-lite (Fast / Lite)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-3.8-flash',
                      child: Text(
                        'gemini-3.8-flash (Standard)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-2.5-flash',
                      child: Text(
                        'gemini-2.5-flash (Legacy)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedModel = val;
                        testResult = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Google AI Studio API Key:',
                  style: TextStyle(color: AppTheme.navyText, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(fontSize: 13, color: AppTheme.navyText),
                  decoration: InputDecoration(
                    hintText: 'Paste AI Studio Key (AIzaSy...)',
                    hintStyle: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Test Connection Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tealBlue,
                      side: const BorderSide(color: AppTheme.tealBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    icon: isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.tealBlue),
                          )
                        : const Icon(Icons.wifi_tethering_rounded, size: 16),
                    label: Text(isTesting ? 'Testing connection...' : 'Test Connection'),
                    onPressed: isTesting
                        ? null
                        : () async {
                            setDialogState(() {
                              isTesting = true;
                              testResult = null;
                            });
                            final err = await _gemini.testConnection(
                              controller.text.trim(),
                              modelName: selectedModel,
                            );
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = err == null;
                              testResult = err == null
                                  ? '✅ Connected! $selectedModel is ready & responding.'
                                  : '❌ $err';
                            });
                          },
                  ),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: testSuccess ? AppTheme.alertSuccess.withValues(alpha: 0.1) : AppTheme.alertSevere.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      testResult!,
                      style: TextStyle(
                        fontSize: 12,
                        color: testSuccess ? AppTheme.alertSuccess : AppTheme.alertSevere,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Get Free Key link
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
                    if (await launcher.canLaunchUrl(uri)) {
                      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.tealBlue),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Get free Gemini API key from Google AI Studio (takes 10 seconds)',
                          style: TextStyle(
                            color: AppTheme.tealBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (currentKey != null && currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _gemini.clearApiKey();
                  if (!mounted) return;
                  setState(() => _hasApiKey = false);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('API Key cleared. Switched to offline mode.')),
                  );
                },
                child: const Text('Clear Key', style: TextStyle(color: AppTheme.alertRed)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final key = controller.text.trim();
                await _gemini.saveApiKey(key);
                await _gemini.setModelName(selectedModel);
                final updatedHasKey = await _gemini.hasApiKey();

                await _gemini.startNewChat(
                  student: _currentUser,
                  recentAssessments: _recentAssessments,
                  availableCounsellors: _counsellors,
                );

                if (!mounted) return;
                setState(() {
                  _hasApiKey = updatedHasKey;
                  _activeModel = selectedModel;
                });
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      key.isNotEmpty
                          ? 'Gemini API key saved! $selectedModel active.'
                          : 'Empty key. Running in offline rule-based mode.',
                    ),
                    backgroundColor: AppTheme.alertSuccess,
                  ),
                );
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _restartChat() {
    setState(() {
      _messages.clear();
      _severityFlagged = false;
      _detectedConcern = 'General Support';
      _detectedSeverity = 'Low';
      _lastErrorNotice = null;
    });
    _gemini.startNewChat(
      student: _currentUser,
      recentAssessments: _recentAssessments,
      availableCounsellors: _counsellors,
    );
    final studentName = _currentUser != null && _currentUser!.name.isNotEmpty ? _currentUser!.name : 'there';
    _messages.add({
      'text': "Chat restarted. Hello $studentName! How can I support your mental wellness right now?",
      'isUser': false,
      'isFromAI': _hasApiKey,
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.skyWhite,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Wellness Companion',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            InkWell(
              onTap: _showSettingsDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _hasApiKey ? AppTheme.mintGreen : AppTheme.alertAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _hasApiKey ? '$_activeModel (Active)' : 'Offline • Tap to Setup',
                      style: TextStyle(
                        fontSize: 11,
                        color: _hasApiKey ? AppTheme.textMedium : AppTheme.alertAmber,
                        fontWeight: _hasApiKey ? FontWeight.normal : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Box Breathing Exercise',
            icon: const Icon(Icons.air_rounded, color: AppTheme.tealBlue, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _showBoxBreathingModal,
          ),
          IconButton(
            tooltip: 'Restart Conversation',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.slateText, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _restartChat,
          ),
          IconButton(
            tooltip: 'Gemini Settings',
            icon: const Icon(Icons.settings_outlined, color: AppTheme.slateText, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: Column(
          children: [
            // ── Prominent AI Activation Banner if No Key is Set ─────────
            if (!_hasApiKey)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Scripts Active',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add your free Gemini API key to unlock unscripted AI.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        elevation: 0,
                      ),
                      onPressed: _showSettingsDialog,
                      child: const Text('Enable AI'),
                    ),
                  ],
                ),
              ),

            // ── Error notification banner if API call failed ─────────────
            if (_lastErrorNotice != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.alertAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.alertAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.alertAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastErrorNotice!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.alertAmber, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: AppTheme.slateText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _lastErrorNotice = null),
                    ),
                  ],
                ),
              ),

            // ── Quick Suggestion Chips ──────────────────────────────────
            _buildQuickSuggestionChips(),

            // ── Severe / Crisis Emergency Action Panel ───────────────────
            if (_severityFlagged) _buildCrisisEmergencyBanner(),

            // ── Message History ──────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final isFromAI = msg['isFromAI'] as bool? ?? false;
                  final suggestedCounsellor = msg['suggestedCounsellor'] as AppUser?;
                  final suggestedResource = msg['suggestedResource'] as Resource?;
                  final suggestedBreathing = msg['suggestedBreathing'] as bool? ?? false;
                  final isCrisis = msg['isCrisis'] as bool? ?? false;

                  return Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.84,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppTheme.tealBlue.withValues(alpha: 0.15)
                                : (isCrisis
                                    ? AppTheme.alertSevere.withValues(alpha: 0.12)
                                    : AppTheme.slateCard.withValues(alpha: 0.9)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: Border.all(
                              color: isUser
                                  ? AppTheme.tealBlue.withValues(alpha: 0.3)
                                  : (isCrisis
                                      ? AppTheme.alertSevere.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.12)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] as String,
                                style: TextStyle(
                                  color: AppTheme.navyText,
                                  height: 1.45,
                                  fontSize: 14,
                                  fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              if (!isUser) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFromAI ? Icons.auto_awesome : Icons.code_rounded,
                                      size: 11,
                                      color: isFromAI ? AppTheme.tealBlue : AppTheme.mutedText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isFromAI ? _activeModel : 'Offline Script',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isFromAI ? AppTheme.tealBlue : AppTheme.mutedText,
                                        fontWeight: isFromAI ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      if (suggestedBreathing) ...[
                        InkWell(
                          onTap: _showBoxBreathingModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.tealBlue.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.tealBlue.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.air_rounded, color: AppTheme.tealBlue, size: 18),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '🌬️ Guided Box Breathing (4-4-4-4)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyText),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (suggestedCounsellor != null) ...[
                        _buildCounsellorCard(suggestedCounsellor),
                        const SizedBox(height: 8),
                      ],

                      if (suggestedResource != null) ...[
                        _buildResourceCard(suggestedResource),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ),

            // ── Typing Indicator ─────────────────────────────────────────
            if (_isTyping) ...[
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.tealBlue),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _hasApiKey ? '$_activeModel is personalizing...' : 'Companion is typing...',
                        style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Message Input Bar ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.white.withValues(alpha: 0.9),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(color: AppTheme.navyText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Share what is on your mind...',
                        hintStyle: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: AppTheme.skyWhite,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.iceBlue.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppTheme.iceBlue.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.tealBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.tealBlue,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildQuickSuggestionChips() {
    final chips = [
      {'label': '🌬️ Box Breathing', 'action': () => _showBoxBreathingModal()},
      {'label': '📝 Exam Stress', 'text': 'I am overwhelmed by my exams and deadlines.'},
      {'label': '🛑 Grounding (5-4-3-2-1)', 'text': 'Can you guide me through a 5-4-3-2-1 grounding exercise?'},
      {'label': '🌙 Sleep Tips', 'text': 'I am having a hard time falling asleep.'},
      {'label': '🤝 Talk to a Counsellor', 'text': 'Can you tell me how to book a session with a campus counsellor?'},
      {'label': '📚 Wellness Resources', 'text': 'What relaxation guides or meditations are available?'},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = chips[index];
          final label = item['label'] as String;
          return ActionChip(
            label: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.navyText)),
            backgroundColor: AppTheme.white.withValues(alpha: 0.8),
            side: BorderSide(color: AppTheme.iceBlue.withValues(alpha: 0.8)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () {
              if (item['action'] != null) {
                (item['action'] as VoidCallback)();
              } else if (item['text'] != null) {
                _sendMessage(item['text'] as String);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildCrisisEmergencyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.alertSevere.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.alertSevere.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.alertSevere.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.crisis_alert_rounded, color: AppTheme.alertSevere, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Immediate Support: You are not alone.',
                  style: TextStyle(color: AppTheme.alertSevere, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertSevere,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
            label: const Text('Call 112 Lifeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _callHelpline('112'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.tealBlue,
              side: const BorderSide(color: AppTheme.tealBlue),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text(
              'Book Counsellor Appointment',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => _navigateToBooking(isAnonymous: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCounsellorCard(AppUser counsellor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.tealBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.tealBlue.withValues(alpha: 0.15),
            radius: 20,
            child: const Icon(Icons.medical_services_rounded, color: AppTheme.tealBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  counsellor.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Campus Wellness Counsellor • Free & Confidential',
                  style: TextStyle(fontSize: 11, color: AppTheme.slateText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _navigateToBooking(counsellorId: counsellor.uid),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mintGreen.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.mintGreen.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(
              resource.category == 'Audio' ? Icons.headset_rounded : Icons.library_books_rounded,
              color: AppTheme.mintGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${resource.category} • ${resource.description}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.slateText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.mintGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _openResourceUrl(resource.url),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE BOX BREATHING EXERCISE MODAL
// ─────────────────────────────────────────────────────────────────────────────

class _BoxBreathingModal extends StatefulWidget {
  const _BoxBreathingModal();

  @override
  State<_BoxBreathingModal> createState() => _BoxBreathingModalState();
}

class _BoxBreathingModalState extends State<_BoxBreathingModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _phase = 0; // 0: Inhale (4s), 1: Hold (4s), 2: Exhale (4s), 3: Hold (4s)
  int _secondsLeft = 4;
  Timer? _timer;
  bool _isRunning = true;

  final List<String> _phaseTitles = [
    'Inhale slowly through your nose...',
    'Hold gently...',
    'Exhale slowly through your mouth...',
    'Rest and hold...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startCycle();
  }

  void _startCycle() {
    _controller.forward(from: 0.0);
    _timer?.cancel();
    _secondsLeft = 4;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _phase = (_phase + 1) % 4;
          _secondsLeft = 4;

          if (_phase == 0) {
            _controller.forward(from: 0.0);
          } else if (_phase == 2) {
            _controller.reverse(from: 1.0);
          }
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startCycle();
      } else {
        _timer?.cancel();
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.air_rounded, color: AppTheme.tealBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Box Breathing (4-4-4-4)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navyText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.slateText),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Calms the nervous system, eases panic, and centers your mind.',
                style: TextStyle(color: AppTheme.slateText, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_phase == 0) {
                    scale = 1.0 + (_controller.value * 0.35);
                  } else if (_phase == 1) {
                    scale = 1.35;
                  } else if (_phase == 2) {
                    scale = 1.35 - (_controller.value * 0.35);
                  } else {
                    scale = 1.0;
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tealBlue.withValues(alpha: 0.3),
                            blurRadius: 18 * scale,
                            spreadRadius: 3 * scale,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_secondsLeft',
                          style: GoogleFonts.nunito(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _phaseTitles[_phase],
                  key: ValueKey<int>(_phase),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepTeal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                    label: Text(_isRunning ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 13)),
                    onPressed: _togglePause,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.slateText,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
