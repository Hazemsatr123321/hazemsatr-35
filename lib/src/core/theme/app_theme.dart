import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- New "Digital Luxury" Color Palette ---
  static const Color goldAccent = Color(0xFFB7943C);
  static const Color charcoalBackground = Color(0xFF1A202C);
  static const Color darkSurface = Color(0xFF2D3748);
  static const Color lightTextColor = Color(0xFFF7FAFC);
  static const Color secondaryTextColor = Color(0xFFA0AEC0);

  // --- Main App Theme (Dark by default) ---
  static CupertinoThemeData get mainTheme => CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: goldAccent,
    scaffoldBackgroundColor: charcoalBackground,
    barBackgroundColor: darkSurface,
    textTheme: CupertinoTextThemeData(
      textStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 16),
      actionTextStyle: GoogleFonts.tajawal(color: goldAccent, fontSize: 16, fontWeight: FontWeight.bold),
      navTitleTextStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 18, fontWeight: FontWeight.bold),
      navLargeTitleTextStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 34, fontWeight: FontWeight.bold),
      pickerTextStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 16),
      tabLabelTextStyle: GoogleFonts.tajawal(color: secondaryTextColor, fontSize: 10),
    ),
  );

  // --- Kept for reference or future light mode toggle ---
  static CupertinoThemeData get lightCupertinoTheme => const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF0D47A1),
    primaryContrastingColor: Color(0xFFFFFFFF),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    barBackgroundColor: Color(0xF0F9F9F9),
  );

   static CupertinoThemeData get darkCupertinoTheme => CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: goldAccent,
    scaffoldBackgroundColor: charcoalBackground,
    barBackgroundColor: darkSurface,
     textTheme: CupertinoTextThemeData(
      textStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 16),
      actionTextStyle: GoogleFonts.tajawal(color: goldAccent, fontSize: 16, fontWeight: FontWeight.bold),
      navTitleTextStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 18, fontWeight: FontWeight.bold),
      navLargeTitleTextStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 34, fontWeight: FontWeight.bold),
      pickerTextStyle: GoogleFonts.tajawal(color: lightTextColor, fontSize: 16),
      tabLabelTextStyle: GoogleFonts.tajawal(color: secondaryTextColor, fontSize: 10),
    ),
  );
}
