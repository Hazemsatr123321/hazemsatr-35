import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditPaymentMethodScreen extends StatefulWidget {
  const AddEditPaymentMethodScreen({Key? key}) : super(key: key);

  @override
  _AddEditPaymentMethodScreenState createState() => _AddEditPaymentMethodScreenState();
}

class _AddEditPaymentMethodScreenState extends State<AddEditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  Future<void> _saveMethod() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client.from('payment_methods').insert({
          'method_name': _nameController.text,
          'account_details': _detailsController.text,
          'instructions': _instructionsController.text,
          'is_active': _isActive,
        });
        Navigator.of(context).pop();
      } catch (e) {
        // Handle error
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add Payment Method'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CupertinoTextFormFieldRow(
                prefix: const Text('Method Name'),
                controller: _nameController,
                placeholder: 'e.g., Zain Cash',
                validator: (value) => value!.isEmpty ? 'This field is required' : null,
              ),
              CupertinoTextFormFieldRow(
                prefix: const Text('Account Details'),
                controller: _detailsController,
                placeholder: 'e.g., 0780 123 4567',
                validator: (value) => value!.isEmpty ? 'This field is required' : null,
              ),
              CupertinoTextFormFieldRow(
                prefix: const Text('Instructions'),
                controller: _instructionsController,
                placeholder: 'Optional instructions for user',
              ),
              CupertinoFormRow(
                prefix: const Text('Active'),
                child: CupertinoSwitch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(
                      onPressed: _saveMethod,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
