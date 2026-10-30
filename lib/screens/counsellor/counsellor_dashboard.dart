import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import 'appointment_requests.dart';
import 'manage_resources.dart';
import 'session_history.dart';
import '../../widgets/user_profile_dialog.dart';

class CounsellorDashboard extends StatefulWidget {
  const CounsellorDashboard({super.key});

  @override
  State<CounsellorDashboard> createState() => _CounsellorDashboardState();
}

class _CounsellorDashboardState extends State<CounsellorDashboard> {
  AppUser? _user;
  List<Appointment> _myAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounsellorData();
  }

  Future<void> _loadCounsellorData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await Services.auth.getCurrentUser();

      // RBAC Security Check
      if (currentUser == null || currentUser.role != 'counsellor') {
        _secureSignOut();
        return;
      }

      _user = currentUser;
      final appts =
          await Services.db.getAppointments(currentUser.uid, 'counsellor');

      setState(() {
        _myAppointments = appts;
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
        _myAppointments.where((a) => a.status == 'pending').length;
    final activeCount =
        _myAppointments.where((a) => a.status == 'accepted').length;
    final completedCount =
        _myAppointments.where((a) => a.status == 'completed').length;

    return Scaffold(
      backgroundColor: AppTheme.skyWhite,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner ────────────────────────────────────────────
            _CounsellorHero(userName: _user?.name ?? 'Counsellor'),
            const SizedBox(height: 20),

            // ── Stat Cards ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatBadge(
                    label: 'Pending',
                    value: pendingCount.toString(),
                    icon: Icons.pending_actions_rounded,
                    color: AppTheme.alertAmber,
                    bgColor: const Color(0xFFFFF8E1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBadge(
                    label: 'Scheduled',
                    value: activeCount.toString(),
                    icon: Icons.schedule_rounded,
                    color: AppTheme.alertGreen,
                    bgColor: const Color(0xFFE8F8F0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBadge(
                    label: 'Completed',
                    value: completedCount.toString(),
                    icon: Icons.task_alt_rounded,
                    color: AppTheme.tealBlue,
                    bgColor: const Color(0xFFE3F6FA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Modules ────────────────────────────────────────────────
            Text(
              'Therapist Modules',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.navyText,
              ),
            ),
            const SizedBox(height: 14),

            _ModuleCard(
              title: 'Appointment Requests',
              desc:
                  'View pending bookings, confirm or reject, and schedule times.',
              icon: Icons.calendar_today_rounded,
              iconColor: AppTheme.alertAmber,
              iconBg: const Color(0xFFFFF8E1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AppointmentRequests()),
              ).then((_) => _loadCounsellorData()),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Manage Wellness Resources',
              desc:
                  'Upload and publish guides, audio, videos & PDFs for students.',
              icon: Icons.library_books_rounded,
              iconColor: AppTheme.tealBlue,
              iconBg: const Color(0xFFE3F6FA),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageResources()),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              title: 'Session History',
              desc:
                  'Read and update case notes from previous consultations.',
              icon: Icons.history_edu_rounded,
              iconColor: const Color(0xFF9B59B6),
              iconBg: const Color(0xFFF4EBF9),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SessionHistory()),
              ).then((_) => _loadCounsellorData()),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
          message: 'Counsellor Profile',
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
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF4EBF9),
                child: Text(
                  (_user?.name ?? 'C').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF9B59B6),
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
          icon: const Icon(Icons.logout_rounded,
              color: AppTheme.alertRed, size: 20),
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

// ── Counsellor Hero ───────────────────────────────────────────────────────────
class _CounsellorHero extends StatelessWidget {
  final String userName;
  const _CounsellorHero({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF52C17C), Color(0xFF2AA8C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mintGreen.withValues(alpha: 0.3),
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
                  'Welcome Back, Specialist 👩‍⚕️',
                  style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
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
                    '💚 Helping students thrive',
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
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.navyText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Module Card ───────────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : AppTheme.iceBlue,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor
                    .withValues(alpha: _hovered ? 0.12 : 0.05),
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.desc,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: _hovered ? widget.iconColor : AppTheme.mutedText,
                  size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
