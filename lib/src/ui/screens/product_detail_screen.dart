import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                expandedHeight: 300.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    product.title,
                    style: const TextStyle(fontSize: 16.0, shadows: [Shadow(blurRadius: 2.0)])
                  ),
                  background: Hero(
                    tag: 'product-image-${product.id}',
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${product.price} د.ع',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    if (product.category != null) ...[
                      const SizedBox(height: 8.0),
                      Chip(
                        label: Text(product.category!),
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                    const SizedBox(height: 16.0),
                    const Divider(),
                    const SizedBox(height: 16.0),
                    Text(
                      'الوصف',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      product.description ?? 'لا يوجد وصف متاح لهذا المنتج.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24.0),
                  ]),
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
            return const SizedBox.shrink(); // Show nothing if product hasn't loaded
          }
           final product = snapshot.data!;
           final isMyProduct = product.userId == currentUserId;
           if (isMyProduct) {
             return const SizedBox.shrink(); // Don't show button for own product
           }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _startChat(product.userId),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('مراسلة البائع'),
            ),
          );
        },
      ),
    );
  }
}
