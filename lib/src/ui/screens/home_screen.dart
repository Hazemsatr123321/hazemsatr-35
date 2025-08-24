import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:smart_iraq/src/models/product_request_model.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/widgets/managed_ad_card.dart';
import 'package:smart_iraq/src/ui/widgets/product_card_shimmer.dart';
import 'package:smart_iraq/src/ui/widgets/product_request_card.dart';
import 'package:smart_iraq/src/ui/screens/add_product_screen.dart';
import 'package:smart_iraq/src/models/app_banner_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/screens/create_request_screen.dart';
import 'dart:math';

// Note: The AppBars and FABs are now handled by MainNavigationScreen.
// This screen is now just the body content.

class HomeScreen extends StatefulWidget {
  final ProductRepository productRepository;
  final bool isGuest; // isGuest is kept for potential future use, though currently unused.

  const HomeScreen({
    super.key,
    required this.productRepository,
    this.isGuest = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _feedFuture;
  AppBanner? _banner;
  bool _isBannerLoading = true;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchBanner();
    if (!widget.isGuest) {
      _fetchProfile();
    }
  }

  Future<void> _fetchBanner() async {
    try {
      final data = await supabase.from('app_banners').select().eq('is_active', true).limit(1);
      if (mounted && data.isNotEmpty) {
        setState(() => _banner = AppBanner.fromJson(data.first));
      }
    } catch (e) {
      debugPrint('Could not fetch banner: $e');
    } finally {
      if (mounted) setState(() => _isBannerLoading = false);
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      if (mounted) setState(() => _profile = Profile.fromJson(data));
    } catch (e) {
      debugPrint('Could not fetch profile: $e');
    }
  }

  void _fetchData() {
    setState(() {
      _feedFuture = _getCombinedFeed();
    });
  }

  Future<List<dynamic>> _getCombinedFeed() async {
    final productsFuture = widget.productRepository.getProducts();
    final requestsFuture = supabase.from('product_requests').select().eq('is_active', true);
    final managedAdsFuture = supabase.from('managed_ads').select().eq('is_active', true);

    final results = await Future.wait([productsFuture, requestsFuture, managedAdsFuture]);

    final allProducts = (results[0] as List).map((p) => Product.fromJson(p)).toList();
    final requests = (results[1] as List).map((r) => ProductRequest.fromJson(r)).toList();
    final managedAds = (results[2] as List).map((ad) => ManagedAd.fromJson(ad)).toList();

    final featuredProducts = allProducts.where((p) => p.is_featured).toList();
    final regularProducts = allProducts.where((p) => !p.is_featured).toList();

    List<dynamic> randomList = [...regularProducts, ...requests];
    randomList.shuffle();

    List<dynamic> combinedList = [...featuredProducts, ...randomList];

    if (managedAds.isNotEmpty) {
      final adIndex = min(4, combinedList.length);
      combinedList.insert(adIndex, managedAds.first);
    }
    return combinedList;
  }

  Widget _buildBanner() {
    if (_isBannerLoading || _banner == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: _banner!.backgroundColor,
      child: Text(
        _banner!.message,
        style: TextStyle(color: _banner!.textColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (widget.isGuest || _profile == null) return const SizedBox.shrink();
    if (_profile?.verification_status != 'approved') return const SizedBox.shrink();

    if (_profile!.business_type == 'wholesaler') {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const AddProductScreen())),
        label: const Text('إضافة منتج'),
        icon: const Icon(Icons.add),
      );
    }

    if (_profile!.business_type == 'retailer') {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const CreateRequestScreen())),
        label: const Text('طلب بضاعة'),
        icon: const Icon(CupertinoIcons.add_circled),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold and AppBar are now part of the parent MainNavigationScreen
    return Material( // Add Material widget to provide text styles and other Material dependencies for cards.
      child: Stack(
        children: [
          Column(
            children: [
              _buildBanner(),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _feedFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75,
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) => const ProductCardShimmer(),
                      );
                    }
                    if (snapshot.hasError) return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('لا توجد إعلانات لعرضها حالياً.'));

                    final feedItems = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: () async => _fetchData(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75,
                        ),
                        itemCount: feedItems.length,
                        itemBuilder: (context, index) {
                          final item = feedItems[index];
                          if (item is ManagedAd) return ManagedAdCard(ad: item);
                          if (item is Product) return ProductCard(product: item);
                          if (item is ProductRequest) return ProductRequestCard(request: item);
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _buildFloatingActionButton(context),
            ),
          )
        ],
      ),
    );
  }
}
