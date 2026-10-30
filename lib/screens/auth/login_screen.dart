import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../student/student_dashboard.dart';
import '../counsellor/counsellor_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await Services.auth.login(username, password);
      if (user != null) {
        if (!mounted) return;

        Widget destination;
        if (user.role == 'admin') {
          destination = const AdminDashboard();
        } else if (user.role == 'counsellor') {
          destination = const CounsellorDashboard();
        } else {
          destination = const StudentDashboard();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password. Please try again.';
        });
      }
    } catch (e) {
      final msg = e.toString();
      setState(() {
        if (msg.contains('permission-denied') ||
            msg.contains('PERMISSION_DENIED')) {
          _errorMessage =
              'Sign-in failed: Firestore security rules are blocking access. '
              'Please update your Firestore rules.';
        } else {
          _errorMessage = 'An error occurred: $msg';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillCredentials(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.skyWhite,
      body: Stack(
        children: [
          // ── Watercolor background blobs ──────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _WatercolorBlob(
              color: const Color(0xFF2AA8C4).withValues(alpha: 0.12),
              size: 280,
            ),
          ),
          Positioned(
            top: -40,
            right: -80,
            child: _WatercolorBlob(
              color: const Color(0xFF52C17C).withValues(alpha: 0.09),
              size: 240,
            ),
          ),
          Positioned(
            bottom: isDesktop ? 40 : 200,
            left: -60,
            child: _WatercolorBlob(
              color: const Color(0xFF2AA8C4).withValues(alpha: 0.08),
              size: 200,
            ),
          ),

          // ── Main scrollable content ──────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 0 : 24,
                vertical: 32,
              ),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── CC Logo ──────────────────────────────────────
                      _CcLogo(size: 88),
                      const SizedBox(height: 16),

                      // ── Brand name ───────────────────────────────────
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Care',
                              style: GoogleFonts.nunito(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.mintGreen,
                              ),
                            ),
                            TextSpan(
                              text: 'Campus',
                              style: GoogleFonts.nunito(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.tealBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your safe space for mental wellness',
                        style: GoogleFonts.nunito(
                          color: AppTheme.mutedText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Login Card ───────────────────────────────────
                      Container(
                        width: isDesktop ? 440 : double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2AA8C4)
                                  .withValues(alpha: 0.10),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error banner
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.alertRed
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.alertRed
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppTheme.alertRed,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.nunito(
                                            color: AppTheme.alertRed,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email Field
                              TextFormField(
                                controller: _usernameController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.nunito(
                                  color: AppTheme.navyText,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: AppTheme.mutedText,
                                    size: 20,
                                  ),
                                ),
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.nunito(
                                  color: AppTheme.navyText,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppTheme.mutedText,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.mutedText,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: Validators.validatePassword,
                              ),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.only(top: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.nunito(
                                      color: AppTheme.slateText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Log In Gradient Button
                              _GradientButton(
                                label: 'Log In',
                                isLoading: _isLoading,
                                onTap: _isLoading ? null : _handleLogin,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Quick access credentials (eval) ──────────────
                      Container(
                        width: isDesktop ? 440 : double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cloudBlue.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.iceBlue),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🎓  Evaluation Quick Access',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.slateText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _demoChip('Student', 'student', 'StudentPassword@123')),
                                const SizedBox(width: 8),
                                Expanded(child: _demoChip('Counsellor', 'counsellor', 'CounsellorPassword@123')),
                                const SizedBox(width: 8),
                                Expanded(child: _demoChip('Admin', 'admin', 'AdminPassword@123')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Bottom illustration ───────────────────────────
                      const SizedBox(height: 16),
                      _CounselingIllustration(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String label, String user, String pass) {
    return GestureDetector(
      onTap: () => _fillCredentials(user, pass),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── CC Logo Widget ────────────────────────────────────────────────────────────
class _CcLogo extends StatelessWidget {
  final double size;
  const _CcLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.tealBlue.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          // Main gradient circle
          CustomPaint(
            size: Size(size, size),
            painter: _CcLogoPainter(),
          ),
        ],
      ),
    );
  }
}

class _CcLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEBF8FF), Color(0xFFF0FFF5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // Border ring
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF52C17C), Color(0xFF2AA8C4)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2 - 1.5, borderPaint);

    // Draw "CC" text manually
    final greenPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF52C17C), Color(0xFF3DB87A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w * 0.5, h));

    final tealPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2AA8C4), Color(0xFF1A7A91)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(w * 0.45, 0, w * 0.55, h));

    // Draw first C (green)
    _drawC(canvas, greenPaint, Offset(w * 0.22, h * 0.5), w * 0.26, h * 0.26);
    // Draw second C (teal, slightly overlapping)
    _drawC(canvas, tealPaint, Offset(w * 0.54, h * 0.5), w * 0.26, h * 0.26);

    // Heart on top-right of second C
    final heartPaint = Paint()
      ..color = const Color(0xFF2AA8C4)
      ..style = PaintingStyle.fill;
    _drawHeart(canvas, heartPaint, Offset(w * 0.72, h * 0.28), w * 0.10);
  }

  void _drawC(Canvas canvas, Paint paint, Offset center, double rx, double ry) {
    final path = Path();
    const startAngle = -math.pi * 0.6;
    const sweepAngle = math.pi * 1.6;
    path.addArc(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      startAngle,
      sweepAngle,
    );
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = rx * 0.38;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    final s = size;
    path.moveTo(x, y + s * 0.4);
    path.cubicTo(x - s * 1.4, y - s * 0.6, x - s * 1.4, y - s * 1.6,
        x, y - s * 0.9);
    path.cubicTo(x + s * 1.4, y - s * 1.6, x + s * 1.4, y - s * 0.6,
        x, y + s * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Gradient Login Button ─────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.onTap == null
                ? LinearGradient(
                    colors: [
                      AppTheme.mintGreen.withValues(alpha: 0.5),
                      AppTheme.tealBlue.withValues(alpha: 0.5),
                    ],
                  )
                : AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(50),
            boxShadow: widget.onTap == null
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.tealBlue.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}


class _WatercolorBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _WatercolorBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.6),
          topRight: Radius.circular(size * 0.3),
          bottomLeft: Radius.circular(size * 0.4),
          bottomRight: Radius.circular(size * 0.7),
        ),
      ),
    );
  }
}

