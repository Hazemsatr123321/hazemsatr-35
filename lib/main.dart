import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/providers/theme_provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mfotgcymwpvbecqfghpg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mb3RnY3ltd3B2YmVjcWZnaHBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzNjE5NzAsImV4cCI6MjA3MDkzNzk3MH0.rYtnVSXRXx9VFFY9iPTWTNX5DN3VvrThaAbkV0hLQzs',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SmartIraqApp(),
    ),
  );
}

// Get a reference to the Supabase client
final supabase = Supabase.instance.client;

class SmartIraqApp extends StatelessWidget {
  const SmartIraqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return CupertinoApp(
          title: 'العراق الذكي',
          theme: themeProvider.themeMode == ThemeMode.dark
              ? AppTheme.darkCupertinoTheme
              : AppTheme.lightCupertinoTheme,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
