import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Shared Colors ---
  static const Color _primaryColor = Color(0xFF0D47A1); // Deep Blue
  static const Color _secondaryColor = Color(0xFF00ACC1); // Vibrant Teal/Cyan
  static const Color _errorColor = Color(0xFFD32F2F);

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey Background
    colorScheme: const ColorScheme.light().copyWith(
      primary: _primaryColor,
      secondary: _secondaryColor,
      background: const Color(0xFFF5F5F5),
      surface: Colors.white,
      error: _errorColor,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0, color: _primaryColor),
      displayMedium: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0, color: _primaryColor),
      headlineSmall: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.black87),
      titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.black87),
      bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.black87),
      bodyMedium: const TextStyle(fontSize: 14.0, color: Colors.black54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.grey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: _primaryColor, width: 2.0)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _secondaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _secondaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: Colors.white,
    ),
  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
     primaryColor: _primaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212), // Very dark grey
    colorScheme: const ColorScheme.dark().copyWith(
      primary: _primaryColor, // Keep primary color vibrant
      secondary: _secondaryColor, // Keep secondary color vibrant
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E), // Slightly lighter grey for cards
      error: _errorColor,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0, color: Colors.white),
      displayMedium: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0, color: Colors.white),
      headlineSmall: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.white70),
      titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white70),
      bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.white70),
      bodyMedium: const TextStyle(fontSize: 14.0, color: Colors.white54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E), // Darker grey for app bar
      foregroundColor: Colors.white,
      elevation: 2,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.grey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: _secondaryColor, width: 2.0)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _secondaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
     floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _secondaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: const Color(0xFF1E1E1E),
    ),
  );
}
