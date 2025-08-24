import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _minOrderQuantityController;

  String? _selectedCategory;
  String? _selectedUnitType;
  bool _isLoading = false;

  final List<String> _categories = const [
    'إلكترونيات', 'ملابس', 'أثاث', 'مركبات', 'عقارات', 'مواد غذائية', 'غير ذلك',
  ];
  final List<String> _unitTypes = const ['قطعة', 'كرتونة', 'درزن', 'كيلوغرام'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockQuantityController = TextEditingController(text: widget.product.stock_quantity?.toString() ?? '0');
    _minOrderQuantityController = TextEditingController(text: widget.product.minimum_order_quantity?.toString() ?? '1');

    if (widget.product.category != null && _categories.contains(widget.product.category)) {
      _selectedCategory = widget.product.category;
    }
     if (widget.product.unit_type != null && _unitTypes.contains(widget.product.unit_type)) {
      _selectedUnitType = widget.product.unit_type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minOrderQuantityController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      await supabase.from('products').update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'stock_quantity': int.parse(_stockQuantityController.text.trim()),
        'minimum_order_quantity': int.parse(_minOrderQuantityController.text.trim()),
        'unit_type': _selectedUnitType,
      }).eq('id', widget.product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المنتج بنجاح!'), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text('تعديل المنتج')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Note: Image editing is not implemented in this version for simplicity.
                // A real app might have a button to re-upload the image.
                if (widget.product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(widget.product.imageUrl!, height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال اسم المنتج' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'وصف المنتج', border: OutlineInputBorder()),
                  maxLines: 4,
                  validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال وصف للمنتج' : null,
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'السعر (للوحدة)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'أدخل سعر صحيح' : null,
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
                const SizedBox(height: 16.0),
                 Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockQuantityController,
                        decoration: const InputDecoration(labelText: 'الكمية المتوفرة', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'أدخل كمية صحيحة' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minOrderQuantityController,
                        decoration: const InputDecoration(labelText: 'أقل كمية للطلب', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'أدخل كمية صحيحة' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'الفئة', border: OutlineInputBorder()),
                  items: _categories.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'الرجاء اختيار فئة' : null,
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _updateProduct, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)), child: const Text('حفظ التعديلات')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
