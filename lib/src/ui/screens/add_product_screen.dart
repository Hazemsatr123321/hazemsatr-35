import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _minOrderQuantityController = TextEditingController();

  String? _selectedCategory;
  String? _selectedUnitType;
  bool _isLoading = false;
  XFile? _selectedImage;

  final List<String> _categories = const [
    'إلكترونيات', 'ملابس', 'أثاث', 'مركبات', 'عقارات', 'مواد غذائية', 'غير ذلك',
  ];
  final List<String> _unitTypes = const ['قطعة', 'كرتونة', 'درزن', 'كيلوغرام'];
  final _donationDescriptionController = TextEditingController();
  bool _isDonation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minOrderQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('الرجاء اختيار صورة للمنتج.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageFile = File(_selectedImage!.path);
      final imageExtension = _selectedImage!.path.split('.').last.toLowerCase();
      final userId = supabase.auth.currentUser!.id;
      final imagePath = '/$userId/${DateTime.now().toIso8601String()}.$imageExtension';

      await supabase.storage.from('product-images').upload(
        imagePath,
        imageFile,
        fileOptions: FileOptions(contentType: 'image/$imageExtension'),
      );

      final imageUrl = supabase.storage.from('product-images').getPublicUrl(imagePath);

      await supabase.from('products').insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'user_id': userId,
        'image_url': imageUrl,
        'category': _selectedCategory,
        'stock_quantity': int.parse(_stockQuantityController.text.trim()),
        'minimum_order_quantity': int.parse(_minOrderQuantityController.text.trim()),
        'unit_type': _selectedUnitType,
        'is_available_for_donation': _isDonation,
        'donation_description': _isDonation ? _donationDescriptionController.text.trim() : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المنتج بنجاح!'), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text('إضافة منتج جملة جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                    child: _selectedImage == null
                        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 50, color: Colors.grey), SizedBox(height: 8), Text('أضف صورة')]))
                        : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover)),
                  ),
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
                // --- Donation Section ---
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('التبرع بجزء من المنتج للفقراء'),
                        subtitle: const Text('سيتم عرض هذا التبرع في صفحة دعم الفقراء'),
                        value: _isDonation,
                        onChanged: (bool value) {
                          setState(() {
                            _isDonation = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      if (_isDonation) ...[
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _donationDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'وصف الجزء المتبرع به',
                            hintText: 'مثال: كرتونة واحدة من كل 10 كراتين',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => _isDonation && (v == null || v.isEmpty) ? 'الرجاء إدخال وصف للتبرع' : null,
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _saveProduct, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)), child: const Text('حفظ المنتج')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
