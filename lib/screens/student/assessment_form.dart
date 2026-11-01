import 'package:flutter/material.dart';
import '../../models/assessment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/security.dart';
import 'book_counsellor.dart';

class AssessmentForm extends StatefulWidget {
  const AssessmentForm({super.key});

  @override
  State<AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends State<AssessmentForm> {
  String? _selectedTest; // 'PHQ-9' | 'GAD-7' | 'GHQ-12'
  int _currentQuestionIndex = 0;
  final Map<String, int> _answers = {};
  
  bool _isFinished = false;
  int _calculatedScore = 0;
  String _calculatedSeverity = 'Minimal';
  String _recommendation = '';

  // Questions Database
  final List<String> _phq9Questions = [
    'Little interest or pleasure in doing things.',
    'Feeling down, depressed, or hopeless.',
    'Trouble falling or staying asleep, or sleeping too much.',
    'Feeling tired or having little energy.',
    'Poor appetite or overeating.',
    'Feeling bad about yourself - or that you are a failure or have let yourself or your family down.',
    'Trouble concentrating on things, such as reading the newspaper or watching television.',
    'Moving or speaking so slowly that other people could have noticed? Or the opposite - being so fidgety or restless that you have been moving around a lot more than usual.',
    'Thoughts that you would be better off dead or of hurting yourself in some way.',
  ];

  final List<String> _gad7Questions = [
    'Feeling nervous, anxious, or on edge.',
    'Not being able to stop or control worrying.',
    'Worrying too much about different things.',
    'Trouble relaxing.',
    'Being so restless that it is hard to sit still.',
    'Becoming easily annoyed or irritable.',
    'Feeling afraid as if something awful might happen.',
  ];

  final List<String> _ghq12Questions = [
    'Been able to concentrate on whatever you\'re doing?',
    'Lost much sleep over worry?',
    'Felt you were playing a useful part in things?',
    'Felt capable of making decisions about things?',
    'Felt constantly under strain?',
    'Felt you couldn\'t overcome your difficulties?',
    'Been able to enjoy your normal day-to-day activities?',
    'Been able to face up to your problems?',
    'Been feeling unhappy and depressed?',
    'Been losing confidence in yourself?',
    'Been thinking of yourself as a worthless person?',
    'Been feeling reasonably happy, all things considered?',
  ];

  final List<String> _phqGadOptions = [
    'Not at all',
    'Several days',
    'More than half the days',
    'Nearly every day',
  ];

  final List<String> _ghqOptions = [
    'Better than usual',
    'Same as usual',
    'Less than usual',
    'Much less than usual',
  ];

  void _selectTest(String testType) {
    setState(() {
      _selectedTest = testType;
      _currentQuestionIndex = 0;
      _answers.clear();
      _isFinished = false;
    });
  }

  List<String> get _currentQuestions {
    if (_selectedTest == 'PHQ-9') return _phq9Questions;
    if (_selectedTest == 'GAD-7') return _gad7Questions;
    if (_selectedTest == 'GHQ-12') return _ghq12Questions;
    return [];
  }

  List<String> get _currentOptions {
    if (_selectedTest == 'GHQ-12') return _ghqOptions;
    return _phqGadOptions;
  }

  void _answerQuestion(int score) {
    _answers['q$_currentQuestionIndex'] = score;

    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateResults();
    }
  }

  void _goBack() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _calculateResults() async {
    int total = 0;
    _answers.forEach((k, v) => total += v);
    _calculatedScore = total;

    String severity = 'Minimal';
    String rec = '';

    if (_selectedTest == 'PHQ-9') {
      if (total >= 20) {
        severity = 'Severe';
        rec = 'Your responses indicate symptoms of severe clinical depression. We strongly urge you to book an immediate, confidential counselling session with a therapist.';
      } else if (total >= 15) {
        severity = 'Moderately Severe';
        rec = 'Your responses suggest moderately severe depression. It is highly recommended to seek professional counselling support to discuss coping methods.';
      } else if (total >= 10) {
        severity = 'Moderate';
        rec = 'Your score indicates moderate depression. Consider scheduling a session with our counselling team to learn anxiety/stress management tools.';
      } else if (total >= 5) {
        severity = 'Mild';
        rec = 'Your score indicates mild depression. Engaging with our Resource Hub guides and taking regular study breaks might help you feel better.';
      } else {
        severity = 'Minimal';
        rec = 'Your score indicates minimal to no depressive symptoms. Keep up your healthy lifestyle routines!';
      }
    } else if (_selectedTest == 'GAD-7') {
      if (total >= 15) {
        severity = 'Severe';
        rec = 'Your score shows severe anxiety. We recommend setting up an offline therapy session to help you establish grounding and recovery techniques.';
      } else if (total >= 10) {
        severity = 'Moderate';
        rec = 'You are showing signs of moderate anxiety. Connecting with a campus counsellor can help you learn to navigate overwhelming academic pressures.';
      } else if (total >= 5) {
        severity = 'Mild';
        rec = 'You are experiencing mild anxiety. Try using the guided box breathing and relaxation audios in our Resource Hub.';
      } else {
        severity = 'Minimal';
        rec = 'Your anxiety level is minimal. You are doing well!';
      }
    } else if (_selectedTest == 'GHQ-12') {
      // General Health Questionnaire (0-36 range)
      if (total >= 28) {
        severity = 'Severe';
        rec = 'Your General Health score shows a high level of distress. We suggest connecting with the counselling team confidential consultation.';
      } else if (total >= 20) {
        severity = 'Moderate';
        rec = 'Your responses indicate moderate psychological distress. A check-in with a campus counsellor could help restore emotional wellness.';
      } else if (total >= 12) {
        severity = 'Mild';
        rec = 'You are showing signs of mild stress. Take time to participate in peer forum topics and practice self-care.';
      } else {
        severity = 'Minimal';
        rec = 'Your general psychological wellness is excellent!';
      }
    }

    _calculatedSeverity = severity;
    _recommendation = rec;

    // Log Assessment report to the database
    try {
      final student = await Services.auth.getCurrentUser();
      if (student != null) {
        final pseudonym = SecurityUtils.generatePseudonym(student.uid);

        final report = AssessmentReport(
          id: 'asmt-${DateTime.now().millisecondsSinceEpoch}',
          studentId: student.uid,
          studentPseudonym: pseudonym,
          type: _selectedTest!,
          score: _calculatedScore,
          severity: _calculatedSeverity,
          answers: Map<String, int>.from(_answers),
          createdAt: DateTime.now(),
        );

        await Services.db.submitAssessmentReport(report);
      }
    } catch (_) {}

    setState(() {
      _isFinished = true;
    });
  }

