import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Using Material Form for validation
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart';
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
    _donationDescriptionController.dispose();
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

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('موافق'), onPressed: () => Navigator.of(context).pop())],
      )
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      _showErrorDialog('الرجاء اختيار صورة للمنتج.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
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
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog('حدث خطأ: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPicker(BuildContext context, {required List<String> options, required Function(String) onSelectedItemChanged}) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoPicker(
              magnification: 1.22,
              squeeze: 1.2,
              useMagnifier: true,
              itemExtent: 32.0,
              onSelectedItemChanged: (int selectedIndex) {
                  onSelectedItemChanged(options[selectedIndex]);
              },
              children: List<Widget>.generate(options.length, (int index) {
                return Center(child: Text(options[index]));
              }),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('إضافة منتج جملة جديد')),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: CupertinoColors.lightBackgroundGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CupertinoColors.separator)
                  ),
                  child: _selectedImage == null
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.photo_camera, size: 50, color: CupertinoColors.secondaryLabel), SizedBox(height: 8), Text('أضف صورة')]))
                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 24.0),
              CupertinoFormSection(
                header: const Text('المعلومات الأساسية'),
                children: [
                  CupertinoTextFormFieldRow(controller: _nameController, prefix: const Text('الاسم'), placeholder: 'اسم المنتج', validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                  CupertinoTextFormFieldRow(controller: _descriptionController, prefix: const Text('الوصف'), placeholder: 'وصف المنتج', maxLines: 4, validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                  CupertinoTextFormFieldRow(controller: _priceController, prefix: const Text('السعر'), placeholder: 'سعر الوحدة', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'رقم صالح مطلوب' : null),
                  CupertinoListTile(title: const Text('الفئة'), additionalInfo: Text(_selectedCategory ?? 'اختر'), trailing: const CupertinoListTileChevron(), onTap: () => _showPicker(context, options: _categories, onSelectedItemChanged: (val) => setState(() => _selectedCategory = val))),
                ],
              ),
              CupertinoFormSection(
                 header: const Text('معلومات الجملة'),
                 children: [
                    CupertinoTextFormFieldRow(controller: _stockQuantityController, prefix: const Text('الكمية'), placeholder: 'الكمية المتوفرة', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'رقم صالح مطلوب' : null),
                    CupertinoTextFormFieldRow(controller: _minOrderQuantityController, prefix: const Text('أقل طلب'), placeholder: 'أقل كمية للطلب', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'رقم صالح مطلوب' : null),
                    CupertinoListTile(title: const Text('الوحدة'), additionalInfo: Text(_selectedUnitType ?? 'اختر'), trailing: const CupertinoListTileChevron(), onTap: () => _showPicker(context, options: _unitTypes, onSelectedItemChanged: (val) => setState(() => _selectedUnitType = val))),
                 ],
              ),
              CupertinoFormSection(
                header: const Text('مساهمة خيرية (اختياري)'),
                children: [
                  CupertinoListTile(
                    title: const Text('التبرع بجزء من المنتج'),
                    trailing: CupertinoSwitch(value: _isDonation, onChanged: (val) => setState(() => _isDonation = val)),
                  ),
                   if (_isDonation)
                    CupertinoTextFormFieldRow(
                      controller: _donationDescriptionController,
                      prefix: const Text('الوصف'),
                      placeholder: 'مثال: كرتونة لكل 10',
                      validator: (v) => _isDonation && (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(onPressed: _saveProduct, child: const Text('حفظ المنتج')),
            ],
          ),
        ),
      ),
    );
  }
}
