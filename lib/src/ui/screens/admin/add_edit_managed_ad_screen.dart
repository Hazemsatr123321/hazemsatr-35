import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditManagedAdScreen extends StatefulWidget {
  final ManagedAd? ad;
  const AddEditManagedAdScreen({super.key, this.ad});

  @override
  State<AddEditManagedAdScreen> createState() => _AddEditManagedAdScreenState();
}

class _AddEditManagedAdScreenState extends State<AddEditManagedAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _targetUrlController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad?.title);
    _imageUrlController = TextEditingController(text: widget.ad?.imageUrl);
    _targetUrlController = TextEditingController(text: widget.ad?.targetUrl);
    _isActive = widget.ad?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final supabase = Provider.of<SupabaseClient>(context, listen: false);
    final data = {
      'title': _titleController.text.trim(),
      'image_url': _imageUrlController.text.trim(),
      'target_url': _targetUrlController.text.trim(),
      'is_active': _isActive,
    };

    try {
      if (widget.ad == null) {
        await supabase.from('managed_ads').insert(data);
      } else {
        await supabase.from('managed_ads').update(data).eq('id', widget.ad!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الإعلان بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الإعلان: $e'), backgroundColor: Colors.red),
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
        middle: Text(widget.ad == null ? 'إضافة إعلان مدار' : 'تعديل الإعلان'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CupertinoFormSection(
                header: const Text('تفاصيل الإعلان'),
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _titleController,
                    placeholder: 'عنوان الإعلان',
                    prefix: const Text('العنوان'),
                    validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _imageUrlController,
                    placeholder: 'https://example.com/image.png',
                    prefix: const Text('رابط الصورة'),
                     validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _targetUrlController,
                    placeholder: 'https://example.com/product/123',
                    prefix: const Text('الرابط'),
                     validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                ],
              ),
              CupertinoFormSection(
                header: const Text('الحالة'),
                children: [
                  CupertinoListTile(
                    title: const Text('فعال'),
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
                    onPressed: _saveAd,
                    child: const Text('حفظ'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
