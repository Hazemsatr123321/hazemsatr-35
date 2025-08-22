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
    url: 'https://mfotgcymwpvbecqfghpg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mb3RnY3ltd3B2YmVjcWZnaHBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzNjE5NzAsImV4cCI6MjA3MDkzNzk3MH0.rYtnVSXRXx9VFFY9iPTWTNX5DN3VvrThaAbkV0hLQzs',
  );

  runApp(const SmartIraqApp());
}

// Get a reference to the Supabase client
final supabase = Supabase.instance.client;

class SmartIraqApp extends StatelessWidget {
  const SmartIraqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'العراق الذكي',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ).copyWith(
        textTheme: GoogleFonts.cairoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
