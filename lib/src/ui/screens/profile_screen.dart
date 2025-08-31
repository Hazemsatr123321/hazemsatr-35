import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/dashboard_screen.dart';
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
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _getProfile();
    });
  }

  Future<Profile> _getProfile() async {
    if (_user == null) throw 'User not logged in';
    try {
      final data = await supabase.from('profiles').select().eq('id', _user!.id).single();
      return Profile.fromJson(data);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') { // Not found
        final newProfileData = {'id': _user!.id, 'username': _user!.email?.split('@').first, 'referral_code': _generateReferralCode()};
        final insertedData = await supabase.from('profiles').insert(newProfileData).select().single();
        return Profile.fromJson(insertedData);
      }
      rethrow;
    }
  }

  String _generateReferralCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<List<Product>> _getUserProducts() async {
    if (_user == null) return [];
    final data = await supabase.from('products').select().eq('user_id', _user!.id).order('created_at', ascending: false);
    return (data as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<void> _deleteProduct(String productId) async {
    final shouldDelete = await _showConfirmationDialog('تأكيد الحذف', 'هل أنت متأكد من رغبتك في حذف هذا الإعلان نهائياً؟');
    if (shouldDelete == true) {
      try {
        await supabase.from('products').delete().eq('id', productId);
        _refreshProfile(); // This will trigger a rebuild and refetch of products
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (context) => EditProductScreen(product: product)));
    if (result == true) {
      _refreshProfile();
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('تأكيد')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              // The auth listener will handle navigation
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) return Center(child: Text('خطأ في تحميل الملف الشخصي: ${snapshot.error}'));

          final profile = snapshot.data!;
          final isAdmin = profile.role == 'admin';

          return RefreshIndicator(
            onRefresh: () async => _refreshProfile(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildProfileHeader(profile)),
                SliverToBoxAdapter(child: _buildReferralSection(profile)),
                if (!isAdmin) SliverToBoxAdapter(child: _buildDashboardButton(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(isAdmin ? 'جميع الإعلانات' : 'إعلاناتي', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ),
                _buildUserProductsList(isAdmin),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              profile.username?.substring(0, 1).toUpperCase() ?? _user!.email!.substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.username ?? 'مستخدم', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(_user!.email!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                if (profile.role == 'admin') ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: const Text('مدير النظام'),
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(Profile profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نظام الإحالة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('الكود الخاص بك:', style: Theme.of(context).textTheme.bodyLarge),
                const Spacer(),
                SelectableText(
                  profile.referralCode ?? 'N/A',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (profile.referralCode != null) {
                      Clipboard.setData(ClipboardData(text: profile.referralCode!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الإحالة!')));
                    }
                  },
                  child: Icon(Icons.copy_all_outlined, size: 20, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Text('عدد الإحالات:', style: Theme.of(context).textTheme.bodyLarge),
                const Spacer(),
                Text('${profile.referralCount}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DashboardScreen())),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        leading: Icon(Icons.dashboard_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text('لوحة معلومات التاجر', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildUserProductsList(bool isAdmin) {
    // This should be adapted if admins need to see all products
    return FutureBuilder<List<Product>>(
      future: _getUserProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text('خطأ في تحميل الإعلانات: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48.0), child: Text('لم تقم بنشر أي إعلانات بعد.'))));
        }
        final products = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ProductCard(
                  product: product,
                  showControls: true,
                  onDelete: () => _deleteProduct(product.id),
                  onEdit: () => _editProduct(product),
                ),
              );
            },
            childCount: products.length,
          ),
        );
      },
    );
  }
}
