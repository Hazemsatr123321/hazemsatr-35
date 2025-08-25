import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_text_form_field_row.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/ui/screens/main_navigation_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  String _businessType = 'wholesaler';
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // Insert profile
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'business_name': _businessNameController.text.trim(),
          'business_type': _businessType,
          'role': 'user', // default role
        });

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showErrorDialog(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
     showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign-up Error'),
        content: Text(message),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Create New Account'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CupertinoTextFormFieldRow(
                controller: _businessNameController,
                prefix: const Text('Business Name'),
                placeholder: 'e.g., Al-Amal Company',
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              CupertinoFormRow(
                prefix: const Text('Business Type'),
                child: CupertinoSegmentedControl<String>(
                  groupValue: _businessType,
                  children: const {
                    'wholesaler': Text('Wholesaler'),
                    'shop_owner': Text('Shop Owner'),
                  },
                  onValueChanged: (value) => setState(() => _businessType = value),
                ),
              ),
              CupertinoTextFormFieldRow(
                controller: _emailController,
                prefix: const Text('Email'),
                placeholder: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (val) => (val == null || !val.contains('@')) ? 'Invalid email' : null,
              ),
              CupertinoTextFormFieldRow(
                controller: _passwordController,
                prefix: const Text('Password'),
                placeholder: '******',
                obscureText: true,
                validator: (val) => (val == null || val.length < 6) ? 'Password too short' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(
                      onPressed: _signUp,
                      child: const Text('Sign Up'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
