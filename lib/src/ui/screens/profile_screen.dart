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
  late Future<Profile> _profileFuture;
  final _user = supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  Future<Profile> _getProfile() async {
    if (_user == null) throw 'User not logged in';
    try {
      final data = await supabase.from('profiles').select().eq('id', _user!.id).maybeSingle();
      if (data != null) {
        return Profile.fromJson(data);
      } else {
        final newProfileData = {
          'id': _user!.id,
          'referral_code': _generateReferralCode(),
        };
        final insertedData = await supabase.from('profiles').insert(newProfileData).select().single();
        return Profile.fromJson(insertedData);
      }
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

  Future<List<Product>> _getProducts({required bool isAdmin}) async {
    if (_user == null) return [];
    try {
      var query = supabase.from('products').select();
      if (!isAdmin) {
        query = query.eq('user_id', _user!.id);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((json) => Product.fromJson(json)).toList();
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
          setState(() { _profileFuture = _getProfile(); });
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
      _profileFuture = _getProfile();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي')),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profileSnapshot.hasError || !profileSnapshot.hasData) {
            return const Center(child: Text('لا يمكن تحميل الملف الشخصي.'));
          }

          final profile = profileSnapshot.data!;
          final isAdmin = profile.role == 'admin';

          return ListView(
            children: [
              _buildProfileHeader(profile),
              const Divider(),
              _buildReferralSection(profile),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  isAdmin ? 'جميع الإعلانات' : 'إعلاناتي',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildProductList(isAdmin),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.person, size: 40, color: Colors.grey),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_user?.email ?? 'مستخدم غير معروف', style: Theme.of(context).textTheme.titleLarge),
              if (profile.role == 'admin')
                Text(
                  'مدير النظام',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(Profile profile) {
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
  }

  Widget _buildProductList(bool isAdmin) {
    return FutureBuilder<List<Product>>(
      future: _getProducts(isAdmin: isAdmin),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (productSnapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${productSnapshot.error}'));
        }
        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(isAdmin ? 'لا توجد إعلانات.' : 'لم تقم بنشر أي إعلانات بعد.'),
          ));
        }
        final products = productSnapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              showControls: isAdmin || product.userId == _user?.id,
              onDelete: () => _deleteProduct(product),
              onEdit: () => _editProduct(product),
            );
          },
        );
      },
    );
  }
}
