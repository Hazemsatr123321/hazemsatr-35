import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/ui/screens/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome({bool isGuest = false}) {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => MainNavigationScreen(isGuest: isGuest)),
        (route) => false,
      );
    }
  }

  Future<void> _signIn() async {
    // A basic validation check
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       _showErrorDialog('الرجاء إدخال البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted && response.user != null) {
        _navigateToHome();
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ في تسجيل الدخول'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _forgotPassword() {
     showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('نسيت كلمة المرور'),
        content: const Text('هذه الميزة قيد التطوير حالياً. يرجى التواصل مع الدعم الفني.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('موافق'), onPressed: () => Navigator.of(context).pop())],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(CupertinoIcons.shopping_cart, color: AppTheme.goldAccent, size: 80),
              const SizedBox(height: 16),
              Text(
                'سوق العراق الذكي',
                textAlign: TextAlign.center,
                style: theme.textTheme.navLargeTitleTextStyle,
              ),
              Text(
                'منصة تجارة الجملة الأولى في العراق',
                textAlign: TextAlign.center,
                style: theme.textTheme.textStyle.copyWith(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 48),
              _buildTextField(
                controller: _emailController,
                placeholder: 'البريد الإلكتروني',
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                placeholder: 'كلمة المرور',
                icon: CupertinoIcons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _forgotPassword,
                  child: Text('نسيت كلمة المرور؟', style: theme.textTheme.textStyle.copyWith(color: AppTheme.secondaryTextColor)),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CupertinoActivityIndicator(radius: 16))
              else
                CupertinoButton.filled(
                  onPressed: _signIn,
                  child: Text('تسجيل الدخول', style: theme.textTheme.textStyle.copyWith(fontWeight: FontWeight.bold, color: AppTheme.charcoalBackground)),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text('ليس لديك حساب؟', style: theme.textTheme.textStyle.copyWith(color: AppTheme.secondaryTextColor)),
                   CupertinoButton(
                     padding: const EdgeInsets.symmetric(horizontal: 4),
                     onPressed: () {
                       // TODO: Navigate to a dedicated signup screen
                       _showErrorDialog('ميزة إنشاء حساب جديد قيد التطوير.');
                     },
                     child: const Text('إنشاء حساب جديد', style: TextStyle(color: AppTheme.goldAccent)),
                   )
                ],
              ),
              const SizedBox(height: 16),
               CupertinoButton(
                  onPressed: () => _navigateToHome(isGuest: true),
                  child: Text('أو الدخول كزائر', style: theme.textTheme.textStyle.copyWith(color: AppTheme.secondaryTextColor)),
                ),
            ].animate(interval: 100.ms).fadeIn(duration: 600.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      padding: const EdgeInsets.all(16),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Icon(icon, color: AppTheme.secondaryTextColor),
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
