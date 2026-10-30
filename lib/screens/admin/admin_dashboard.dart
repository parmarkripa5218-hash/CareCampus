import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import 'manage_users.dart';
import 'monitor_forum.dart';
import 'counselling_overview.dart';
import 'manage_resources_admin.dart';
import 'chatbot_reports.dart';
import 'mental_health_analytics.dart';
import '../../widgets/user_profile_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AppUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    final currentUser = await Services.auth.getCurrentUser();

    // RBAC Security Check
    if (currentUser == null || currentUser.role != 'admin') {
      _secureSignOut();
      return;
    }

    setState(() {
      _user = currentUser;
      _isLoading = false;
    });
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

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.skyWhite,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Admin Hero Card ────────────────────────────────────────
            _AdminHero(userName: _user?.name ?? 'Admin'),
            const SizedBox(height: 28),

            // ── Section title ──────────────────────────────────────────
            Text(
              'Administration Modules',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.navyText,
              ),
            ),
            const SizedBox(height: 14),

            // ── Admin Module Grid ──────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = isDesktop ? 3 : 2;
                // Compute aspect ratio based on available width per card
                final cardWidth = (constraints.maxWidth - (crossCount - 1) * 14) / crossCount;
                final aspectRatio = cardWidth < 140 ? 0.85 : 1.0;
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: aspectRatio,
                  children: [
                    _AdminCard(
                      title: 'Manage Users',
                      desc: 'Register Student & Counsellor accounts.',
                      icon: Icons.manage_accounts_rounded,
                      iconColor: AppTheme.tealBlue,
                      iconBg: const Color(0xFFE3F6FA),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ManageUsers())),
                    ),
                    _AdminCard(
                      title: 'Monitor Forum',
                      desc: 'View and remove inappropriate community posts.',
                      icon: Icons.security_rounded,
                      iconColor: AppTheme.alertRed,
                      iconBg: const Color(0xFFFFF3F3),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MonitorForum())),
                    ),
                    _AdminCard(
                      title: 'Counselling Logs',
                      desc: 'View appointment bookings & history.',
                      icon: Icons.assignment_rounded,
                      iconColor: const Color(0xFF9B59B6),
                      iconBg: const Color(0xFFF4EBF9),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CounsellingOverview())),
                    ),
                    _AdminCard(
                      title: 'Wellness Resources',
                      desc: 'Upload and publish student resources.',
                      icon: Icons.auto_stories_rounded,
                      iconColor: AppTheme.mintGreen,
                      iconBg: const Color(0xFFE8F8F0),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManageResourcesAdmin())),
                    ),
                    _AdminCard(
                      title: 'AI Chatbot Reports',
                      desc: 'Session counts & risk patterns.',
                      icon: Icons.smart_toy_rounded,
                      iconColor: const Color(0xFF4A90E2),
                      iconBg: const Color(0xFFEAF3FF),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChatbotReports())),
                    ),
                    _AdminCard(
                      title: 'Mental Health Stats',
                      desc: 'PHQ-9, GAD-7, GHQ-12 analytics.',
                      icon: Icons.analytics_rounded,
                      iconColor: AppTheme.alertGreen,
                      iconBg: const Color(0xFFE8F8F0),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MentalHealthAnalytics())),
                    ),
                  ],
                );
              },
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
          message: 'Admin Profile',
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
                  color: AppTheme.alertAmber.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFFF8E1),
                child: Text(
                  (_user?.name ?? 'A').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: AppTheme.alertAmber,
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

// ── Admin Hero Card ───────────────────────────────────────────────────────────
class _AdminHero extends StatelessWidget {
  final String userName;
  const _AdminHero({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A91), Color(0xFF2AA8C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealBlue.withValues(alpha: 0.3),
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
                  'Administrative Portal',
                  style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: 0.8),
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
                    '🔐 Full system control',
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
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ── Admin Module Card ─────────────────────────────────────────────────────────
class _AdminCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
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
              color: _hovered
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : AppTheme.iceBlue,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor
                    .withValues(alpha: _hovered ? 0.15 : 0.06),
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
                      height: 1.3,
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
