import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/donation_method_model.dart';

class AddEditDonationMethodScreen extends StatefulWidget {
  final DonationMethod? method;
  const AddEditDonationMethodScreen({super.key, this.method});

  @override
  State<AddEditDonationMethodScreen> createState() => _AddEditDonationMethodScreenState();
}

class _AddEditDonationMethodScreenState extends State<AddEditDonationMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _detailsController;
  late final TextEditingController _instructionsController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.method?.methodName);
    _detailsController = TextEditingController(text: widget.method?.accountDetails);
    _instructionsController = TextEditingController(text: widget.method?.instructions);
    _isActive = widget.method?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveMethod() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'method_name': _nameController.text.trim(),
      'account_details': _detailsController.text.trim(),
      'instructions': _instructionsController.text.trim(),
      'is_active': _isActive,
    };

    try {
      if (widget.method == null) {
        await supabase.from('donation_methods').insert(data);
      } else {
        await supabase.from('donation_methods').update(data).eq('id', widget.method!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ طريقة الدفع بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ البيانات: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.method == null ? 'إضافة طريقة دفع' : 'تعديل طريقة الدفع'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CupertinoFormSection(
                header: const Text('تفاصيل الطريقة'),
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _nameController,
                    placeholder: 'مثال: Zain Cash',
                    prefix: const Text('اسم الطريقة'),
                    validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _detailsController,
                    placeholder: 'مثال: 07800000000',
                    prefix: const Text('رقم/حساب'),
                     validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _instructionsController,
                    placeholder: 'مثال: يرجى إرسال إيصال',
                    prefix: const Text('تعليمات'),
                  ),
                ],
              ),
              CupertinoFormSection(
                header: const Text('الحالة'),
                children: [
                  CupertinoListTile(
                    title: const Text('فعالة'),
                    trailing: CupertinoSwitch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : CupertinoButton.filled(
                    onPressed: _saveMethod,
                    child: const Text('حفظ'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
