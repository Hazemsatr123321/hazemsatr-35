import 'package:flutter/cupertino.dart';
import 'package:smart_iraq/main.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    return CupertinoPageScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.hourglass, size: 80, color: CupertinoColors.systemYellow),
              const SizedBox(height: 24),
              Text(
                'الحساب قيد المراجعة',
                style: textTheme.navLargeTitleTextStyle.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'شكرًا لتسجيلك. فريقنا يقوم بمراجعة حسابك الآن. سيتم إعلامك فور الموافقة عليه لتتمكن من الوصول الكامل للتطبيق.',
                style: textTheme.textStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CupertinoButton(
                onPressed: () {
                  // Allow user to sign out and return to login screen
                  supabase.auth.signOut();
                },
                child: const Text('العودة إلى تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
