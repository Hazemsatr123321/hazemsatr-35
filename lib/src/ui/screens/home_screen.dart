import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/widgets/managed_ad_card.dart';
import 'package:smart_iraq/src/ui/widgets/product_card_shimmer.dart';
import 'package:smart_iraq/src/ui/screens/add_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile_screen.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_rooms_screen.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/charity_screen.dart';
import 'package:smart_iraq/src/models/app_banner_model.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchBanner();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanner() async {
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

  Future<List<ManagedAd>> _getManagedAds() async {
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
    final managedAdsFuture = _getManagedAds();

    final results = await Future.wait([productsFuture, managedAdsFuture]);
    final products = results[0] as List<Product>;
    final managedAds = results[1] as List<ManagedAd>;

    List<dynamic> combinedList = List.from(products);
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
    String? tempCategory = _selectedCategory;
    bool? tempSort = _sortAscending;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الفلترة والفرز', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: tempCategory,
                      decoration: const InputDecoration(labelText: 'الفئة'),
                      onChanged: (value) => tempCategory = value.isNotEmpty ? value : null,
                    ),
                    const SizedBox(height: 16),
                    Text('الفرز حسب السعر', style: Theme.of(context).textTheme.titleMedium),
                    RadioListTile<bool?>(
                      title: const Text('من الأقل إلى الأعلى'),
                      value: true,
                      groupValue: tempSort,
                      onChanged: (value) => setModalState(() => tempSort = value),
                    ),
                    RadioListTile<bool?>(
                      title: const Text('من الأعلى إلى الأقل'),
                      value: false,
                      groupValue: tempSort,
                      onChanged: (value) => setModalState(() => tempSort = value),
                    ),
                    RadioListTile<bool?>(
                      title: const Text('بدون فرز'),
                      value: null,
                      groupValue: tempSort,
                      onChanged: (value) => setModalState(() => tempSort = value),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCategory;
                          _sortAscending = tempSort;
                        });
                        _fetchData();
                        Navigator.of(context).pop();
                      },
                      child: const Text('تطبيق'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppBar _buildNormalAppBar() {
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
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddProductScreen())),
              child: const Icon(Icons.add),
            ),
    );
  }
}
