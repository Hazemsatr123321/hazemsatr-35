import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/models/review_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  const SellerProfileScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  _SellerProfileScreenState createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late Future<Profile> _profileFuture;
  late Future<List<Product>> _productsFuture;
  late Future<List<Review>> _reviewsFuture;
  late SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _profileFuture = _getProfile();
    _productsFuture = _getProducts();
    _reviewsFuture = _getReviews();
  }

  Future<Profile> _getProfile() async {
    final data = await _supabase.from('profiles').select().eq('id', widget.sellerId).single();
    return Profile.fromJson(data);
  }

  Future<List<Product>> _getProducts() async {
    final data = await _supabase.from('products').select().eq('user_id', widget.sellerId).order('created_at', ascending: false);
    return (data as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Review>> _getReviews() async {
    final data = await _supabase.from('reviews').select('*, buyer:buyer_id(*)').eq('seller_id', widget.sellerId).order('created_at', ascending: false);
    return (data as List).map((json) => Review.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) return const CustomLoadingIndicator();
          if (profileSnapshot.hasError || !profileSnapshot.hasData) {
            return Center(child: Text('Could not load seller profile: ${profileSnapshot.error}'));
          }

          final profile = profileSnapshot.data!;

          return CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(profile.business_name ?? 'Seller Profile'),
              ),
              SliverToBoxAdapter(child: _buildBusinessInfoSection(profile)),
              _buildSectionHeader('Reviews'),
              _buildReviewsList(),
              _buildSectionHeader('Other items from this seller'),
              _buildProductGrid(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBusinessInfoSection(Profile profile) {
    // This can be expanded with more details from the profile model
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
              Text('Seller Information', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
              _buildReputationBadge(profile.seller_tier),
            ],
          ),
          const SizedBox(height: 12),
          _buildRatingSection(profile.reputation_score ?? 0, _reviewsFuture),
        ],
      ),
    );
  }

  Widget _buildReputationBadge(String? tier) {
    // Re-using the same badge logic
    return Container(); // Placeholder
  }

  Widget _buildRatingSection(double avgRating, Future<List<Review>> reviewsFuture) {
    return FutureBuilder<List<Review>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        final reviewCount = snapshot.data?.length ?? 0;
        return Row(
          children: [
            _buildStarRating(avgRating),
            const SizedBox(width: 8),
            Text(
              '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.lightTextColor),
            ),
          ],
        );
      },
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
        return Icon(icon, color: AppTheme.goldAccent, size: 20);
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title, style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
      ),
    );
  }

  Widget _buildReviewsList() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: CustomLoadingIndicator());
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error loading reviews: ${snapshot.error}')));
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No reviews yet.'))));
        }
        final reviews = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final review = reviews[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(review.buyer?.business_name ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.lightTextColor)),
                        _buildStarRating(review.rating.toDouble()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(review.comment ?? '', style: const TextStyle(color: AppTheme.secondaryTextColor)),
                  ],
                ),
              );
            },
            childCount: reviews.length,
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: CustomLoadingIndicator());
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error loading products: ${snapshot.error}')));
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No other products from this seller.'))));
        }
        final products = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(product: product).animate().fadeIn();
            }, childCount: products.length),
          ),
        );
      },
    );
  }
}
