import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedUnitType;
  bool _isLoading = false;

  final List<String> _unitTypes = const ['قطعة', 'كرتونة', 'درزن', 'كيلوغرام'];

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      await supabase.from('product_requests').insert({
        'retailer_id': supabase.auth.currentUser!.id,
        'requested_product_name': _productNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quantity_needed': _quantityController.text.trim(),
        'unit_type': _selectedUnitType,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر طلبك بنجاح!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${error.toString()}'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نشر طلب بضاعة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _productNameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج المطلوب', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال اسم المنتج' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف (المواصفات، الموديل، إلخ)', border: OutlineInputBorder()),
                  maxLines: 4,
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'الكمية المطلوبة', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال الكمية' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnitType,
                        decoration: const InputDecoration(labelText: 'وحدة القياس', border: OutlineInputBorder()),
                        items: _unitTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _selectedUnitType = v),
                        validator: (v) => v == null ? 'اختر وحدة' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _submitRequest, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)), child: const Text('نشر الطلب')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
