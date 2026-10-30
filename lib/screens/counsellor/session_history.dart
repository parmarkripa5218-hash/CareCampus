import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

class SessionHistory extends StatefulWidget {
  const SessionHistory({super.key});

  @override
  State<SessionHistory> createState() => _SessionHistoryState();
}

class _SessionHistoryState extends State<SessionHistory> {
  List<Appointment> _completedAppointments = [];
  bool _isLoading = true;

  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final user = await Services.auth.getCurrentUser();
      if (user != null) {
        final list = await Services.db.getAppointments(user.uid, 'counsellor');
        setState(() {
          _completedAppointments = list.where((a) => a.status == 'completed').toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editSessionNotes(Appointment appt) async {
    _notesController.text = appt.sessionNotes ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.slateDark,
          title: const Text('Update Session Case Notes'),
          content: Form(
            key: _formKey,
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Session Summary & Recommendations',
                ),
                validator: (v) => Validators.validateRequired(v, 'Session notes', maxLen: 1500),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final updatedNotes = Validators.sanitizeText(_notesController.text);
      await Services.db.updateAppointmentStatus(
        appt.id, 
        'completed', 
        sessionNotes: updatedNotes,
      );
      _loadHistory();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session notes updated successfully.'),
          backgroundColor: AppTheme.alertSuccess,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History Logs'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : _completedAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: AppTheme.textLow.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No completed sessions logged.',
                          style: TextStyle(color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _completedAppointments.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final appt = _completedAppointments[index];
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        appt.isAnonymous ? Icons.security_rounded : Icons.person_outline_rounded,
                                        color: appt.isAnonymous ? AppTheme.alertSevere : AppTheme.lilacAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          appt.isAnonymous ? 'Anonymous Student' : appt.studentPseudonym,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    appt.scheduledDateTime ?? 'Date unknown',
                                    style: const TextStyle(color: AppTheme.textLow, fontSize: 11),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (appt.isAnonymous && appt.anonymousAlertReason != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Referral Code: ${appt.anonymousAlertReason}',
                                style: const TextStyle(color: AppTheme.textLow, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ],
                            
                            const Divider(height: 24, color: Colors.white10),
                            const Text(
                              'Clinical Session Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.mintAccent),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              appt.sessionNotes ?? 'No notes recorded.',
                              style: const TextStyle(color: AppTheme.textMedium, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text('Update Notes'),
                                onPressed: () => _editSessionNotes(appt),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
