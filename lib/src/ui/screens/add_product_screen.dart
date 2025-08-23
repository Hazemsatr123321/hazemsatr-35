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
  XFile? _selectedImage;

  final List<String> _categories = const [
    'إلكترونيات',
    'ملابس',
    'أثاث',
    'مركبات',
    'عقارات',
    'مواد غذائية',
    'غير ذلك',
  ];

  Future<void> _generateAdCopy() async {
    if (_aiKeywordsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء إدخال كلمات مفتاحية لوصف المنتج.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Call the Supabase Edge Function
      final response = await supabase.functions.invoke(
        'generate-ad-copy',
        body: {'keywords': _aiKeywordsController.text.trim()},
      );

      if (response.status != 200) {
        throw FunctionException(
          status: response.status,
          details: response.data,
        );
      }

      final data = response.data;
      final String aiTitle = data['title'] ?? 'خطأ في إنشاء العنوان';
      final String aiDescription = data['description'] ?? 'خطأ في إنشاء الوصف';

      _titleController.text = aiTitle;
      _descriptionController.text = aiDescription;

    } on FunctionException catch (error) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ من السيرفر: ${error.details ?? 'فشل إنشاء المحتوى'}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _getCategoryFromImage(XFile imageFile) async {
    setState(() {
      _isGenerating = true; // Reuse the same loading flag for simplicity
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تحليل الصورة لاقتراح فئة...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await supabase.functions.invoke(
        'categorize-image',
        body: {'image': base64Image},
      );

      if (response.status != 200) {
        throw FunctionException(
          status: response.status,
          details: response.data,
        );
      }

      final suggestedCategory = response.data['category'] as String?;
      if (suggestedCategory != null && _categories.contains(suggestedCategory)) {
        setState(() {
          _selectedCategory = suggestedCategory;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اقتراح الفئة: $suggestedCategory'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FunctionException catch (error) {
      // Silently fail for now, as this is an enhancement, not a critical path.
      // A snackbar could be shown here if desired.
      debugPrint('Error categorizing image: ${error.details}');
    } catch (error) {
      debugPrint('Unexpected error categorizing image: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (imageFile == null) {
      return;
    }
    setState(() {
      _selectedImage = imageFile;
    });
    // After picking the image, try to categorize it
    _getCategoryFromImage(imageFile);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء اختيار صورة للإعلان.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageFile = File(_selectedImage!.path);
      final imageExtension = _selectedImage!.path.split('.').last.toLowerCase();
      final userId = supabase.auth.currentUser!.id;
      final imagePath = '/$userId/${DateTime.now().toIso8601String()}.$imageExtension';

      // Upload image to Supabase Storage
      await supabase.storage.from('product-images').upload(
            imagePath,
            imageFile,
            fileOptions: FileOptions(contentType: 'image/$imageExtension'),
          );

      // Get public URL
      final imageUrl = supabase.storage.from('product-images').getPublicUrl(imagePath);

      // Insert product record into the database
      await supabase.from('products').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'user_id': userId,
        'image_url': imageUrl,
        'category': _selectedCategory,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعلان بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on StorageException catch (error) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      appBar: AppBar(
        title: const Text('إضافة إعلان جديد'),
      ),
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
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedImage == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('أضف صورة'),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // --- AI Generation Section ---
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'إنشاء المحتوى بالذكاء الاصطناعي',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل كلمات مفتاحية (مثل: "سيارة تويوتا كامري 2022 بيضاء")، وسيقوم الذكاء الاصطناعي بكتابة عنوان ووصف احترافي لإعلانك.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _aiKeywordsController,
                        decoration: const InputDecoration(
                          labelText: 'الكلمات المفتاحية',
                          hintText: 'مثال: لابتوب ديل مستعمل بحالة ممتازة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _isGenerating
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                key: const Key('generateWithAIButton'),
                                onPressed: _generateAdCopy,
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('إنشاء'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                // --- End AI Generation Section ---
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الإعلان',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان للإعلان';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف الإعلان',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال وصف للإعلان';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر (د.ع)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return 'الرجاء إدخال سعر صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'الفئة',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء اختيار فئة للإعلان';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        key: const Key('saveProductButton'),
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('حفظ الإعلان'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
