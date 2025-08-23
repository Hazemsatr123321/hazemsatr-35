import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
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
  late Future<List<ManagedAd>> _managedAdsFuture;
  final _user = supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  void _refreshAllData() {
    setState(() {
      _profileFuture = _getProfile();
      if (_user != null) {
        _managedAdsFuture = _getManagedAds();
      }
    });
  }

  Future<Profile> _getProfile() async {
    if (_user == null) throw 'User not logged in';
    try {
      final data = await supabase.from('profiles').select().eq('id', _user!.id).maybeSingle();
      if (data != null) {
        return Profile.fromJson(data);
      } else {
        final newProfileData = {'id': _user!.id, 'referral_code': _generateReferralCode()};
        final insertedData = await supabase.from('profiles').insert(newProfileData).select().single();
        return Profile.fromJson(insertedData);
      }
    } catch (e) { rethrow; }
  }

  String _generateReferralCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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
    } catch (e) { rethrow; }
  }

  Future<List<ManagedAd>> _getManagedAds() async {
    try {
      final data = await supabase.from('managed_ads').select().order('created_at', ascending: false);
      return (data as List).map((json) => ManagedAd.fromJson(json)).toList();
    } catch (e) { rethrow; }
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('تأكيد الحذف'), content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإعلان نهائياً؟'), actions: [TextButton(onPressed:()=>Navigator.of(c).pop(false), child: const Text('إلغاء')), TextButton(onPressed:()=>Navigator.of(c).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف'))]));
    if(shouldDelete == true) {
      await supabase.from('products').delete().eq('id', product.id);
      _refreshAllData();
    }
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProductScreen(product: product))).then((_) => _refreshAllData());
  }

  Future<void> _deleteManagedAd(String adId) async {
     final shouldDelete = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('حذف الإعلان المدار'), content: const Text('هل أنت متأكد؟'), actions: [TextButton(onPressed:()=>Navigator.of(c).pop(false), child: const Text('إلغاء')), TextButton(onPressed:()=>Navigator.of(c).pop(true), child: const Text('حذف'))]));
     if(shouldDelete == true) {
       await supabase.from('managed_ads').delete().eq('id', adId);
       _refreshAllData();
     }
  }

  Future<void> _showManagedAdDialog({ManagedAd? ad}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: ad?.title);
    final imageUrlController = TextEditingController(text: ad?.imageUrl);
    final targetUrlController = TextEditingController(text: ad?.targetUrl);
    bool isActive = ad?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ad == null ? 'إضافة إعلان مدار جديد' : 'تعديل الإعلان المدار'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'العنوان'), validator: (v)=>v!.isEmpty?'مطلوب':null),
                  const SizedBox(height: 8),
                  TextFormField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'رابط الصورة'), validator: (v)=>v!.isEmpty?'مطلوب':null),
                  const SizedBox(height: 8),
                  TextFormField(controller: targetUrlController, decoration: const InputDecoration(labelText: 'الرابط المستهدف'), validator: (v)=>v!.isEmpty?'مطلوب':null),
                  StatefulBuilder(builder: (context, setDialogState) {
                    return SwitchListTile(
                      title: const Text('فعال'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final data = {'title': titleController.text, 'image_url': imageUrlController.text, 'target_url': targetUrlController.text, 'is_active': isActive};
                  if (ad == null) {
                    await supabase.from('managed_ads').insert(data);
                  } else {
                    await supabase.from('managed_ads').update(data).eq('id', ad.id);
                  }
                  Navigator.of(context).pop();
                  _refreshAllData();
                }
              },
              child: const Text('حفظ'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('profileScreen'),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (profileSnapshot.hasError || !profileSnapshot.hasData) return const Center(child: Text('لا يمكن تحميل الملف الشخصي.'));

          final profile = profileSnapshot.data!;
          final isAdmin = profile.role == 'admin';

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(profile.role == 'admin' ? 'لوحة تحكم المدير' : 'ملفي الشخصي'),
                  background: _buildProfileHeader(profile),
                ),
              ),
            ],
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildReferralSection(profile)),
                if (isAdmin) _buildManagedAdsSection(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(isAdmin ? 'إعلانات المستخدمين' : 'إعلاناتي', style: Theme.of(context).textTheme.titleLarge),
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
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_pin, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(_user?.email ?? 'مستخدم غير معروف', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            if (profile.role == 'admin')
              Chip(label: const Text('مدير النظام'), backgroundColor: Colors.white.withOpacity(0.9), labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نظام الإحالة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(children: [
            Text('الكود الخاص بك: ', style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            SelectableText(profile.referralCode ?? 'N/A', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(width: 8),
            GestureDetector(onTap: () { if (profile.referralCode != null) { Clipboard.setData(ClipboardData(text: profile.referralCode!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الإحالة!')));}}, child: Icon(Icons.copy, size: 18, color: colorScheme.secondary))
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('عدد الإحالات الناجحة: ', style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Text('${profile.referralCount}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildManagedAdsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('إدارة الإعلانات الخارجية', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.add_circle), color: Theme.of(context).colorScheme.primary, onPressed: () => _showManagedAdDialog())
            ]),
            const SizedBox(height: 8),
            FutureBuilder<List<ManagedAd>>(
              future: _managedAdsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Text('خطأ: ${snapshot.error}');
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('لا توجد إعلانات مدارة حالياً.');
                final ads = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return Card(
                      elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Image.network(ad.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.error)),
                        title: Text(ad.title),
                        subtitle: Text(ad.isActive ? 'فعال' : 'غير فعال', style: TextStyle(color: ad.isActive ? Colors.green : Colors.red)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showManagedAdDialog(ad: ad)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteManagedAd(ad.id)),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(bool isAdmin) {
    return FutureBuilder<List<Product>>(
      future: _getProducts(isAdmin: isAdmin),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        if (productSnapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('حدث خطأ: ${productSnapshot.error}')));
        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(isAdmin ? 'لا توجد إعلانات.' : 'لم تقم بنشر أي إعلانات بعد.'))));
        final products = productSnapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.65),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(product: product, showControls: isAdmin || product.userId == _user?.id, onDelete: () => _deleteProduct(product), onEdit: () => _editProduct(product));
            }, childCount: products.length),
          ),
        );
      },
    );
  }
}
