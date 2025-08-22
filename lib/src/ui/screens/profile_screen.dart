import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Product>> _myProductsFuture;
  late Future<Profile> _profileFuture;
  final _user = supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _myProductsFuture = _getMyProducts();
    _profileFuture = _getProfile();
  }

  Future<List<Product>> _getMyProducts() async {
    if (_user == null) return [];
    try {
      final data = await supabase
          .from('products')
          .select()
          .eq('user_id', _user!.id)
          .order('created_at', ascending: false);
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      rethrow;
    }
  }

  String _generateReferralCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<Profile> _getProfile() async {
    if (_user == null) throw 'User not logged in';
    try {
      final data = await supabase.from('profiles').select().eq('id', _user!.id).maybeSingle();
      if (data != null) {
        return Profile.fromJson(data);
      } else {
        // Profile doesn't exist, create one
        final newProfile = {
          'id': _user!.id,
          'referral_code': _generateReferralCode(),
        };
        final insertedData = await supabase.from('profiles').insert(newProfile).select().single();
        return Profile.fromJson(insertedData);
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإعلان نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await supabase.from('products').delete().eq('id', product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم حذف الإعلان بنجاح.'),
            backgroundColor: Colors.green,
          ));
          setState(() { _myProductsFuture = _getMyProducts(); });
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('حدث خطأ أثناء حذف الإعلان.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      }
    }
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
    ).then((_) => setState(() {
      // Refresh the list when coming back from the edit screen
      _myProductsFuture = _getMyProducts();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي')),
      body: ListView(
        children: [
          _buildProfileHeader(),
          const Divider(),
          _buildReferralSection(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('إعلاناتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildProductList(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.person, size: 40, color: Colors.grey),
          const SizedBox(width: 16.0),
          Text(_user?.email ?? 'مستخدم غير معروف', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildReferralSection() {
    return FutureBuilder<Profile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('لا يمكن تحميل معلومات الإحالة.'));
        }
        final profile = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نظام الإحالة', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(
                  text: 'كود الإحالة الخاص بك: ',
                  children: [
                    TextSpan(
                      text: profile.referralCode ?? 'لا يوجد',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('عدد الإحالات: ${profile.referralCount}'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  if (profile.referralCode != null) {
                    Clipboard.setData(ClipboardData(text: profile.referralCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ كود الإحالة!')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('نسخ الكود'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    return FutureBuilder<List<Product>>(
      future: _myProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('لم تقم بنشر أي إعلانات بعد.'),
          ));
        }
        final products = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              showControls: true,
              onDelete: () => _deleteProduct(product),
              onEdit: () => _editProduct(product),
            );
          },
        );
      },
    );
  }
}
