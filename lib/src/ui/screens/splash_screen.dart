import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/ui/screens/home_screen.dart';
import 'package:smart_iraq/src/ui/screens/auth/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Wait for the animation to be visually pleasing
    await Future.delayed(const Duration(milliseconds: 2500));

    // This check is needed because the widget might be disposed
    // while the Future is resolving.
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            productRepository: SupabaseProductRepository(),
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'سوق العراق الذكي',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
        )
        .animate()
        .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeInOut)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 800.ms, curve: Curves.easeInOut)
        .then(delay: 500.ms)
        .shimmer(duration: 1500.ms, color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
      ),
    );
  }
}
