import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/screens/review/leave_review_screen.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({Key? key}) : super(key: key);

  @override
  _MyPurchasesScreenState createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  late Future<List<Product>> _purchasesFuture;
  late final SupabaseClient _supabase;
  final Set<int> _reviewedProductIds = {};
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadData();
  }

  Future<void> _loadData() async {
    _purchasesFuture = _fetchPurchases();
    await _fetchReviewedProducts();
  }

  Future<void> _fetchReviewedProducts() async {
    setState(() {
      _isLoadingReviews = true;
    });
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _supabase.from('reviews').select('product_id').eq('buyer_id', userId);

    if (mounted) {
      setState(() {
        _reviewedProductIds.clear();
        for (final review in response) {
          if (review['product_id'] != null) {
            _reviewedProductIds.add(review['product_id']);
          }
        }
        _isLoadingReviews = false;
      });
    }
  }

  Future<List<Product>> _fetchPurchases() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw 'User not logged in';
    }

    // Join purchases with products to get product details
    final response = await _supabase
        .from('purchases')
        .select('*, products(*)')
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    // The result from the join is a list of purchases, each with a nested product object.
    // We need to extract the product from each purchase record.
    final products = response.map((purchase) {
      return Product.fromJson(purchase['products']);
    }).toList();

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('مشترياتي'),
      ),
      child: FutureBuilder<List<Product>>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لم تقم بشراء أي منتجات بعد.',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            );
          }

          final purchases = snapshot.data!;

          if (_isLoadingReviews) {
            return const CustomLoadingIndicator();
          }

          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final product = purchases[index];
              final hasReviewed = _reviewedProductIds.contains(product.id);

              return CupertinoListTile(
                leading: product.imageUrl != null
                    ? Image.network(product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: AppTheme.darkSurface),
                title: Text(product.name, style: const TextStyle(color: AppTheme.lightTextColor)),
                subtitle: Text('${product.price} د.ع', style: const TextStyle(color: AppTheme.secondaryTextColor)),
                trailing: hasReviewed
                    ? const Text('تم التقييم', style: TextStyle(color: AppTheme.goldAccent, fontSize: 12))
                    : CupertinoButton(
                        child: const Text('تقييم المنتج'),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            CupertinoPageRoute(builder: (context) => LeaveReviewScreen(product: product)),
                          );
                          // Refresh the reviewed status after returning from the review screen
                          _fetchReviewedProducts();
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

// A simple CupertinoListTile to make the code cleaner. Can be expanded later.
class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.darkSurface)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16.0),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
