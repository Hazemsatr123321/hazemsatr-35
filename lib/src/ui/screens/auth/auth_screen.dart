import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/ui/screens/auth/signup_screen.dart';
import 'package:smart_iraq/src/ui/screens/main_navigation_screen.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_text_form_field_row.dart';
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
    if (_formKey.currentState?.validate() ?? false) {
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
    final emailController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('إعادة تعيين كلمة المرور'),
        content: Column(
          children: [
            const Text('أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.'),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: emailController,
              placeholder: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
            )
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('إرسال'),
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final supabase = Provider.of<SupabaseClient>(context, listen: false);
                try {
                  await supabase.auth.resetPasswordForEmail(emailController.text.trim());
                  Navigator.of(context).pop(); // Close the dialog
                  _showErrorDialog('تم إرسال رابط إعادة التعيين. يرجى التحقق من بريدك الإلكتروني.');
                } on AuthException catch (e) {
                   Navigator.of(context).pop();
                  _showErrorDialog(e.message);
                }
              }
            },
          ),
        ],
      ),
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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      placeholder: 'البريد الإلكتروني',
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty || !val.contains('@')) {
                          return 'الرجاء إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      placeholder: 'كلمة المرور',
                      icon: CupertinoIcons.lock,
                      obscureText: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
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
                       Navigator.of(context).push(
                         CupertinoPageRoute(builder: (context) => const SignUpScreen()),
                       );
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
    String? Function(String?)? validator,
  }) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      placeholder: placeholder,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Icon(icon, color: AppTheme.secondaryTextColor),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      validator: validator,
    );
  }
}
