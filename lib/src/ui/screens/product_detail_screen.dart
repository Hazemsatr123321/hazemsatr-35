import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
      await supabase.rpc('increment_view_count', params: {'product_id': widget.productId});
    } catch (e) {
      debugPrint('Could not increment view count: $e');
    }

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

  void _showAnalyticsModal(Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تحليلات الإعلان', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              _buildStatRow(
                context,
                icon: Icons.visibility_outlined,
                label: 'عدد المشاهدات',
                value: '${product.viewCount ?? 0}',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                context,
                icon: Icons.message_outlined,
                label: 'عدد الرسائل',
                value: '${product.messageCount ?? 0}',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 16),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Future<void> _startChat(String sellerId) async {
    try {
      final roomId = await _chatRepository.findOrCreateChatRoom(sellerId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              roomId: roomId,
              chatRepository: _chatRepository,
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
    final currentUserId = supabase.auth.currentUser?.id;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final priceFormat = NumberFormat.currency(locale: 'ar_IQ', symbol: 'د.ع', decimalDigits: 0);

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
          final isMyProduct = product.userId == currentUserId;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product-image-${product.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(product.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        priceFormat.format(product.price),
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      if (product.category != null)
                        Row(
                          children: [
                             Icon(Icons.category_outlined, size: 18, color: Colors.grey[700]),
                             const SizedBox(width: 8),
                             Text(product.category!, style: textTheme.bodyLarge),
                          ],
                        ),
                      const SizedBox(height: 24.0),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16.0),
                      Text('الوصف', style: textTheme.titleLarge),
                      const SizedBox(height: 12.0),
                      Text(
                        product.description ?? 'لا يوجد وصف متاح لهذا المنتج.',
                        style: textTheme.bodyLarge?.copyWith(height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
       bottomNavigationBar: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
           final product = snapshot.data!;
           final isMyProduct = product.userId == currentUserId;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isMyProduct
                ? ElevatedButton.icon(
                    onPressed: () => _showAnalyticsModal(product),
                    icon: const Icon(Icons.bar_chart_outlined),
                    label: const Text('عرض تحليلات الإعلان'),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _startChat(product.userId),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('مراسلة البائع'),
                  ),
            ),
          );
        },
      ),
    );
  }
}
