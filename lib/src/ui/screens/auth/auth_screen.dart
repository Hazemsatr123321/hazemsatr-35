import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/ui/screens/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/screens/auth/pending_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _selectedSegment = 0; // 0 for Login, 1 for Signup

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Signup form
  final _signupFormKey = GlobalKey<FormState>();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _signupBusinessNameController = TextEditingController();
  final _signupBusinessAddressController = TextEditingController();
  String _selectedBusinessType = 'retailer';

  bool _isLoading = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupBusinessNameController.dispose();
    _signupBusinessAddressController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );
      if (mounted && response.user != null) {
        final profile = await supabase.from('profiles').select('verification_status').eq('id', response.user!.id).single();
        if (mounted) {
          if (profile['verification_status'] == 'approved') {
            Navigator.of(context).pushAndRemoveUntil(CupertinoPageRoute(builder: (context) => const MainNavigationScreen()), (route) => false);
          } else {
            Navigator.of(context).pushAndRemoveUntil(CupertinoPageRoute(builder: (context) => const PendingVerificationScreen()), (route) => false);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signUp(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text.trim(),
        data: {
          'business_name': _signupBusinessNameController.text.trim(),
          'business_address': _signupBusinessAddressController.text.trim(),
          'business_type': _selectedBusinessType,
        }
      );
      if (mounted) {
        _showErrorDialog('تم إنشاء الحساب بنجاح! حسابك الآن قيد المراجعة. سيتم إعلامك عند تفعيله.', isError: false);
        setState(() => _selectedSegment = 0);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message, {bool isError = true}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isError ? 'خطأ' : 'نجاح'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 40),
            Text(
              'سوق العراق الذكي',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 36),
            ),
            Text(
              'منصة تجارة الجملة الأولى في العراق',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.secondaryLabel),
            ),
            const SizedBox(height: 40),
            CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedSegment,
              onValueChanged: (int? value) {
                if (value != null) {
                  setState(() => _selectedSegment = value);
                }
              },
              children: const <int, Widget>{
                0: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('تسجيل الدخول')),
                1: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('إنشاء حساب')),
              },
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _selectedSegment == 0 ? _buildLoginForm() : _buildSignupForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        children: [
          CupertinoTextFormFieldRow(
            controller: _loginEmailController,
            prefix: const Text('البريد'),
            placeholder: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'بريد إلكتروني غير صالح' : null,
          ),
          CupertinoTextFormFieldRow(
            controller: _loginPasswordController,
            prefix: const Text('الرمز'),
            placeholder: 'كلمة المرور',
            obscureText: true,
            validator: (v) => v == null || v.isEmpty ? 'كلمة المرور مطلوبة' : null,
          ),
          const SizedBox(height: 20),
          _isLoading ? const CupertinoActivityIndicator() : CupertinoButton.filled(
            onPressed: _signIn,
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        key: const ValueKey('signup'),
        children: [
           CupertinoTextFormFieldRow(
            controller: _signupBusinessNameController,
            prefix: const Text('اسم العمل'),
            placeholder: 'مثال: متجر النور',
            validator: (v) => v == null || v.isEmpty ? 'اسم العمل مطلوب' : null,
          ),
          CupertinoTextFormFieldRow(
            controller: _signupEmailController,
            prefix: const Text('البريد'),
            placeholder: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'بريد إلكتروني غير صالح' : null,
          ),
          CupertinoTextFormFieldRow(
            controller: _signupPasswordController,
            prefix: const Text('الرمز'),
            placeholder: 'كلمة المرور',
            obscureText: true,
            validator: (v) => v == null || v.length < 6 ? '6 أحرف على الأقل' : null,
          ),
          CupertinoTextFormFieldRow(
            controller: _signupConfirmPasswordController,
            prefix: const Text('التأكيد'),
            placeholder: 'تأكيد كلمة المرور',
            obscureText: true,
            validator: (v) => v != _signupPasswordController.text ? 'غير متطابق' : null,
          ),
          const SizedBox(height: 16),
          const Text('أنا أسجل بصفتي:'),
          CupertinoSegmentedControl<String>(
            groupValue: _selectedBusinessType,
            onValueChanged: (val) => setState(() => _selectedBusinessType = val!),
            children: const {
              'retailer': Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('صاحب محل')),
              'wholesaler': Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('تاجر جملة')),
            },
          ),
          const SizedBox(height: 20),
          _isLoading ? const CupertinoActivityIndicator() : CupertinoButton.filled(
            onPressed: _signUp,
            child: const Text('إنشاء الحساب'),
          ),
        ],
      ),
    );
  }
}
