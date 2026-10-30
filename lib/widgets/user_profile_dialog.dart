import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';

/// Shows a beautifully themed user profile modal dialog in CareCampus style
Future<void> showUserProfileDialog(
  BuildContext context, {
  required AppUser user,
  required VoidCallback onLogout,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => _UserProfileDialogContent(
      user: user,
      onLogout: onLogout,
    ),
  );
}

class _UserProfileDialogContent extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const _UserProfileDialogContent({
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role.toLowerCase();
    final Color roleColor;
    final Color roleBg;
    final IconData roleIcon;
    final String roleTitle;
    final String roleDescription;
    final String securityBadgeText;

    if (role == 'admin') {
      roleColor = AppTheme.alertAmber;
      roleBg = const Color(0xFFFFF8E1);
      roleIcon = Icons.admin_panel_settings_rounded;
      roleTitle = 'Campus Administrator';
      roleDescription = 'Campus wellness oversight, crisis triage reports, user management, and system administration.';
      securityBadgeText = 'Administrator Privileges: Full platform security active';
    } else if (role == 'counsellor') {
      roleColor = const Color(0xFF9B59B6);
      roleBg = const Color(0xFFF4EBF9);
      roleIcon = Icons.psychology_rounded;
      roleTitle = 'Campus Counsellor';
      roleDescription = 'Clinical student mental health care, scheduled counselling sessions, and crisis support.';
      securityBadgeText = 'Verified Practitioner: Encrypted mental health communications';
    } else {
      roleColor = AppTheme.tealBlue;
      roleBg = AppTheme.cloudBlue;
      roleIcon = Icons.school_rounded;
      roleTitle = 'Student Member';
      roleDescription = 'Personalized mental wellness tracking, anonymous bookings, AI companion, and peer forum.';
      securityBadgeText = 'Anonymity Shield: Identity masked during confidential bookings';
    }

    final initial = (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase();

    final createdDateStr = '${user.createdAt.day.toString().padLeft(2, '0')}/'
        '${user.createdAt.month.toString().padLeft(2, '0')}/'
        '${user.createdAt.year}';

    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CareCampus Profile',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slateText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.mutedText, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar & Basic Info Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.iceBlue.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    // Avatar with glowing ring
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: roleBg,
                        child: Text(
                          initial,
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name.isNotEmpty ? user.name : 'CareCampus User',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.username,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppTheme.slateText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 14, color: roleColor),
                          const SizedBox(width: 6),
                          Text(
                            roleTitle,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details section
              _infoTile(
                icon: Icons.shield_outlined,
                title: 'Security & Privacy',
                subtitle: securityBadgeText,
                accentColor: AppTheme.mintGreen,
              ),
              const SizedBox(height: 10),
              _infoTile(
                icon: Icons.info_outline_rounded,
                title: 'Role Scope',
                subtitle: roleDescription,
                accentColor: AppTheme.tealBlue,
              ),
              const SizedBox(height: 10),
              _infoTile(
                icon: Icons.calendar_today_rounded,
                title: 'Account Member Since',
                subtitle: createdDateStr,
                accentColor: AppTheme.slateText,
              ),
              const SizedBox(height: 20),

              // Sign Out and Close Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.alertRed,
                        side: BorderSide(color: AppTheme.alertRed.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.skyWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.iceBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppTheme.slateText,
                    height: 1.3,
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