  void _navigateToBooking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookCounsellor(
          isAnonymous: false,
          anonymousAlertReason: 'Assessment referral: $_selectedTest score $_calculatedScore ($_calculatedSeverity)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _currentQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTest ?? 'Self-Assessments'),
        leading: _selectedTest != null && !_isFinished
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _selectedTest = null;
                  });
                },
              )
            : null,
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _selectedTest == null
              ? _buildSelectionScreen()
              : _isFinished
                  ? _buildResultsScreen()
                  : _buildQuestionScreen(questions),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Self-Assessments',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Select a scientifically validated questionnaire to evaluate your current wellness status. Your responses are stored securely and pseudonymized for campus analysis.',
          style: TextStyle(color: AppTheme.textMedium),
        ),
        const SizedBox(height: 32),
        
        _assessmentCard(
          'PHQ-9 (Depression Screen)',
          'Patient Health Questionnaire: evaluates severity of depressive symptoms over the last two weeks.',
          '9 questions',
          'PHQ-9',
        ),
        const SizedBox(height: 16),
        _assessmentCard(
          'GAD-7 (Anxiety Screen)',
          'Generalized Anxiety Disorder scale: assesses anxiety, worrying, irritability and physiological tension.',
          '7 questions',
          'GAD-7',
        ),
        const SizedBox(height: 16),
        _assessmentCard(
          'GHQ-12 (General Distress)',
          'General Health Questionnaire: measures general psychological wellbeing and social strain.',
          '12 questions',
          'GHQ-12',
        ),
      ],
    );
  }

  Widget _assessmentCard(String title, String desc, String time, String key) {
    return InkWell(
      onTap: () => _selectTest(key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.mintAccent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(color: AppTheme.textMedium, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textLow),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(color: AppTheme.textLow, fontSize: 11, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.tealPrimary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(List<String> questions) {
    final progress = (_currentQuestionIndex + 1) / questions.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linear Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation(AppTheme.tealPrimary),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${questions.length}',
              style: const TextStyle(color: AppTheme.textLow, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (_currentQuestionIndex > 0)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Back'),
                onPressed: _goBack,
              )
          ],
        ),
        const SizedBox(height: 40),

        // Question Card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCardDecoration(isBorderAccent: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Over the last 2 weeks, how often have you been bothered by:',
                style: TextStyle(color: AppTheme.textLow, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Text(
                questions[_currentQuestionIndex],
                style: const TextStyle(
                  color: AppTheme.textHigh,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Selection Options
        ...List.generate(_currentOptions.length, (idx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.slateCard,
                foregroundColor: AppTheme.textHigh,
                padding: const EdgeInsets.all(18),
                alignment: Alignment.centerLeft,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              onPressed: () => _answerQuestion(idx),
              child: Text(_currentOptions[idx]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final bool isSevere = _calculatedSeverity == 'Severe' || 
                         _calculatedSeverity == 'Moderately Severe' || 
                         _calculatedSeverity == 'Moderate';
    
    Color severityColor = AppTheme.alertSuccess;
    if (_calculatedSeverity == 'Moderate') severityColor = AppTheme.alertWarning;
    if (_calculatedSeverity == 'Severe' || _calculatedSeverity == 'Moderately Severe') severityColor = AppTheme.alertSevere;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Result Score Card
        Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassCardDecoration(),
          child: Column(
            children: [
              Text(
                'Assessment Completed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textLow),
              ),
              const SizedBox(height: 16),
              Text(
                '$_calculatedScore',
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: severityColor),
              ),
              Text(
                'Total Score',
                style: TextStyle(color: severityColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _calculatedSeverity.toUpperCase(),
                  style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _recommendation,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textHigh, height: 1.5, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Referral Card if Moderate or Severe
        if (isSevere) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cloudBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.iceBlue),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: AppTheme.tealBlue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Counselling Support Recommended',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.navyText,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your assessment results indicate that speaking with a campus counsellor would be helpful. You can book an appointment directly with our counselling team.',
                  style: TextStyle(color: AppTheme.slateText, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Book Counsellor Appointment'),
                  onPressed: _navigateToBooking,
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedTest = null;
              _isFinished = false;
            });
          },
          child: const Text('Take Another Assessment'),
        ),
      ],
    );
  }
}
