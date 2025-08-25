import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart' as custom;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  void _showPicker(BuildContext context, {required List<String> options, required ValueChanged<String> onSelectedItemChanged}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoPicker(
          itemExtent: 32.0,
          onSelectedItemChanged: (int index) {
            onSelectedItemChanged(options[index]);
          },
          children: options.map((String value) => Center(child: Text(value))).toList(),
        ),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  String _listingType = 'sale'; // 'sale' or 'auction'

  // Common controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _minOrderQuantityController = TextEditingController();

  // Sale-specific controllers
  final _priceController = TextEditingController();

  // Auction-specific controllers
  final _startPriceController = TextEditingController();
  final _endDateController = TextEditingController();
  DateTime? _auctionEndDate;

  String? _selectedCategory;
  String? _selectedUnitType;
  bool _isLoading = false;
  XFile? _selectedImage;

  final List<String> _categories = const ['إلكترونيات', 'ملابس', 'أثاث', 'مركبات', 'عقارات', 'مواد غذائية', 'غير ذلك'];
  final List<String> _unitTypes = const ['قطعة', 'كرتونة', 'درزن', 'كيلوغرام'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minOrderQuantityController.dispose();
    _startPriceController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (imageFile != null) setState(() => _selectedImage = imageFile);
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('موافق'), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      _showErrorDialog('الرجاء اختيار صورة للمنتج.');
      return;
    }
    if (_listingType == 'auction' && _auctionEndDate == null) {
      _showErrorDialog('الرجاء تحديد تاريخ انتهاء المزاد.');
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

      final Map<String, dynamic> productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'user_id': userId,
        'image_url': imageUrl,
        'category': _selectedCategory,
        'stock_quantity': int.parse(_stockQuantityController.text.trim()),
        'minimum_order_quantity': int.parse(_minOrderQuantityController.text.trim()),
        'unit_type': _selectedUnitType,
        'listing_type': _listingType,
      };

      if (_listingType == 'auction') {
        productData.addAll({
          'start_price': double.parse(_startPriceController.text.trim()),
          'end_time': _auctionEndDate!.toIso8601String(),
          'price': null, // No fixed price for auctions
        });
      } else {
        productData['price'] = double.parse(_priceController.text.trim());
      }

      await supabase.from('products').insert(productData);

      if (mounted) Navigator.of(context).pop();

    } catch (error) {
      if (mounted) _showErrorDialog('حدث خطأ: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppTheme.darkSurface,
        child: CupertinoDatePicker(
          initialDateTime: DateTime.now().add(const Duration(days: 7)),
          minimumDate: DateTime.now(),
          mode: CupertinoDatePickerMode.dateAndTime,
          onDateTimeChanged: (DateTime newDate) {
            setState(() {
              _auctionEndDate = newDate;
              _endDateController.text = DateFormat('yyyy-MM-dd HH:mm', 'ar').format(newDate);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('إضافة إعلان جديد')),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ... (Image Picker remains the same)
              const SizedBox(height: 24),
              CupertinoFormSection.insetGrouped(
                header: const Text('نوع الإعلان'),
                children: [
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: _listingType,
                    onValueChanged: (value) => setState(() => _listingType = value!),
                    children: const {
                      'sale': Text('سعر ثابت'),
                      'auction': Text('مزاد'),
                    },
                  ),
                ],
              ),
              CupertinoFormSection.insetGrouped(
                header: const Text('المعلومات الأساسية'),
                children: [
                  CupertinoTextFormFieldRow(controller: _nameController, prefix: const Text('الاسم'), placeholder: 'اسم المنتج', validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                  CupertinoTextFormFieldRow(controller: _descriptionController, prefix: const Text('الوصف'), placeholder: 'وصف المنتج', maxLines: 4, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                   custom.CupertinoListTile(
                    title: const Text('الفئة'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(_selectedCategory ?? 'اختر'), const SizedBox(width: 8), const custom.CupertinoListTileChevron()]),
                    onTap: () => _showPicker(context, options: _categories, onSelectedItemChanged: (val) => setState(() => _selectedCategory = val))),
                ],
              ),
              if (_listingType == 'sale')
                CupertinoFormSection.insetGrouped(
                  header: const Text('التسعير (سعر ثابت)'),
                  children: [
                    CupertinoTextFormFieldRow(controller: _priceController, prefix: const Text('السعر'), placeholder: 'سعر الوحدة', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                  ],
                ),
              if (_listingType == 'auction')
                CupertinoFormSection.insetGrouped(
                  header: const Text('التسعير (مزاد)'),
                  children: [
                     CupertinoTextFormFieldRow(controller: _startPriceController, prefix: const Text('السعر الابتدائي'), placeholder: 'أقل سعر للبدء', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                     CupertinoTextFormFieldRow(controller: _endDateController, prefix: const Text('تاريخ الانتهاء'), placeholder: 'اختر تاريخ ووقت', readOnly: true, onTap: _showDatePicker),
                  ],
                ),
              CupertinoFormSection.insetGrouped(
                 header: const Text('معلومات الجملة'),
                 children: [
                    CupertinoTextFormFieldRow(controller: _stockQuantityController, prefix: const Text('الكمية'), placeholder: 'الكمية المتوفرة', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                    CupertinoTextFormFieldRow(controller: _minOrderQuantityController, prefix: const Text('أقل طلب'), placeholder: 'أقل كمية للطلب', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                    custom.CupertinoListTile(
                      title: const Text('الوحدة'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(_selectedUnitType ?? 'اختر'), const SizedBox(width: 8), const custom.CupertinoListTileChevron()]),
                      onTap: () => _showPicker(context, options: _unitTypes, onSelectedItemChanged: (val) => setState(() => _selectedUnitType = val))),
                 ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(onPressed: _saveProduct, child: const Text('حفظ الإعلان')),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget because the default one is not a FormField
class CupertinoTextFormFieldRow extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final Widget prefix;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  const CupertinoTextFormFieldRow({
    Key? key,
    required this.controller,
    required this.placeholder,
    required this.prefix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      prefix: prefix,
      child: CupertinoTextFormField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
