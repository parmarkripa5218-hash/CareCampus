import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import 'book_counsellor.dart';
import 'peer_forum.dart';
import 'resource_hub.dart';
import 'chatbot_chat.dart';
import 'assessment_form.dart';
import '../../widgets/user_profile_dialog.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  AppUser? _user;
  List<Appointment> _appointments = [];
  List<String> _warnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await Services.auth.getCurrentUser();

      // RBAC Security Check
      if (currentUser == null || currentUser.role != 'student') {
        _secureSignOut();
        return;
      }

      _user = currentUser;
      final appointments =
          await Services.db.getAppointments(currentUser.uid, 'student');
      final warnings = await Services.db.getUserWarnings(currentUser.uid);

      setState(() {
        _appointments = appointments;
        _warnings = warnings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _secureSignOut() async {
    await Services.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.skyWhite,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.tealBlue),
        ),
      );
    }

    final pendingCount =
        _appointments.where((a) => a.status == 'pending').length;
    final approvedCount =
        _appointments.where((a) => a.status == 'accepted').length;

    return Scaffold(
      backgroundColor: AppTheme.skyWhite,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Hero Card ──────────────────────────────────────
            _WelcomeHero(userName: _user?.name ?? 'Student'),
            const SizedBox(height: 20),

            // ── Admin Alerts ───────────────────────────────────────────
            if (_warnings.isNotEmpty) ...[
              _AlertBanner(warnings: _warnings),
              const SizedBox(height: 16),
            ],

            // ── Status Cards ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    label: 'Pending Bookings',
                    value: pendingCount.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    color: AppTheme.alertAmber,
                    bgColor: const Color(0xFFFFF8E1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatusCard(
                    label: 'Confirmed Sessions',
                    value: approvedCount.toString(),
                    icon: Icons.event_available_rounded,
                    color: AppTheme.alertGreen,
                    bgColor: const Color(0xFFE8F8F0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Wellness Services Grid ─────────────────────────────────
            Text(
              'Wellness Services',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.navyText,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 600 ? 3 : 2;
                final cardWidth = (constraints.maxWidth - (crossCount - 1) * 14) / crossCount;
                final aspectRatio = cardWidth < 140 ? 0.9 : 1.05;
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: aspectRatio,
                  children: [
                    _ServiceCard(
                      title: 'AI Chatbot',
                      desc: 'Chat & get coping advice',
                      icon: Icons.smart_toy_outlined,
                      iconColor: const Color(0xFF4A90E2),
                      iconBg: const Color(0xFFEAF3FF),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChatbotChat())),
                    ),
                    _ServiceCard(
                      title: 'Self-Assessment',
                      desc: 'PHQ-9, GAD-7, GHQ-12',
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF27AE60),
                      iconBg: const Color(0xFFE8F8F0),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AssessmentForm())),
                    ),
                    _ServiceCard(
                      title: 'Book Counsellor',
                      desc: 'Schedule a session',
                      icon: Icons.calendar_month_outlined,
                      iconColor: const Color(0xFF2AA8C4),
                      iconBg: const Color(0xFFE3F6FA),
                      onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BookCounsellor()))
                          .then((_) => _loadDashboardData()),
                    ),
                    _ServiceCard(
                      title: 'Peer Forum',
                      desc: 'Anonymous community',
                      icon: Icons.forum_outlined,
                      iconColor: const Color(0xFF9B59B6),
                      iconBg: const Color(0xFFF4EBF9),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PeerForum())),
                    ),
                    _ServiceCard(
                      title: 'Resource Hub',
                      desc: 'Guides & meditations',
                      icon: Icons.folder_shared_outlined,
                      iconColor: const Color(0xFFF5A623),
                      iconBg: const Color(0xFFFFF4E0),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ResourceHub())),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Recent Appointments ────────────────────────────────────
            Text(
              'Recent Appointments',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.navyText,
              ),
            ),
            const SizedBox(height: 14),
            _appointments.isEmpty
                ? _EmptyAppointments()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final appt = _appointments[idx];
                      return _AppointmentCard(appointment: appt);
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Care',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.mintGreen,
                  ),
                ),
                TextSpan(
                  text: 'Campus',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: 'My Profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              if (_user != null) {
                showUserProfileDialog(
                  context,
                  user: _user!,
                  onLogout: _secureSignOut,
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.tealBlue.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.cloudBlue,
                child: Text(
                  (_user?.name ?? 'S').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: AppTheme.tealBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          icon:
              const Icon(Icons.logout_rounded, color: AppTheme.alertRed, size: 20),
          onPressed: _secureSignOut,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.iceBlue),
      ),
    );
  }
}

// ── Welcome Hero ──────────────────────────────────────────────────────────────
class _WelcomeHero extends StatelessWidget {
  final String userName;
  const _WelcomeHero({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back 👋',
                  style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🌱 Your wellness journey matters',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final List<String> warnings;
  const _AlertBanner({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.alertRed, size: 22),
              const SizedBox(width: 10),
              Text(
                'Administrative Alert',
                style: GoogleFonts.nunito(
                  color: AppTheme.alertRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  '• $w',
                  style: GoogleFonts.nunito(
                    color: AppTheme.navyText,
                    fontSize: 13,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Status Card ───────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.navyText,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service Card ──────────────────────────────────────────────────────────────
class _ServiceCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? widget.iconColor.withValues(alpha: 0.4) : AppTheme.iceBlue,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withValues(alpha: _hovered ? 0.15 : 0.06),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppTheme.navyText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.desc,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty Appointments ────────────────────────────────────────────────────────
class _EmptyAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 40, color: AppTheme.mutedText),
          const SizedBox(height: 12),
          Text(
            'No appointments booked yet',
            style: GoogleFonts.nunito(
              color: AppTheme.slateText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'If you\'re feeling overwhelmed, consider booking a counsellor session.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppTheme.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.alertAmber;
    Color statusBg = const Color(0xFFFFF8E1);
    if (appointment.status == 'accepted') {
      statusColor = AppTheme.alertGreen;
      statusBg = const Color(0xFFE8F8F0);
    }
    if (appointment.status == 'completed') {
      statusColor = AppTheme.tealBlue;
      statusBg = const Color(0xFFE3F6FA);
    }
    if (appointment.status == 'rejected') {
      statusColor = AppTheme.alertRed;
      statusBg = const Color(0xFFFFF3F3);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.isAnonymous
                      ? 'Anonymous Request'
                      : 'Standard Appointment',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.navyText,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            text: 'Counsellor: ${appointment.counsellorName}',
          ),
          if (appointment.scheduledDateTime != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.event_rounded,
              text: 'Scheduled: ${appointment.scheduledDateTime}',
            ),
          ],
          if (appointment.sessionNotes != null) ...[
            const Divider(height: 20, color: AppTheme.iceBlue),
            Text(
              'Session Notes:',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.tealBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.sessionNotes!,
              style: GoogleFonts.nunito(
                fontStyle: FontStyle.italic,
                color: AppTheme.slateText,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: AppTheme.slateText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
