import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
import 'package:smart_iraq/src/ui/screens/edit_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/leave_review_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Future<Product> _productFuture;
  final ChatRepository _chatRepository = SupabaseChatRepository();

  @override
  void initState() {
    super.initState();
    _productFuture = _getProduct();
  }

  Future<Product> _getProduct() async {
    try {
      final data = await supabase
          .from('products')
          .select()
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
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
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
       if (mounted) {
        _showErrorDialog('حدث خطأ أثناء بدء المحادثة.');
      }
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

          return CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(product.name),
                stretch: true,
                background: Hero(
                  tag: 'product-image-${product.id}',
                  child: product.imageUrl != null
                  ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    color: CupertinoColors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(CupertinoIcons.photo, size: 100, color: CupertinoColors.systemGrey)),
                  )
                  : Container(color: CupertinoColors.systemGrey, child: const Center(child: Icon(CupertinoIcons.photo, size: 100, color: CupertinoColors.white))),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPriceChip(context, product),
                          const SizedBox(height: 24.0),
                          _buildSectionTitle(context, 'تفاصيل الجملة'),
                          const SizedBox(height: 12.0),
                          _buildB2BInfoGrid(context, product),
                          const SizedBox(height: 24.0),
                          _buildSectionTitle(context, 'الوصف'),
                          const SizedBox(height: 12.0),
                          Text(
                            product.description ?? 'لا يوجد وصف متاح لهذا المنتج.',
                            style: CupertinoTheme.of(context).textTheme.body.copyWith(height: 1.6, color: CupertinoColors.label),
                          ),
                        ].animate(interval: 100.ms).fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                      ),
                    ),
                  ]),
              ),
            ],
          );
        },
      ),
       bottomNavigationBar: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
           final product = snapshot.data!;
           final isMyProduct = product.userId == supabase.auth.currentUser?.id;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isMyProduct
                ? CupertinoButton.filled(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        CupertinoPageRoute(builder: (context) => EditProductScreen(product: product))
                      );
                    },
                    child: const Text('تعديل المنتج'),
                  )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoButton.filled(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _startChat(product.userId, product.name);
                      },
                      child: const Text('مراسلة التاجر'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                         Navigator.of(context).push(
                          CupertinoPageRoute(builder: (context) => LeaveReviewScreen(revieweeId: product.userId)),
                        );
                      },
                      child: const Text('أو أضف تقييمًا لهذا التاجر'),
                    )
                  ],
                ),
            ).animate().slideY(begin: 1, duration: 500.ms, delay: 300.ms, curve: Curves.easeOut),
          );
        },
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(CupertinoIcons.tag_solid, color: theme.primaryColor),
           const SizedBox(width: 8),
           Text(
            '${product.price} د.ع / ${product.unit_type ?? 'وحدة'}',
            style: theme.textTheme.textStyle.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildB2BInfoGrid(BuildContext context, Product product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth / 2) - 8;
        return Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildInfoCard(context, CupertinoIcons.cube_box, 'الكمية المتوفرة', '${product.stock_quantity ?? 0}')
            ),
            SizedBox(
              width: itemWidth,
              child: _buildInfoCard(context, CupertinoIcons.shopping_cart, 'أقل كمية للطلب', '${product.minimum_order_quantity ?? 1}')
            ),
          ],
        );
      }
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border.all(color: CupertinoColors.systemGrey5.resolveFrom(context)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.footnote.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          Text(value, style: theme.textTheme.headline.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
