import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/screens/splash_screen.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السوق - العراق الذكي'),
      ),
      body: const Center(
        child: Text(
          'أهلاً بك في تطبيق العراق الذكي!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
