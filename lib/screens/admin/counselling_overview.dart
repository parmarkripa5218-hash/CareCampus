import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';

class CounsellingOverview extends StatefulWidget {
  const CounsellingOverview({super.key});

  @override
  State<CounsellingOverview> createState() => _CounsellingOverviewState();
}

class _CounsellingOverviewState extends State<CounsellingOverview> {
  List<Appointment> _allAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAppointments();
  }

  Future<void> _loadAllAppointments() async {
    try {
      final list = await Services.db.getAppointments('', 'admin');
      setState(() {
        _allAppointments = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counselling Global Log'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : _allAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 64, color: AppTheme.textLow.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No appointment bookings registered in the system.',
                          style: TextStyle(color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allAppointments.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final appt = _allAppointments[index];
                      
                      Color statusColor = AppTheme.alertWarning;
                      if (appt.status == 'accepted') statusColor = AppTheme.alertSuccess;
                      if (appt.status == 'completed') statusColor = AppTheme.tealPrimary;
                      if (appt.status == 'rejected') statusColor = AppTheme.alertSevere;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    appt.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Colors.white10),
                            
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 16, color: AppTheme.textLow),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Counsellor: ${appt.counsellorName}',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.today_rounded, size: 16, color: AppTheme.textLow),
                                const SizedBox(width: 8),
                                Text(
                                  'Requested: ${appt.bookingDate.day}/${appt.bookingDate.month}/${appt.bookingDate.year}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            if (appt.scheduledDateTime != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 16, color: AppTheme.textLow),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Scheduled: ${appt.scheduledDateTime}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.mintAccent,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            if (appt.anonymousAlertReason != null && appt.anonymousAlertReason!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.alertSevere.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.alertSevere.withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  'Clinical Alert Flag: ${appt.anonymousAlertReason}',
                                  style: const TextStyle(color: AppTheme.alertSevere, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],

                            if (appt.sessionNotes != null) ...[
                              const Divider(height: 24, color: Colors.white10),
                              const Text(
                                'Counsellor Case Session Notes:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lilacAccent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appt.sessionNotes!,
                                style: const TextStyle(color: AppTheme.textMedium, fontStyle: FontStyle.italic, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