// ── Counseling Illustration ───────────────────────────────────────────────────
class _CounselingIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _IllustrationPainter(),
        size: Size(MediaQuery.of(context).size.width.clamp(0, 440), 160),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground / floor
    final floorPaint = Paint()
      ..color = const Color(0xFFD0E9F8).withValues(alpha: 0.5);
    final floorPath = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 0.65, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(floorPath, floorPaint);

    // Left chair (patient)
    _drawChair(canvas, Offset(w * 0.18, h * 0.75), const Color(0xFFB8D9F0), false);
    // Right chair (counsellor)
    _drawChair(canvas, Offset(w * 0.75, h * 0.72), const Color(0xFFB8D9F0), true);

    // Small table in center
    _drawTable(canvas, Offset(w * 0.5, h * 0.78), const Color(0xFFD0E9F8));

    // Plant
    _drawPlant(canvas, Offset(w * 0.58, h * 0.65));

    // Patient (left person – sitting, hunched)
    _drawPerson(
      canvas: canvas,
      bodyCenter: Offset(w * 0.18, h * 0.52),
      bodyColor: const Color(0xFFF5C65A), // yellow shirt
      headColor: const Color(0xFFE8B89A),
      isHunched: true,
    );

    // Counsellor (right person – upright, holding clipboard)
    _drawPerson(
      canvas: canvas,
      bodyCenter: Offset(w * 0.77, h * 0.5),
      bodyColor: const Color(0xFFB8D9F0), // light blue jacket
      headColor: const Color(0xFFE8B89A),
      isHunched: false,
    );

    // Speech bubble near counsellor
    _drawSpeechBubble(canvas, Offset(w * 0.60, h * 0.22), w * 0.14);
  }

  void _drawChair(Canvas canvas, Offset base, Color color, bool flipped) {
    final paint = Paint()..color = color;
    final s = 28.0;

    // seat
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: base, width: s * 2, height: s * 0.5),
      const Radius.circular(6),
    );
    canvas.drawRRect(seatRect, paint);

    // back
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        flipped ? base.dx + s * 0.5 : base.dx - s * 1.5,
        base.dy - s * 1.5,
        s * 0.5,
        s * 1.5,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(backRect, paint);

    // legs
    final legPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(base.dx - s * 0.8, base.dy + s * 0.25),
        Offset(base.dx - s * 0.8, base.dy + s * 0.9), legPaint);
    canvas.drawLine(Offset(base.dx + s * 0.8, base.dy + s * 0.25),
        Offset(base.dx + s * 0.8, base.dy + s * 0.9), legPaint);
  }

  void _drawTable(Canvas canvas, Offset center, Color color) {
    final paint = Paint()..color = color;
    final s = 18.0;
    // table top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: s * 2.5, height: s * 0.5),
        const Radius.circular(6),
      ),
      paint,
    );
    // legs
    final legPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - s * 0.7, center.dy + s * 0.25),
      Offset(center.dx - s * 0.7, center.dy + s * 0.9),
      legPaint,
    );
    canvas.drawLine(
      Offset(center.dx + s * 0.7, center.dy + s * 0.25),
      Offset(center.dx + s * 0.7, center.dy + s * 0.9),
      legPaint,
    );
  }

  void _drawPlant(Canvas canvas, Offset base) {
    // pot
    final potPaint = Paint()..color = const Color(0xFFD0E9F8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base + const Offset(0, 12),
            width: 16, height: 14),
        const Radius.circular(3),
      ),
      potPaint,
    );
    // leaves
    final leafPaint = Paint()..color = const Color(0xFF52C17C);
    canvas.drawOval(
      Rect.fromCenter(center: base + const Offset(-10, -2), width: 14, height: 20),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: base + const Offset(10, -2), width: 14, height: 20),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: base + const Offset(0, -8), width: 12, height: 18),
      leafPaint,
    );
  }

  void _drawPerson({
    required Canvas canvas,
    required Offset bodyCenter,
    required Color bodyColor,
    required Color headColor,
    required bool isHunched,
  }) {
    final bodyPaint = Paint()..color = bodyColor;
    final headPaint = Paint()..color = headColor;
    final hairPaint = Paint()..color = const Color(0xFF3D2B1F);

    final headR = 12.0;
    // head
    final headCenter = bodyCenter + Offset(isHunched ? -4 : 0, -28);
    canvas.drawCircle(headCenter, headR, headPaint);
    // hair
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headR),
      -math.pi,
      math.pi,
      false,
      hairPaint..style = PaintingStyle.stroke..strokeWidth = 5,
    );
    // body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: bodyCenter + Offset(isHunched ? -2 : 0, 4),
        width: 22,
        height: 28,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // jeans/pants
    final jeansPaint = Paint()..color = const Color(0xFF5B8DD9);
    final jeansRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: bodyCenter + const Offset(0, 22),
        width: 20,
        height: 16,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(jeansRect, jeansPaint);
  }

  void _drawSpeechBubble(Canvas canvas, Offset center, double r) {
    final bubblePaint = Paint()
      ..color = const Color(0xFFF5A623).withValues(alpha: 0.85);
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: r));
    // tail
    path.moveTo(center.dx - r * 0.3, center.dy + r * 0.8);
    path.lineTo(center.dx + r * 0.5, center.dy + r * 1.6);
    path.lineTo(center.dx + r * 0.4, center.dy + r * 0.8);
    path.close();
    canvas.drawPath(path, bubblePaint);

    // dots inside
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center + Offset(-r * 0.35, 0), r * 0.12, dotPaint);
    canvas.drawCircle(center, r * 0.12, dotPaint);
    canvas.drawCircle(center + Offset(r * 0.35, 0), r * 0.12, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
