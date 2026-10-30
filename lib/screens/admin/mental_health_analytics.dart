import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/assessment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';

class MentalHealthAnalytics extends StatefulWidget {
  const MentalHealthAnalytics({super.key});

  @override
  State<MentalHealthAnalytics> createState() => _MentalHealthAnalyticsState();
}

class _MentalHealthAnalyticsState extends State<MentalHealthAnalytics> {
  List<AssessmentReport> _reports = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String? _exportPath;

  @override
  void initState() {
    super.initState();
    _loadAssessmentReports();
  }

  Future<void> _loadAssessmentReports() async {
    try {
      final list = await Services.db.getAssessmentReports();
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAnonymizedReport(bool isHighRisk) async {
    setState(() {
      _isExporting = true;
      _exportPath = null;
    });

    try {
      // Build CSV Data
      final buffer = StringBuffer();
      buffer.writeln('REPORT_TYPE,${isHighRisk ? "HIGH_RISK_ALERT_REPORT" : "ROUTINE_ANALYTICS_REPORT"}');
      buffer.writeln('GENERATED_DATE,${DateTime.now().toIso8601String()}');
      buffer.writeln('');
      buffer.writeln('Assessment_ID,Pseudonym,Test_Type,Score,Severity,Submission_Date');
      
      for (var r in _reports) {
        buffer.writeln('${r.id},${r.studentPseudonym},${r.type},${r.score},${r.severity},${r.createdAt.toIso8601String()}');
      }

      // Write to workspace directory
      // Since this runs on Windows, write to the project root
      final file = File('d:\\my_projects\\carecampus\\anonymized_mental_health_report.csv');
      await file.writeAsString(buffer.toString());

      setState(() {
        _exportPath = file.path;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported successfully to: ${file.path}'),
          backgroundColor: AppTheme.alertSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary)),
      );
    }

    final totalAssessments = _reports.length;
    final severeCount = _reports.where((r) => r.severity == 'Severe' || r.severity == 'Moderately Severe').length;
    final double severePercentage = totalAssessments > 0 ? (severeCount / totalAssessments) * 100 : 0.0;
    
    // Check for high-risk trend (e.g. > 30% are Severe/Moderately Severe)
    final bool isHighRiskTrend = severePercentage >= 30.0;

    // Test Type distribution
    final phqCount = _reports.where((r) => r.type == 'PHQ-9').length;
    final gadCount = _reports.where((r) => r.type == 'GAD-7').length;
    final ghqCount = _reports.where((r) => r.type == 'GHQ-12').length;

    // Severity distribution
    final minimal = _reports.where((r) => r.severity == 'Minimal').length;
    final mild = _reports.where((r) => r.severity == 'Mild').length;
    final moderate = _reports.where((r) => r.severity == 'Moderate').length;
    final severe = _reports.where((r) => r.severity == 'Severe' || r.severity == 'Moderately Severe').length;

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Analytics'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Assessment Analytics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Campus-wide psychological test analytics dashboard. Identifies population risk indices and clinical referral ratios.',
                style: TextStyle(color: AppTheme.textMedium),
              ),
              const SizedBox(height: 24),

              // High-Risk Alert Banner
              if (isHighRiskTrend) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.alertSevere.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.alertSevere.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.crisis_alert_rounded, color: AppTheme.alertSevere, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HIGH-RISK TREND DETECTED!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.alertSevere),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Over ${severePercentage.toStringAsFixed(1)}% of self-assessments indicate Moderately Severe or Severe distress. Immediate intervention programs are recommended.',
                              style: const TextStyle(color: AppTheme.textHigh, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Actions and Overview Cards
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildMetricsList(phqCount, gadCount, ghqCount, minimal, mild, moderate, severe, totalAssessments)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildExportCard(isHighRiskTrend, totalAssessments)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMetricsList(phqCount, gadCount, ghqCount, minimal, mild, moderate, severe, totalAssessments),
                        const SizedBox(height: 24),
                        _buildExportCard(isHighRiskTrend, totalAssessments),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsList(
    int phq, int gad, int ghq, 
    int minimal, int mild, int moderate, int severe,
    int total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Distribution of assessments
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assessment Types Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.mintAccent),
              ),
              const SizedBox(height: 20),
              _progressRow('PHQ-9 (Depression Screen)', phq, total, Colors.blue),
              const SizedBox(height: 16),
              _progressRow('GAD-7 (Anxiety Screen)', gad, total, Colors.amber),
              const SizedBox(height: 16),
              _progressRow('GHQ-12 (General Health)', ghq, total, Colors.teal),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Distribution of severities
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Severity Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.lilacAccent),
              ),
              const SizedBox(height: 20),
              _progressRow('Minimal Distress', minimal, total, AppTheme.alertSuccess),
              const SizedBox(height: 16),
              _progressRow('Mild Distress', mild, total, Colors.lightBlue),
              const SizedBox(height: 16),
              _progressRow('Moderate Distress', moderate, total, AppTheme.alertWarning),
              const SizedBox(height: 16),
              _progressRow('Severe Distress', severe, total, AppTheme.alertSevere),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressRow(String label, int count, int total, Color color) {
    final double percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('$count (${(percent * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                    color: AppTheme.textLow, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildExportCard(bool isHighRisk, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(isBorderAccent: isHighRisk),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isHighRisk ? 'High-Risk Escalation Action' : 'Report Center',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            isHighRisk 
                ? 'High-risk flags indicate critical distress levels on campus. Exporting this report yields a targeted anonymized alert sheet for university health boards.' 
                : 'Generate and export routine anonymized clinical assessment metrics sheets for school wellness monitoring boards.',
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighRisk ? AppTheme.alertSevere : AppTheme.tealPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            icon: const Icon(Icons.file_download_rounded),
            label: _isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isHighRisk ? 'Export High-Risk Alert Report' : 'Export Routine Report'),
            onPressed: total == 0 ? null : () => _exportAnonymizedReport(isHighRisk),
          ),
          if (_exportPath != null) ...[
            const SizedBox(height: 16),
            Text(
              'File saved: \n$_exportPath',
              style: const TextStyle(color: AppTheme.alertSuccess, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
