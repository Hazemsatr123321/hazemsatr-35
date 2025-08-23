import 'dart:math';
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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoginView = true;

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
  String _selectedBusinessType = 'retailer'; // 'retailer' or 'wholesaler'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupBusinessNameController.dispose();
    _signupBusinessAddressController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_animationController.status != AnimationStatus.forward) {
      if (_isLoginView) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      setState(() {
        _isLoginView = !_isLoginView;
      });
    }
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );

      if (response.user != null) {
        final profile = await supabase.from('profiles').select().eq('id', response.user!.id).single();
        if (profile['verification_status'] == 'approved') {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainNavigationScreen()), (route) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const PendingVerificationScreen()), (route) => false);
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text.trim(),
        data: {
          'business_name': _signupBusinessNameController.text.trim(),
          'business_address': _signupBusinessAddressController.text.trim(),
          'business_type': _selectedBusinessType,
        }
      );

      // The handle_new_user trigger in the DB will create the profile.
      // We just need to inform the user.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح! حسابك الآن قيد المراجعة من قبل الإدارة.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        _flipCard(); // Flip back to login
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final angle = _animation.value * pi;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);
                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: _animation.value <= 0.5
                          ? _buildCard(context, _buildLogin)
                          : Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: Alignment.center,
                              child: _buildCard(context, _buildSignup),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget Function(BuildContext) builder) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoading ? const Center(child: CircularProgressIndicator()) : builder(context),
    );
  }

  Widget _buildLogin(BuildContext context) {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تسجيل الدخول', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextFormField(
            controller: _loginEmailController,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'بريد إلكتروني غير صالح' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(labelText: 'كلمة المرور'),
            obscureText: true,
            validator: (v) => v == null || v.isEmpty ? 'كلمة المرور مطلوبة' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _signIn, child: const Text('دخول')),
          TextButton(onPressed: _flipCard, child: const Text('ليس لديك حساب؟ إنشاء حساب تاجر')),
        ],
      ),
    );
  }

  Widget _buildSignup(BuildContext context) {
    return Form(
      key: _signupFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('إنشاء حساب تاجر جديد', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          // Business Type
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'retailer', label: Text('صاحب محل'), icon: Icon(Icons.store)),
              ButtonSegment<String>(value: 'wholesaler', label: Text('تاجر جملة'), icon: Icon(Icons.warehouse)),
            ],
            selected: {_selectedBusinessType},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedBusinessType = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupBusinessNameController,
            decoration: const InputDecoration(labelText: 'اسم العمل/المحل'),
            validator: (v) => v == null || v.isEmpty ? 'اسم العمل مطلوب' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupEmailController,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'بريد إلكتروني غير صالح' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupPasswordController,
            decoration: const InputDecoration(labelText: 'كلمة المرور'),
            obscureText: true,
            validator: (v) => v == null || v.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupConfirmPasswordController,
            decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
            obscureText: true,
            validator: (v) => v != _signupPasswordController.text ? 'كلمتا المرور غير متطابقتين' : null,
          ),
           const SizedBox(height: 16),
          TextFormField(
            controller: _signupBusinessAddressController,
            decoration: const InputDecoration(labelText: 'عنوان العمل (اختياري)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _signUp, child: const Text('إنشاء الحساب')),
          TextButton(onPressed: _flipCard, child: const Text('لديك حساب بالفعل؟ تسجيل الدخول')),
        ],
      ),
    );
  }
}
