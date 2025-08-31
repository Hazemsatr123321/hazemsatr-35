import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  final _aiKeywordsController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSuggestingPrice = false;

  final List<String> _categories = const [
    'إلكترونيات', 'ملابس', 'أثاث', 'مركبات', 'عقارات', 'مواد غذائية', 'غير ذلك',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    if (widget.product.category != null && _categories.contains(widget.product.category)) {
      _selectedCategory = widget.product.category;
    }
  }

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

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.from('products').update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory,
      }).eq('id', widget.product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الإعلان بنجاح!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true); // Pop with a result to indicate success
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
      appBar: AppBar(title: const Text('تعديل الإعلان')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExistingImage(),
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
                onPressed: _updateProduct,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('حفظ التعديلات'),
              ),
      ),
    );
  }

  Widget _buildExistingImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            );
          },
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
          Text('أدخل كلمات مفتاحية جديدة، وسيقوم الذكاء الاصطناعي بتحديث عنوان ووصف إعلانك.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _aiKeywordsController,
            decoration: const InputDecoration(labelText: 'الكلمات المفتاحية', hintText: 'مثال: لابتوب ديل بسعر مخفض'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _isGenerating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _generateAdCopy,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('تحديث المحتوى'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
