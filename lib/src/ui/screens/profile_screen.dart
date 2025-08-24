import 'package:flutter/cupertino.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/dashboard_screen.dart';
import 'package:smart_iraq/src/ui/screens/reviews_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/providers/theme_provider.dart';
import 'package:smart_iraq/src/ui/screens/admin/admin_panel_screen.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Profile> _profileFuture;
  User? _user;
  late SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _user = _supabase.auth.currentUser;
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
      final data = await _supabase.from('profiles').select().eq('id', _user!.id).single();
      return Profile.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> _getProducts({required bool isAdmin}) async {
    if (_user == null) return [];
    try {
      var query = _supabase.from('products').select();
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
      await _supabase.from('products').delete().eq('id', product.id);
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
        if (profileSnapshot.connectionState == ConnectionState.waiting) return const CustomLoadingIndicator();
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
                onPressed: () => _supabase.auth.signOut(),
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
    CupertinoDynamicColor verificationColor;
    IconData verificationIcon;
    final theme = CupertinoTheme.of(context);
    final textTheme = theme.textTheme;

    switch (profile.verification_status) {
      case 'approved':
        verificationText = 'موثق';
        verificationColor = CupertinoColors.activeGreen;
        verificationIcon = CupertinoIcons.checkmark_seal_fill;
        break;
      case 'rejected':
        verificationText = 'مرفوض';
        verificationColor = CupertinoColors.destructiveRed;
        verificationIcon = CupertinoIcons.xmark_seal_fill;
        break;
      default:
        verificationText = 'قيد المراجعة';
        verificationColor = CupertinoColors.systemYellow;
        verificationIcon = CupertinoIcons.hourglass;
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات الحساب التجاري', style: textTheme.navTitleTextStyle),
          const SizedBox(height: 16),
          _buildInfoRow(CupertinoIcons.building_2_fill, 'اسم العمل', profile.business_name ?? 'غير محدد'),
          const SizedBox(height: 12),
          _buildInfoRow(CupertinoIcons.person_2, 'نوع الحساب', profile.business_type == 'wholesaler' ? 'تاجر جملة' : 'صاحب محل'),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(verificationIcon, color: verificationColor, size: 20),
              const SizedBox(width: 16),
              Text('حالة الحساب:', style: textTheme.textStyle),
              const Spacer(),
              Text(verificationText, style: textTheme.textStyle.copyWith(fontWeight: FontWeight.bold, color: verificationColor)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),
          const SizedBox(height: 12),
          _buildRatingSection(profile),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
     final textTheme = CupertinoTheme.of(context).textTheme;
     return Row(children: [
      Icon(icon, color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 20),
      const SizedBox(width: 16),
      Text('$label:', style: textTheme.textStyle),
      const Spacer(),
      Text(value, style: textTheme.textStyle.copyWith(fontWeight: FontWeight.bold)),
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.shield_lefthalf_fill, color: CupertinoColors.white, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'لوحة تحكم المدير',
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.forward, color: CupertinoColors.white),
            ],
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.chart_bar_square, color: CupertinoTheme.of(context).primaryColor, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'عرض لوحة معلومات التاجر',
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
              ),
              Icon(CupertinoIcons.forward, color: CupertinoTheme.of(context).primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(bool isAdmin) {
     return FutureBuilder<List<Product>>(
      future: _getProducts(isAdmin: isAdmin),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: CustomLoadingIndicator());
        if (productSnapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('حدث خطأ: ${productSnapshot.error}')));
        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(isAdmin ? 'لا توجد إعلانات.' : 'لم تقم بنشر أي إعلانات بعد.'))));
        final products = productSnapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(product: product, showControls: isAdmin || product.userId == _user?.id, onDelete: () => _deleteProduct(product), onEdit: () => _editProduct(product))
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (100 * (index % 2)).ms)
                  .slideY(begin: 0.5, duration: 500.ms, delay: (100 * (index % 2)).ms, curve: Curves.easeOut);
            }, childCount: products.length),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return CupertinoListTile(
              title: const Text('الوضع الليلي'),
              subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
              leading: const Icon(CupertinoIcons.moon_stars),
              trailing: CupertinoSwitch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingSection(Profile profile) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        if (profile.rating_count > 0) {
          Navigator.of(context).push(
            CupertinoPageRoute(builder: (context) => ReviewsListScreen(revieweeId: profile.id)),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقييم التاجر',
                style: textTheme.body.copyWith(fontWeight: FontWeight.bold),
              ),
              if (profile.rating_count > 0)
                const Icon(CupertinoIcons.forward, size: 18, color: CupertinoColors.systemGrey)
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStarRating(profile.average_rating),
              const SizedBox(width: 8),
              Text(
                '${profile.average_rating.toStringAsFixed(1)} (${profile.rating_count} تقييم)',
                style: textTheme.textStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index >= rating) {
          icon = CupertinoIcons.star;
        } else if (index > rating - 1 && index < rating) {
          icon = CupertinoIcons.star_lefthalf_fill;
        } else {
          icon = CupertinoIcons.star_fill;
        }
        return Icon(icon, color: CupertinoColors.systemYellow, size: 20);
      }),
    );
  }
}
