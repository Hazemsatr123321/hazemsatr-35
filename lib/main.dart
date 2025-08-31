import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/screens/splash_screen.dart';
import 'package:smart_iraq/src/ui/screens/home_screen.dart'; // Import the new home screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // Initialize Supabase with user-provided credentials
  await Supabase.initialize(
    url: 'https://aqtwasxdpkrkavqworwm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxdHdhc3hkcGtya2F2cXdvcndtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxNjk4NzUsImV4cCI6MjA3MTc0NTg3NX0.aIL3uIycOHqhlh_2xXncOFSHmDK-_yor7eWv8SxOu_w',
  );

  runApp(const SmartIraqApp());
}

// Get a reference to the Supabase client
final supabase = Supabase.instance.client;

class SmartIraqApp extends StatelessWidget {
  const SmartIraqApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a modern, professional color palette
    const Color primaryColor = Color(0xFF0D47A1); // Deep Blue
    const Color secondaryColor = Color(0xFF00ACC1); // Vibrant Teal/Cyan
    const Color backgroundColor = Color(0xFFF5F5F5); // Light Grey Background
    const Color cardColor = Colors.white;
    const Color errorColor = Color(0xFFD32F2F);

    // Create the base theme
    final ThemeData base = ThemeData.light();

    return MaterialApp(
      title: 'العراق الذكي',
      theme: base.copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: base.colorScheme.copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          background: backgroundColor,
          surface: cardColor,
          error: errorColor,
        ),
        textTheme: GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0, color: primaryColor),
          displayMedium: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0, color: primaryColor),
          headlineSmall: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.black87),
          titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.black87),
          bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.black87),
          bodyMedium: const TextStyle(fontSize: 14.0, color: Colors.black54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0, // We will use BoxShadows on containers instead for more control
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: cardColor,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
