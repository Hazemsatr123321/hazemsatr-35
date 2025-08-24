import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/providers/theme_provider.dart';
import 'package:smart_iraq/src/ui/screens/admin/admin_panel_screen.dart';

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
    _refreshAllData();
  }

  void _refreshAllData() {
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
      rethrow;
    }
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

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showCupertinoDialog<bool>(context: context, builder: (c) => CupertinoAlertDialog(title: const Text('تأكيد الحذف'), content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإعلان نهائياً؟'), actions: [CupertinoDialogAction(onPressed:()=>Navigator.of(c).pop(false), child: const Text('إلغاء')), CupertinoDialogAction(onPressed:()=>Navigator.of(c).pop(true), isDestructiveAction: true, child: const Text('حذف'))]));
    if(shouldDelete == true) {
      await supabase.from('products').delete().eq('id', product.id);
      _refreshAllData();
    }
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => EditProductScreen(product: product))).then((_) => _refreshAllData());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
        if (profileSnapshot.hasError || !profileSnapshot.hasData) return const Center(child: Text('لا يمكن تحميل الملف الشخصي.'));

        final profile = profileSnapshot.data!;
        final isAdmin = profile.role == 'admin';

        return CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(isAdmin ? 'لوحة تحكم المدير' : 'ملفي الشخصي'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.square_arrow_right),
                onPressed: () => supabase.auth.signOut(),
              )
            ),
            SliverToBoxAdapter(child: _buildBusinessInfoSection(profile)),
            SliverToBoxAdapter(child: _buildSettingsSection()),
            if (isAdmin) _buildAdminPanelButton() else _buildDashboardButton(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(isAdmin ? 'إعلانات المستخدمين' : 'إعلاناتي', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
              ),
            ),
            _buildProductGrid(isAdmin),
          ],
        );
      },
    );
  }

  Widget _buildBusinessInfoSection(Profile profile) {
    String verificationText;
    Color verificationColor;
    IconData verificationIcon;

    switch (profile.verification_status) {
      case 'approved':
        verificationText = 'موثق';
        verificationColor = Colors.green;
        verificationIcon = Icons.verified;
        break;
      case 'rejected':
        verificationText = 'مرفوض';
        verificationColor = Colors.red;
        verificationIcon = Icons.error;
        break;
      default:
        verificationText = 'قيد المراجعة';
        verificationColor = Colors.orange;
        verificationIcon = Icons.hourglass_top;
    }

    return Material( // Using Material for Card and its elevation
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('معلومات الحساب التجاري', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildInfoRow(CupertinoIcons.building_2_fill, 'اسم العمل', profile.business_name ?? 'غير محدد'),
              const SizedBox(height: 12),
              _buildInfoRow(CupertinoIcons.person_2, 'نوع الحساب', profile.business_type == 'wholesaler' ? 'تاجر جملة' : 'صاحب محل'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(verificationIcon, color: verificationColor, size: 20),
                  const SizedBox(width: 16),
                  Text('حالة الحساب:', style: Theme.of(context).textTheme.bodyLarge),
                  const Spacer(),
                  Text(verificationText, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: verificationColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
     return Row(children: [
      Icon(icon, color: Colors.grey.shade600, size: 20),
      const SizedBox(width: 16),
      Text('$label:', style: Theme.of(context).textTheme.bodyLarge),
      const Spacer(),
      Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildAdminPanelButton() {
     return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(builder: (context) => const AdminPanelScreen()),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            color: CupertinoTheme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.shield_lefthalf_fill, color: Colors.white, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'لوحة تحكم المدير',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(CupertinoIcons.forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton() {
     return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(builder: (context) => const DashboardScreen()),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(CupertinoIcons.chart_bar_square, color: CupertinoTheme.of(context).primaryColor, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'عرض لوحة معلومات التاجر',
                      style: TextStyle(
                        fontSize: 18,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Icon(CupertinoIcons.forward, color: CupertinoTheme.of(context).primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(bool isAdmin) {
     return FutureBuilder<List<Product>>(
      future: _getProducts(isAdmin: isAdmin),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CupertinoActivityIndicator()));
        if (productSnapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('حدث خطأ: ${productSnapshot.error}')));
        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(isAdmin ? 'لا توجد إعلانات.' : 'لم تقم بنشر أي إعلانات بعد.'))));
        final products = productSnapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(product: product, showControls: isAdmin || product.userId == _user?.id, onDelete: () => _deleteProduct(product), onEdit: () => _editProduct(product));
            }, childCount: products.length),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection() {
     return SliverToBoxAdapter(
       child: Material(
        color: Colors.transparent,
         child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('الوضع الليلي'),
                subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                secondary: const Icon(CupertinoIcons.moon_stars),
              );
            },
          ),
           ),
       ),
     );
  }
}
