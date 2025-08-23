import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:smart_iraq/src/models/product_request_model.dart'; // New
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/widgets/managed_ad_card.dart';
import 'package:smart_iraq/src/ui/widgets/product_card_shimmer.dart';
import 'package:smart_iraq/src/ui/widgets/product_request_card.dart'; // New
import 'package:smart_iraq/src/ui/screens/add_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile_screen.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_rooms_screen.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/charity_screen.dart';
import 'package:smart_iraq/src/models/app_banner_model.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/screens/create_request_screen.dart';
import 'package:smart_iraq/src/ui/screens/smart_assistant_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  final ProductRepository productRepository;
  final bool isGuest;

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
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool? _sortAscending;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanner() async {
    // ... (existing code)
    try {
      final data = await supabase
          .from('app_banners')
          .select()
          .eq('is_active', true)
          .limit(1);
      if (data.isNotEmpty) {
        setState(() {
          _banner = AppBanner.fromJson(data.first);
          _isBannerLoading = false;
        });
      } else {
        setState(() {
          _isBannerLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Could not fetch banner: $e');
      setState(() {
        _isBannerLoading = false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    // ... (existing code)
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      setState(() {
        _profile = Profile.fromJson(data);
      });
    } catch (e) {
      debugPrint('Could not fetch profile: $e');
    }
  }

  Future<List<ManagedAd>> _getManagedAds() async {
    // ... (existing code)
    try {
      final data = await supabase.from('managed_ads').select().eq('is_active', true);
      return (data as List).map((json) => ManagedAd.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Could not fetch managed ads: $e');
      return [];
    }
  }

  void _fetchData() {
    setState(() {
      _feedFuture = _getCombinedFeed();
    });
  }

  Future<List<dynamic>> _getCombinedFeed() async {
    final productsFuture = widget.productRepository.getProducts(
      query: _searchController.text,
      category: _selectedCategory,
      sortAscending: _sortAscending,
    );
    final requestsFuture = supabase.from('product_requests').select().eq('is_active', true);
    final managedAdsFuture = _getManagedAds();

    final results = await Future.wait([productsFuture, requestsFuture, managedAdsFuture]);

    final products = results[0] as List<Product>;
    final requestsData = results[1] as List;
    final managedAds = results[2] as List<ManagedAd>;

    final requests = requestsData.map((json) => ProductRequest.fromJson(json)).toList();

    List<dynamic> combinedList = [...products, ...requests];
    combinedList.shuffle(); // Shuffle products and requests together

    if (managedAds.isNotEmpty) {
      final adIndex = min(4, combinedList.length);
      combinedList.insert(adIndex, managedAds.first);
    }
    return combinedList;
  }

  void _clearSearch() {
     _searchController.clear();
     setState(() { _isSearching = false; });
     _fetchData();
  }

  void _showFilterSheet() {
    // ... (existing code)
  }

  AppBar _buildNormalAppBar() {
    // ... (existing code)
     return AppBar(
      title: const Text('السوق - العراق الذكي'),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet),
        if (!widget.isGuest)
          IconButton(icon: const Icon(Icons.smart_toy_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SmartAssistantScreen()))),
        if (!widget.isGuest)
          IconButton(icon: const Icon(Icons.chat), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatRoomsScreen(chatRepository: SupabaseChatRepository())))),
        IconButton(icon: const Icon(Icons.volunteer_activism), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CharityScreen()))),
        if (!widget.isGuest)
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()))),
        if (!widget.isGuest)
          IconButton(icon: const Icon(Icons.logout), onPressed: () => supabase.auth.signOut()),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    // ... (existing code)
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _clearSearch),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'ابحث عن منتج...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white70)),
        style: const TextStyle(color: Colors.white),
        onSubmitted: (query) => _fetchData(),
      ),
      actions: [IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())],
    );
  }

  Widget _buildBanner() {
    // ... (existing code)
    if (_isBannerLoading || _banner == null) {
      return const SizedBox.shrink();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          _buildBanner(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _feedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.7,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) => const ProductCardShimmer(),
                  );
                }
                if (snapshot.hasError) return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('لا توجد إعلانات لعرضها حالياً.'));

                final feedItems = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.7,
                  ),
                  itemCount: feedItems.length,
                  itemBuilder: (context, index) {
                    final item = feedItems[index];
                    if (item is ManagedAd) return ManagedAdCard(ad: item);
                    if (item is Product) return ProductCard(product: item);
                    if (item is ProductRequest) return ProductRequestCard(request: item);
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (widget.isGuest || _profile == null) {
      return null;
    }
    if (_profile?.verification_status != 'approved') return null;

    if (_profile!.business_type == 'wholesaler') {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddProductScreen())),
        label: const Text('إضافة منتج'),
        icon: const Icon(Icons.add),
      );
    }

    if (_profile!.business_type == 'retailer') {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateRequestScreen())),
        label: const Text('طلب بضاعة'),
        icon: const Icon(Icons.add_shopping_cart),
      );
    }

    return null;
  }
}
