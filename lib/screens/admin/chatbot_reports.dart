import 'package:flutter/material.dart';
import '../../models/chatbot_session_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';

class ChatbotReports extends StatefulWidget {
  const ChatbotReports({super.key});

  @override
  State<ChatbotReports> createState() => _ChatbotReportsState();
}

class _ChatbotReportsState extends State<ChatbotReports> {
  List<ChatbotSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionsData();
  }

  Future<void> _loadSessionsData() async {
    try {
      final list = await Services.db.getChatbotSessions();
      setState(() {
        _sessions = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary)),
      );
    }

    final total = _sessions.length;
    final severeCount = _sessions.where((s) => s.severity == 'Severe').length;
    final moderateCount = _sessions.where((s) => s.severity == 'Moderate').length;
    
    // Count topic occurrences
    final Map<String, int> topicCounts = {
      'Academic Stress': 0,
      'Anxiety': 0,
      'Depression/Crisis': 0,
      'Sleep issues': 0,
      'Social Isolation': 0,
      'General Support': 0,
    };

    for (var session in _sessions) {
      final concern = session.concern;
      if (topicCounts.containsKey(concern)) {
        topicCounts[concern] = topicCounts[concern]! + 1;
      } else {
        topicCounts['General Support'] = (topicCounts['General Support'] ?? 0) + 1;
      }
    }

    final sortedTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot Usage Reports'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Conversation Analytics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isDesktop ? 28 : 22,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Monitor chatbot interactions to identify general campus worries and crisis escalation rates.',
                style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Responsive KPI Count Boxes (Row on Desktop, Column on Mobile to prevent overflow)
              if (isDesktop)
                Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        'Total Conversations',
                        total.toString(),
                        Icons.chat_bubble_outline_rounded,
                        AppTheme.tealPrimary,
                        isMobile: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _kpiCard(
                        'Severe Escalations',
                        severeCount.toString(),
                        Icons.crisis_alert_rounded,
                        AppTheme.alertSevere,
                        isMobile: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _kpiCard(
                        'Moderate Indicators',
                        moderateCount.toString(),
                        Icons.warning_amber_rounded,
                        AppTheme.alertWarning,
                        isMobile: false,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _kpiCard(
                      'Total Conversations',
                      total.toString(),
                      Icons.chat_bubble_outline_rounded,
                      AppTheme.tealPrimary,
                      isMobile: true,
                    ),
                    const SizedBox(height: 12),
                    _kpiCard(
                      'Severe Escalations',
                      severeCount.toString(),
                      Icons.crisis_alert_rounded,
                      AppTheme.alertSevere,
                      isMobile: true,
                    ),
                    const SizedBox(height: 12),
                    _kpiCard(
                      'Moderate Indicators',
                      moderateCount.toString(),
                      Icons.warning_amber_rounded,
                      AppTheme.alertWarning,
                      isMobile: true,
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildTopicsList(sortedTopics, total, isDesktop)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildEscalationOverview(total, severeCount, isDesktop)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildTopicsList(sortedTopics, total, isDesktop),
                        const SizedBox(height: 20),
                        _buildEscalationOverview(total, severeCount, isDesktop),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, {required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 14 : 20),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 22 : 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLow),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopicsList(List<MapEntry<String, int>> topics, int totalCount, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Student Concerns',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.mintAccent,
              fontSize: isDesktop ? 20 : 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Frequency breakdown based on topics flagged by chatbot local natural language analysis.',
            style: TextStyle(color: AppTheme.textLow, fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          ...topics.map((entry) {
            final double percent = totalCount > 0 ? (entry.value / totalCount) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value} (${(percent * 100).toStringAsFixed(1)}%)', 
                        style: const TextStyle(color: AppTheme.textLow, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.tealPrimary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEscalationOverview(int total, int severe, bool isDesktop) {
    final double rate = total > 0 ? (severe / total) * 100 : 0.0;
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinical Escalation Rate',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: isDesktop ? 20 : 16,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: isDesktop ? 140 : 120,
              height: isDesktop ? 140 : 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: total > 0 ? severe / total : 0,
                    strokeWidth: isDesktop ? 12 : 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.alertSevere),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${rate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: isDesktop ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.alertSevere,
                          ),
                        ),
                        const Text(
                          'Crisis Rate',
                          style: TextStyle(fontSize: 10, color: AppTheme.textLow, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Crisis rate measures the percentage of user interactions that trigger suicidal, self-harm, or severe depression alerts requiring professional human counsellor referrals.',
            style: TextStyle(color: AppTheme.textMedium, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
