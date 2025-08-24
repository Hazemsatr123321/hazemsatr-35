import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/ui/screens/auth/auth_screen.dart';
import 'package:smart_iraq/src/ui/screens/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final supabase = Provider.of<SupabaseClient>(context, listen: false);
    final session = supabase.auth.currentSession;

    if (session == null) {
      _navigateToAuth();
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('verification_status')
          .eq('id', session.user.id)
          .single();

      if (!mounted) return;

      if (profile['verification_status'] == 'approved') {
        _navigateToHome();
      } else {
        // Handle unapproved or rejected users
        await supabase.auth.signOut();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('حسابك لم يتم توثيقه بعد أو تم رفضه. الرجاء مراجعة الإدارة.'),
          backgroundColor: Colors.orange,
        ));
        _navigateToAuth();
      }
    } catch (e) {
      // Handle cases where profile doesn't exist or other errors
      if (!mounted) return;
      await supabase.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء التحقق من حسابك. الرجاء تسجيل الدخول مرة أخرى.'),
        backgroundColor: Colors.red,
      ));
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
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
