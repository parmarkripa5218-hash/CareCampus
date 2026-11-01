import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/appointment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

class AppointmentRequests extends StatefulWidget {
  const AppointmentRequests({super.key});

  @override
  State<AppointmentRequests> createState() => _AppointmentRequestsState();
}

class _AppointmentRequestsState extends State<AppointmentRequests> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  final _notesController = TextEditingController();
  final _preNoteController = TextEditingController();
  final _dialogFormKey = GlobalKey<FormState>();
  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final user = await Services.auth.getCurrentUser();
      if (user != null) {
        final list = await Services.db.getAppointments(user.uid, 'counsellor');
        setState(() {
          _appointments = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatFullDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdays[d.weekday - 1];
    final month = months[d.month - 1];
    return '$weekday, ${d.day} $month ${d.year}';
  }

  ThemeData _buildCareCampusDatePickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppTheme.tealBlue,
        onPrimary: Colors.white,
        surface: AppTheme.white,
        onSurface: AppTheme.navyText,
        secondary: AppTheme.mintGreen,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppTheme.white,
        headerBackgroundColor: AppTheme.tealBlue,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        headerHelpStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dayStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        todayForegroundColor: WidgetStateProperty.all(AppTheme.tealBlue),
        todayBorder: const BorderSide(color: AppTheme.tealBlue, width: 1.5),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppTheme.tealBlue;
          return Colors.transparent;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppTheme.mutedText;
          return AppTheme.navyText;
        }),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppTheme.slateText),
          textStyle: WidgetStateProperty.all(GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppTheme.tealBlue),
          textStyle: WidgetStateProperty.all(GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  ThemeData _buildCareCampusTimePickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppTheme.tealBlue,
        onPrimary: Colors.white,
        surface: AppTheme.white,
        onSurface: AppTheme.navyText,
        secondary: AppTheme.mintGreen,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        hourMinuteTextColor: AppTheme.navyText,
        hourMinuteColor: AppTheme.cloudBlue,
        hourMinuteTextStyle: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900),
        dialHandColor: AppTheme.tealBlue,
        dialBackgroundColor: AppTheme.skyWhite,
        dialTextColor: AppTheme.navyText,
        dialTextStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        dayPeriodTextColor: AppTheme.tealBlue,
        dayPeriodColor: AppTheme.cloudBlue,
        dayPeriodBorderSide: const BorderSide(color: AppTheme.iceBlue),
        dayPeriodTextStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppTheme.slateText),
          textStyle: WidgetStateProperty.all(GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppTheme.tealBlue),
          textStyle: WidgetStateProperty.all(GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Future<void> _acceptAppointment(Appointment appt) async {
    _pickedDate = null;
    _pickedTime = null;
    _preNoteController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Session',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navyText,
                          ),
                        ),
                        Text(
                          appt.isAnonymous ? 'Confidential Session' : appt.studentPseudonym,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppTheme.slateText,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Student / Topic Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.skyWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.iceBlue.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            appt.isAnonymous ? Icons.security_rounded : Icons.person_outline_rounded,
                            size: 18,
                            color: appt.isAnonymous ? AppTheme.alertSevere : AppTheme.tealBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt.isAnonymous
                                      ? 'Anonymous Student (${appt.studentPseudonym})'
                                      : appt.studentPseudonym,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navyText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Concern: ${appt.anonymousAlertReason != null && appt.anonymousAlertReason!.isNotEmpty ? appt.anonymousAlertReason! : "General Wellness Consultation"}',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.slateText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Modern Themed Date Selection Card
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _pickedDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                          builder: (context, child) => Theme(
                            data: _buildCareCampusDatePickerTheme(context),
                            child: child!,
                          ),
                        );
                        if (date != null) setDialogState(() => _pickedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _pickedDate != null ? AppTheme.tealBlue.withValues(alpha: 0.06) : AppTheme.skyWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _pickedDate != null ? AppTheme.tealBlue.withValues(alpha: 0.5) : AppTheme.iceBlue,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _pickedDate != null ? AppTheme.tealBlue : AppTheme.cloudBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: _pickedDate != null ? Colors.white : AppTheme.tealBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SESSION DATE',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.slateText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pickedDate == null
                                        ? 'Tap to select date'
                                        : _formatFullDate(_pickedDate!),
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _pickedDate == null ? AppTheme.mutedText : AppTheme.navyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: _pickedDate != null ? AppTheme.tealBlue : AppTheme.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Modern Themed Time Selection Card
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _pickedTime ?? const TimeOfDay(hour: 10, minute: 0),
                          builder: (context, child) => Theme(
                            data: _buildCareCampusTimePickerTheme(context),
                            child: child!,
                          ),
                        );
                        if (time != null) setDialogState(() => _pickedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _pickedTime != null ? AppTheme.mintGreen.withValues(alpha: 0.08) : AppTheme.skyWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _pickedTime != null ? AppTheme.mintGreen.withValues(alpha: 0.6) : AppTheme.iceBlue,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _pickedTime != null ? AppTheme.mintGreen : const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.access_time_filled_rounded,
                                color: _pickedTime != null ? Colors.white : AppTheme.mintGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SESSION TIME',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.slateText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pickedTime == null
                                        ? 'Tap to select time'
                                        : _pickedTime!.format(context),
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _pickedTime == null ? AppTheme.mutedText : AppTheme.navyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: _pickedTime != null ? AppTheme.mintGreen : AppTheme.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pre-session note (optional)
                    TextFormField(
                      controller: _preNoteController,
                      maxLines: 3,
                      style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.navyText),
                      decoration: InputDecoration(
                        labelText: 'Pre-Session Note (optional)',
                        labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppTheme.slateText),
                        hintText: 'Meeting room location, Zoom link, preparation guidance...',
                        hintStyle: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedText),
                        prefixIcon: const Icon(Icons.note_alt_outlined, color: AppTheme.tealBlue, size: 20),
                        filled: true,
                        fillColor: AppTheme.skyWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.iceBlue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.iceBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.tealBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(color: AppTheme.slateText, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    'Confirm & Schedule',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  onPressed: () {
                    if (_pickedDate == null || _pickedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select both a date and a time.'),
                          backgroundColor: AppTheme.alertWarning,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && _pickedDate != null && _pickedTime != null) {
      final d = _pickedDate!;
      final t = _pickedTime!;
      final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final dateTimeText =
          '${d.day}/${d.month}/${d.year} at $hour:$minute $amPm';
      final preNote = _preNoteController.text.trim().isNotEmpty
          ? _preNoteController.text.trim()
          : null;
      await Services.db.updateAppointmentStatus(
        appt.id,
        'accepted',
        scheduledDateTime: dateTimeText,
        sessionNotes: preNote,
      );
      _loadAppointments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session scheduled for $dateTimeText'),
          backgroundColor: AppTheme.alertSuccess,
        ),
      );
    }
  }

  Future<void> _rejectAppointment(Appointment appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.alertSevere.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: AppTheme.alertSevere, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Decline Request',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.navyText),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to decline this appointment request for ${appt.studentPseudonym}?',
          style: GoogleFonts.nunito(color: AppTheme.slateText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.nunito(color: AppTheme.slateText, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertSevere,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Decline', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Services.db.updateAppointmentStatus(appt.id, 'rejected');
      _loadAppointments();
    }
  }

  Future<void> _completeSession(Appointment appt) async {
    _notesController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tealBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.tealBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete Case Notes',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.navyText),
                ),
              ),
            ],
          ),
          content: Form(
            key: _dialogFormKey,
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.navyText),
                decoration: InputDecoration(
                  labelText: 'Session Summary & Clinical Recommendations',
                  labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppTheme.slateText),
                  hintText: 'Enter case details, coping exercises discussed, follow-up plan...',
                  hintStyle: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedText),
                  filled: true,
                  fillColor: AppTheme.skyWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => Validators.validateRequired(v, 'Session notes', maxLen: 1500),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.nunito(color: AppTheme.slateText, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_dialogFormKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text('Save & Close', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final notes = Validators.sanitizeText(_notesController.text);
      await Services.db.updateAppointmentStatus(
        appt.id, 
        'completed', 
        sessionNotes: notes,
      );
      _loadAppointments();
    }
  }

  @override
  void dispose() {
    _preNoteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _appointments.where((a) => a.status == 'pending').toList();
    final active = _appointments.where((a) => a.status == 'accepted').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointment Manager'),
          bottom: const TabBar(
            indicatorColor: AppTheme.lilacAccent,
            labelColor: AppTheme.lilacAccent,
            unselectedLabelColor: AppTheme.textLow,
            tabs: [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Active Schedule'),
            ],
          ),
        ),
        body: Container(
          height: double.infinity,
          decoration: AppTheme.backgroundGradient,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
              : TabBarView(
                  children: [
                    _buildRequestsList(pending, isPendingTab: true),
                    _buildRequestsList(active, isPendingTab: false),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<Appointment> list, {required bool isPendingTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.assignment_turned_in_rounded : Icons.calendar_month_rounded, 
              size: 64, 
              color: AppTheme.mintAccent.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab ? 'No pending requests.' : 'No active sessions scheduled.',
              style: const TextStyle(color: AppTheme.textLow),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appt = list[index];
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          appt.isAnonymous ? Icons.security_rounded : Icons.person_outline_rounded,
                          color: appt.isAnonymous ? AppTheme.alertSevere : AppTheme.tealPrimary,
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
                  Text(
                    '${appt.bookingDate.day}/${appt.bookingDate.month}/${appt.bookingDate.year}',
                    style: const TextStyle(color: AppTheme.textLow, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Severity alert / referral reason
              if (appt.anonymousAlertReason != null && appt.anonymousAlertReason!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.tealBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.tealBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded, color: AppTheme.tealBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appt.anonymousAlertReason!,
                          style: const TextStyle(color: AppTheme.navyText, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (appt.scheduledDateTime != null) ...[
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 18, color: AppTheme.textMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled: ${appt.scheduledDateTime}',
                        style: const TextStyle(color: AppTheme.textHigh, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Actions Row — Wrap to prevent overflow on small screens
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (isPendingTab) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.alertSevere,
                        side: BorderSide(color: AppTheme.alertSevere.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => _rejectAppointment(appt),
                      child: const Text('Decline'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => _acceptAppointment(appt),
                      child: const Text('Schedule & Accept'),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18, color: AppTheme.spaceDark),
                      label: const Text('Conduct Offline Session'),
                      onPressed: () => _completeSession(appt),
                    ),
                  ]
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
