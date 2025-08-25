import 'dart:async';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/services/notification_service.dart';
import 'package:smart_iraq/src/ui/screens/auth/auth_screen.dart';
import 'package:smart_iraq/src/ui/screens/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

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
    // Wait for a bit for the animation to be visually pleasing
    await Future.delayed(const Duration(milliseconds: 2500));

    // This check is needed because the widget might be disposed
    // while the Future is resolving.
    if (!mounted) return;

    final supabase = Provider.of<SupabaseClient>(context, listen: false);
    final session = supabase.auth.currentSession;

    // Since verification is removed, we just check for a session.
    if (session != null) {
      // Initialize the notification service after user is confirmed to be logged in
      await Provider.of<NotificationService>(context, listen: false).init();
      _navigateToHome();
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.charcoalBackground,
      child: Center(
        child: Text(
          'سوق العراق الذكي',
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            shadows: [
              Shadow(
                color: AppTheme.goldAccent.withOpacity(0.3),
                blurRadius: 15,
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
        .shimmer(duration: 1500.ms, color: AppTheme.goldAccent.withOpacity(0.7)),
      ),
    );
  }
}
