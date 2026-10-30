import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Palette (Light Watercolor Theme) ────────────────────────────────
  static const Color white        = Color(0xFFFFFFFF);
  static const Color skyWhite     = Color(0xFFF4F9FF);   // page background
  static const Color cloudBlue    = Color(0xFFE8F4FD);   // card fill
  static const Color lightBlue    = Color(0xFFD0E9F8);   // subtle accent
  static const Color iceBlue      = Color(0xFFB8D9F0);   // border / divider

  static const Color mintGreen    = Color(0xFF52C17C);   // brand green
  static const Color tealBlue     = Color(0xFF2AA8C4);   // brand teal
  static const Color deepTeal     = Color(0xFF1A7A91);   // dark teal
  static const Color navyText     = Color(0xFF1A2E44);   // primary text
  static const Color slateText    = Color(0xFF4A6580);   // secondary text
  static const Color mutedText    = Color(0xFF8AA5BE);   // hint/muted text

  static const Color alertRed     = Color(0xFFE05252);
  static const Color alertAmber   = Color(0xFFF5A623);
  static const Color alertGreen   = Color(0xFF27AE60);

  // Legacy aliases for screens that still use old color names
  static const Color spaceDark    = navyText;
  static const Color slateDark    = Color(0xFF2C3E50);
  static const Color slateCard    = cloudBlue;
  static const Color mintAccent   = mintGreen;
  static const Color tealPrimary  = tealBlue;
  static const Color lilacAccent  = Color(0xFF9B59B6);
  static const Color textHigh     = navyText;
  static const Color textMedium   = slateText;
  static const Color textLow      = mutedText;
  static const Color alertSevere  = alertRed;
  static const Color alertWarning = alertAmber;
  static const Color alertSuccess = alertGreen;

  // ── Gradient helpers ──────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [mintGreen, tealBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient brandGradientV = LinearGradient(
    colors: [mintGreen, tealBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroBg = LinearGradient(
    colors: [Color(0xFFEBF7FF), Color(0xFFF8FDFF), Color(0xFFF0FAF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: skyWhite,
      primaryColor: tealBlue,
      cardColor: white,
      colorScheme: const ColorScheme.light(
        primary: tealBlue,
        secondary: mintGreen,
        tertiary: deepTeal,
        surface: white,
        error: alertRed,
        onPrimary: white,
        onSecondary: white,
        onSurface: navyText,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.nunito(
          color: navyText, fontSize: 32,
          fontWeight: FontWeight.w800, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.nunito(
          color: navyText, fontSize: 24,
          fontWeight: FontWeight.w800, letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.nunito(
          color: navyText, fontSize: 18, fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.nunito(
          color: slateText, fontSize: 15, fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: navyText, fontSize: 16,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: slateText, fontSize: 14,
        ),
        labelLarge: GoogleFonts.nunito(
          color: tealBlue, fontSize: 14, fontWeight: FontWeight.w700,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: iceBlue,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          color: navyText, fontSize: 18, fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: navyText),
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        hintStyle: GoogleFonts.nunito(color: mutedText, fontSize: 14),
        labelStyle: GoogleFonts.nunito(color: slateText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: iceBlue, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: iceBlue, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tealBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: alertRed, width: 1.8),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealBlue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tealBlue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: tealBlue, width: 1.5),
          textStyle: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tealBlue,
          textStyle: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w700,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cloudBlue,
        labelStyle: GoogleFonts.nunito(color: slateText, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: iceBlue),
      ),

      dividerTheme: const DividerThemeData(
        color: iceBlue,
        thickness: 1,
        space: 1,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: white,
        headerBackgroundColor: tealBlue,
        headerForegroundColor: white,
        surfaceTintColor: Colors.transparent,
        dividerColor: iceBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dayStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        todayForegroundColor: WidgetStateProperty.all(tealBlue),
        todayBorder: const BorderSide(color: tealBlue, width: 1.5),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tealBlue;
          return Colors.transparent;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          if (states.contains(WidgetState.disabled)) return mutedText;
          return navyText;
        }),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        hourMinuteTextColor: navyText,
        hourMinuteColor: cloudBlue,
        hourMinuteTextStyle: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900),
        dialHandColor: tealBlue,
        dialBackgroundColor: skyWhite,
        dialTextColor: navyText,
        entryModeIconColor: tealBlue,
        dayPeriodTextColor: tealBlue,
        dayPeriodColor: cloudBlue,
      ),
    );
  }

  // Keep dark theme available (unchanged for now)
  static ThemeData get darkTheme => lightTheme;

  // ── Background decorations ────────────────────────────────────────────────
  static Decoration get backgroundGradient => const BoxDecoration(
    gradient: heroBg,
  );

  static Decoration glassCardDecoration({bool isBorderAccent = false}) =>
      BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBorderAccent ? tealBlue.withValues(alpha: 0.35) : iceBlue,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2AA8C4).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // Gradient pill button decoration (for custom gradient buttons)
  static BoxDecoration get gradientButtonDecoration => BoxDecoration(
    gradient: brandGradient,
    borderRadius: BorderRadius.circular(50),
    boxShadow: [
      BoxShadow(
        color: tealBlue.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
