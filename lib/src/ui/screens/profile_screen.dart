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

          return NestedScrollView(
            key: const Key('profileScreen'),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(profile.role == 'admin' ? 'لوحة تحكم المدير' : 'ملفي الشخصي'),
                    background: _buildProfileHeader(profile),
                  ),
                ),
              ];
            },
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildReferralSection(profile)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      isAdmin ? 'جميع الإعلانات في التطبيق' : 'إعلاناتي',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                _buildProductGrid(isAdmin),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_pin, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              _user?.email ?? 'مستخدم غير معروف',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            if (profile.role == 'admin')
              Chip(
                label: const Text('مدير النظام'),
                backgroundColor: Colors.white.withOpacity(0.9),
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection(Profile profile) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نظام الإحالة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('الكود الخاص بك: ', style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              SelectableText(
                profile.referralCode ?? 'N/A',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                   if (profile.referralCode != null) {
                    Clipboard.setData(ClipboardData(text: profile.referralCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ كود الإحالة!')),
                    );
                  }
                },
                child: Icon(Icons.copy, size: 18, color: colorScheme.secondary),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('عدد الإحالات الناجحة: ', style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              Text(
                '${profile.referralCount}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(bool isAdmin) {
    return FutureBuilder<List<Product>>(
      future: _getProducts(isAdmin: isAdmin),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          // You could use a shimmer grid here as well for consistency
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (productSnapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text('حدث خطأ: ${productSnapshot.error}')));
        }
        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(isAdmin ? 'لا توجد إعلانات.' : 'لم تقم بنشر أي إعلانات بعد.'),
              ),
            ),
          );
        }
        final products = productSnapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.65, // Adjust ratio for controls
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  showControls: isAdmin || product.userId == _user?.id,
                  onDelete: () => _deleteProduct(product),
                  onEdit: () => _editProduct(product),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}
