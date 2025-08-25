import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/leave_review_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile/seller_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Future<Product> _productFuture;
  late SupabaseClient _supabase;
  late ChatRepository _chatRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _chatRepository = Provider.of<ChatRepository>(context, listen: false);
    _productFuture = _getProduct();
  }

  Future<Product> _getProduct() async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, profiles(*)') // Join with profiles table
          .eq('id', widget.productId)
          .single();
      return Product.fromJson(data);
    } catch (error) {
      rethrow;
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(context).pop(), child: const Text('موافق'))],
      ),
    );
  }

  Future<void> _startChat(String sellerId, String productName) async {
    try {
      final roomId = await _chatRepository.findOrCreateChatRoom(sellerId);
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ChatScreen(
              roomId: roomId,
              chatRepository: _chatRepository,
              initialMessage: 'مرحباً، أستفسر بخصوص منتج: $productName',
            ),
          ),
        );
      }
    } catch (error) {
       if (mounted) _showErrorDialog('حدث خطأ أثناء بدء المحادثة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      key: const Key('productDetailScreen'),
      child: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('لم يتم العثور على المنتج.'));
          }

          final product = snapshot.data!;
          final isMyProduct = product.userId == _supabase.auth.currentUser?.id;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: Text(product.name),
                    stretch: true,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (product.imageUrl != null) Image.network(product.imageUrl!),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.seller != null) _buildSellerInfo(product.seller!),
                              const SizedBox(height: 24.0),
                              _buildPriceChip(context, product),
                              const SizedBox(height: 24.0),
                              _buildSectionTitle(context, 'الوصف'),
                              const SizedBox(height: 12.0),
                              Text(
                                product.description ?? 'لا يوجد وصف متاح لهذا المنتج.',
                                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(height: 1.6),
                              ),
                              const SizedBox(height: 80),
                            ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildBottomActionBar(product, isMyProduct),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSellerInfo(Profile seller) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (context) => SellerProfileScreen(sellerId: seller.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.person_alt_circle, size: 40, color: AppTheme.secondaryTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(seller.business_name ?? 'بائع غير معروف', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildReputationBadge(seller.seller_tier),
                      const SizedBox(width: 8),
                      _buildStarRating(seller.reputation_score ?? 0),
                      const SizedBox(width: 4),
                      Text(
                        (seller.reputation_score ?? 0).toStringAsFixed(1),
                        style: const TextStyle(color: AppTheme.lightTextColor, fontWeight: FontWeight.bold),
                      ),
                       const Icon(CupertinoIcons.forward, size: 16, color: AppTheme.secondaryTextColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        return Icon(icon, color: AppTheme.goldAccent, size: 16);
      }),
    );
  }

  Widget _buildReputationBadge(String? tier) {
    IconData icon;
    Color color;
    String text = tier ?? 'New Seller';

    // Match the tiers defined in the Edge Function
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _buyNow(Product product) async {
    final buyerId = _supabase.auth.currentUser?.id;
    if (buyerId == null) {
      _showErrorDialog('You must be logged in to purchase an item.');
      return;
    }

    try {
      // We need the buyer's profile ID, not auth user ID.
      // This assumes the profile id is the same as the user id, which should be the case.
      await _supabase.from('purchases').insert({
        'product_id': product.id,
        'buyer_id': buyerId,
        'seller_id': product.userId,
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('تم الشراء بنجاح'),
            content: const Text('تم تسجيل عملية الشراء. يمكنك الآن ترك تقييم للبائع من صفحة مشترياتك.'),
            actions: [CupertinoDialogAction(onPressed: () => Navigator.of(context).pop(), child: const Text('موافق'))],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        // Handle specific error for unique constraint violation
        if (error.toString().contains('duplicate key value violates unique constraint')) {
          _showErrorDialog('لقد قمت بشراء هذا المنتج بالفعل.');
        } else {
          _showErrorDialog('حدث خطأ أثناء عملية الشراء: ${error.toString()}');
        }
      }
    }
  }

  Widget _buildBottomActionBar(Product product, bool isMyProduct) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isMyProduct
              ? CupertinoButton.filled(
                  onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => EditProductScreen(product: product))),
                  child: const Text('تعديل المنتج'),
                )
              : Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () => _startChat(product.userId, product.name),
                        color: AppTheme.darkSurface,
                        child: const Text('مراسلة التاجر', style: TextStyle(color: AppTheme.lightTextColor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () => _buyNow(product),
                        child: const Text('شراء الآن'),
                      ),
                    ),
                  ],
                ),
        ).animate().slideY(begin: 1, duration: 500.ms, delay: 300.ms, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildPriceChip(BuildContext context, Product product) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${product.price} د.ع / ${product.unit_type ?? 'وحدة'}',
        style: theme.textTheme.textStyle.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
