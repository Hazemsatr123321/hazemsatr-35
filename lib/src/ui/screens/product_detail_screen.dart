import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء بدء المحادثة.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('productDetailScreen'),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)])
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  background: Hero(
                    tag: 'product-image-${product.id}',
                    child: product.imageUrl != null
                    ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 100, color: Colors.grey)),
                    )
                    : Container(color: Colors.grey, child: const Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.white))),
                  ),
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Colors.black87),
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
                ? ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // TODO: Navigate to Edit Product Screen
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل المنتج'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      backgroundColor: Theme.of(context).colorScheme.secondary
                    ),
                  )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _startChat(product.userId, product.name);
                      },
                      icon: const Icon(CupertinoIcons.chat_bubble_2_fill),
                      label: const Text('مراسلة التاجر'),
                       style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
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
    return Chip(
      avatar: Icon(Icons.sell, color: Theme.of(context).colorScheme.primary),
      label: Text(
        '${product.price} د.ع / ${product.unit_type ?? 'وحدة'}',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildB2BInfoGrid(BuildContext context, Product product) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildInfoCard(context, Icons.inventory_2_outlined, 'الكمية المتوفرة', '${product.stock_quantity ?? 0}'),
        _buildInfoCard(context, Icons.production_quantity_limits, 'أقل كمية للطلب', '${product.minimum_order_quantity ?? 1}'),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
