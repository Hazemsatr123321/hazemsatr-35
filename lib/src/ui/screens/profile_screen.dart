import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/screens/admin/admin_panel_screen.dart';
import 'package:smart_iraq/src/ui/screens/dashboard_screen.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/feature/feature_ad_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile/my_purchases_screen.dart';
import 'package:smart_iraq/src/ui/screens/reviews_list_screen.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:smart_iraq/src/ui/widgets/notification_icon.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Profile> _profileFuture;
  late Future<int> _reviewCountFuture;
  User? _user;
  late SupabaseClient _supabase;

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
      _reviewCountFuture = _getReviewCount();
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

  Future<int> _getReviewCount() async {
    if (_user == null) return 0;
    try {
      final response = await _supabase
          .from('reviews')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('seller_id', _user!.id);
      return response.count;
    } catch (e) {
      return 0;
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showCupertinoDialog<bool>(
        context: context,
        builder: (c) => CupertinoAlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإعلان نهائياً؟'),
              actions: [
                CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(false), child: const Text('إلغاء')),
                CupertinoDialogAction(
                    onPressed: () => Navigator.of(c).pop(true), isDestructiveAction: true, child: const Text('حذف'))
              ],
            ));
    if (shouldDelete == true) {
      await _supabase.from('products').delete().eq('id', product.id);
      _refreshAllData();
    }
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => EditProductScreen(product: product))).then((_) => _refreshAllData());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) return const CustomLoadingIndicator();
          if (profileSnapshot.hasError || !profileSnapshot.hasData) {
            return Center(child: Text('لا يمكن تحميل الملف الشخصي: ${profileSnapshot.error}'));
          }

          final profile = profileSnapshot.data!;
          final isAdmin = profile.role == 'admin';

          return CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                leading: const NotificationIcon(),
                largeTitle: Text(isAdmin ? 'لوحة تحكم المدير' : 'ملفي الشخصي'),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.square_arrow_right),
                  onPressed: () => _supabase.auth.signOut(),
                ),
              ),
              SliverToBoxAdapter(child: _buildBusinessInfoSection(profile)),
              if (isAdmin) _buildAdminPanelButton() else _buildDashboardButton(),
              if (!isAdmin) _buildMyPurchasesButton(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(isAdmin ? 'إعلانات المستخدمين' : 'إعلاناتي',
                      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                ),
              ),
              _buildProductGrid(isAdmin),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBusinessInfoSection(Profile profile) {
    final theme = CupertinoTheme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('معلومات الحساب التجاري', style: textTheme.navTitleTextStyle),
              _buildReputationBadge(profile.seller_tier),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(CupertinoIcons.building_2_fill, 'اسم العمل', profile.business_name ?? 'غير محدد'),
          const SizedBox(height: 12),
          _buildInfoRow(CupertinoIcons.person_2, 'نوع الحساب',
              profile.business_type == 'wholesaler' ? 'تاجر جملة' : 'صاحب محل'),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.charcoalBackground),
          const SizedBox(height: 12),
          _buildRatingSection(profile),
        ],
      ),
    );
  }

  Widget _buildReputationBadge(String? tier) {
    IconData icon;
    Color color;
    String text = tier ?? 'New Seller';

    switch (text) {
      case 'Power Seller':
        icon = CupertinoIcons.checkmark_seal_fill;
        color = AppTheme.goldAccent;
        break;
      case 'Top Seller':
        icon = CupertinoIcons.star_circle_fill;
        color = CupertinoColors.systemGreen;
        break;
      case 'Rising Star':
        icon = CupertinoIcons.flame_fill;
        color = CupertinoColors.systemOrange;
        break;
      default: // New Seller
        icon = CupertinoIcons.person_badge_plus;
        color = AppTheme.secondaryTextColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    return Row(children: [
      Icon(icon, color: AppTheme.secondaryTextColor, size: 20),
      const SizedBox(width: 16),
      Text('$label:', style: textTheme.textStyle.copyWith(color: AppTheme.secondaryTextColor)),
      const Spacer(),
      Text(value, style: textTheme.textStyle.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildAdminPanelButton() => _buildPanelButton(
    title: 'لوحة تحكم المدير',
    icon: CupertinoIcons.shield_lefthalf_fill,
    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const AdminPanelScreen())),
    isPrimary: true,
  );

  Widget _buildDashboardButton() => _buildPanelButton(
    title: 'عرض لوحة معلومات التاجر',
    icon: CupertinoIcons.chart_bar_square,
    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const DashboardScreen())),
  );

  Widget _buildMyPurchasesButton() => _buildPanelButton(
    title: 'عرض مشترياتي',
    icon: CupertinoIcons.shopping_cart,
    onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const MyPurchasesScreen())),
  );

  Widget _buildPanelButton({required String title, required IconData icon, required VoidCallback onTap, bool isPrimary = false}) {
    final theme = CupertinoTheme.of(context);
    final color = isPrimary ? AppTheme.goldAccent : AppTheme.darkSurface;
    final textColor = isPrimary ? CupertinoColors.black : AppTheme.lightTextColor;

    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: theme.textTheme.navTitleTextStyle.copyWith(color: textColor))),
              Icon(CupertinoIcons.forward, color: textColor),
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
        if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(isAdmin ? 'لا توجد إعلانات.' : 'لم تقم بنشر أي إعلانات بعد.'))));
        }
        final products = productSnapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                showControls: isAdmin || product.userId == _user?.id,
                onDelete: () => _deleteProduct(product),
                onEdit: () => _editProduct(product),
                onFeature: product.is_featured ? null : () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => FeatureAdScreen(product: product),
                  ));
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (100 * (index % 2)).ms)
                  .slideY(begin: 0.5, duration: 500.ms, delay: (100 * (index % 2)).ms, curve: Curves.easeOut);
            }, childCount: products.length),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(Profile profile) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    return FutureBuilder<int>(
        future: _reviewCountFuture,
        builder: (context, snapshot) {
          final reviewCount = snapshot.data ?? 0;
          return GestureDetector(
            onTap: () {
              if (reviewCount > 0) {
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
                    Text('تقييم التاجر', style: textTheme.textStyle.copyWith(fontWeight: FontWeight.bold)),
                    if (reviewCount > 0)
                      const Icon(CupertinoIcons.forward, size: 18, color: CupertinoColors.systemGrey)
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStarRating(profile.reputation_score ?? 0),
                    const SizedBox(width: 8),
                    Text(
                      '${(profile.reputation_score ?? 0).toStringAsFixed(1)} ($reviewCount تقييم)',
                      style: textTheme.textStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
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
        return Icon(icon, color: AppTheme.goldAccent, size: 20);
      }),
    );
  }
}
