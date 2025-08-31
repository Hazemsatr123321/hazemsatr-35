import 'dart:convert';
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _aiKeywordsController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSuggestingPrice = false;
  XFile? _selectedImage;

  final List<String> _categories = const [
    'إلكترونيات', 'ملابس', 'أثاث', 'مركبات', 'عقارات', 'مواد غذائية', 'غير ذلك',
  ];

  Future<void> _generateAdCopy() async {
    if (_aiKeywordsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء إدخال كلمات مفتاحية لوصف المنتج.'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final response = await supabase.functions.invoke('generate-ad-copy', body: {'keywords': _aiKeywordsController.text.trim()});
      if (response.status != 200) throw FunctionException(status: response.status, details: response.data);
      final data = response.data;
      _titleController.text = data['title'] ?? 'خطأ في إنشاء العنوان';
      _descriptionController.text = data['description'] ?? 'خطأ في إنشاء الوصف';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء المحتوى: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _suggestPrice() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء إدخال العنوان، الوصف، والفئة أولاً لاقتراح سعر.'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    setState(() => _isSuggestingPrice = true);
    try {
      final response = await supabase.functions.invoke('suggest-price', body: {'title': _titleController.text, 'description': _descriptionController.text, 'category': _selectedCategory});
      final suggestedPrice = response.data['suggested_price']?.toString();
      if (suggestedPrice != null) {
        _priceController.text = suggestedPrice;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اقتراح السعر: $suggestedPrice د.ع'), backgroundColor: Colors.green));
      } else {
        throw 'No price suggested';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء اقتراح السعر: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _isSuggestingPrice = false);
    }
  }

  Future<void> _getCategoryFromImage(XFile imageFile) async {
    setState(() => _isGenerating = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تحليل الصورة لاقتراح فئة...'), backgroundColor: Colors.blue));
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final response = await supabase.functions.invoke('categorize-image', body: {'image': base64Image});
      if (response.status != 200) throw FunctionException(status: response.status, details: response.data);
      final suggestedCategory = response.data['category'] as String?;
      if (suggestedCategory != null && _categories.contains(suggestedCategory)) {
        setState(() => _selectedCategory = suggestedCategory);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اقتراح الفئة: $suggestedCategory'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Error categorizing image: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (imageFile != null) {
      setState(() => _selectedImage = imageFile);
      await _getCategoryFromImage(imageFile);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الرجاء اختيار صورة للإعلان.'), backgroundColor: Theme.of(context).colorScheme.error));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final imageFile = File(_selectedImage!.path);
      final imageExtension = _selectedImage!.path.split('.').last.toLowerCase();
      final userId = supabase.auth.currentUser!.id;
      final imagePath = '/$userId/${DateTime.now().toIso8601String()}.$imageExtension';
      await supabase.storage.from('product-images').upload(imagePath, imageFile, fileOptions: FileOptions(contentType: 'image/$imageExtension'));
      final imageUrl = supabase.storage.from('product-images').getPublicUrl(imagePath);
      await supabase.from('products').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'user_id': userId,
        'image_url': imageUrl,
        'category': _selectedCategory,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعلان بنجاح!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _aiKeywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة إعلان جديد')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildAiSection(),
              const SizedBox(height: 24),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان الإعلان'), validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'وصف الإعلان'), maxLines: 5, validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'السعر (د.ع)',
                  suffixIcon: _isSuggestingPrice
                      ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(icon: Icon(Icons.auto_fix_high, color: Theme.of(context).colorScheme.secondary), onPressed: _suggestPrice, tooltip: 'اقتراح سعر ذكي'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'سعر غير صحيح' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'الرجاء اختيار فئة' : null,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('حفظ الإعلان'),
              ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: _selectedImage == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text('أضف صورة', style: TextStyle(color: Colors.grey.shade800)),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildAiSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text('مساعد الإعلان الذكي', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('أدخل كلمات مفتاحية (مثل: "سيارة تويوتا كامري 2022 بيضاء")، وسيقوم الذكاء الاصطناعي بكتابة عنوان ووصف احترافي لإعلانك.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _aiKeywordsController,
            decoration: const InputDecoration(labelText: 'الكلمات المفتاحية', hintText: 'مثال: لابتوب ديل مستعمل بحالة ممتازة'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _isGenerating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _generateAdCopy,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('إنشاء المحتوى'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
