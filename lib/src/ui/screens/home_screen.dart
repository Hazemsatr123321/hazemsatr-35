import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart'; // For supabase client
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/widgets/product_card_shimmer.dart';
import 'package:smart_iraq/src/ui/screens/add_product_screen.dart';
import 'package:smart_iraq/src/ui/screens/profile_screen.dart';
import 'package:smart_iraq/src/ui/screens/chat/chat_rooms_screen.dart';
import 'package:smart_iraq/src/repositories/chat_repository.dart';
import 'package:smart_iraq/src/ui/screens/charity_screen.dart';

class HomeScreen extends StatefulWidget {
  final ProductRepository productRepository;

  const HomeScreen({
    super.key,
    required this.productRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _productsFuture;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool? _sortAscending;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    setState(() {
      _productsFuture = widget.productRepository.getProducts(
        query: _searchController.text,
        category: _selectedCategory,
        sortAscending: _sortAscending,
      );
    });
  }

  void _clearSearch() {
     _searchController.clear();
     setState(() {
        _isSearching = false;
     });
     _fetchData();
  }

  void _showFilterSheet() {
    // Local state for the sheet, only applied on button press
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
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      tempCategory = value.isNotEmpty ? value : null;
                    },
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
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
          tooltip: 'بحث',
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterSheet,
          tooltip: 'فلترة',
        ),
        IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ChatRoomsScreen(chatRepository: SupabaseChatRepository()),
              ),
            );
          },
          tooltip: 'محادثاتي',
        ),
        IconButton(
          icon: const Icon(Icons.volunteer_activism),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CharityScreen()),
            );
          },
          tooltip: 'الدعم الخيري',
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          tooltip: 'ملفي الشخصي',
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => supabase.auth.signOut(),
          tooltip: 'تسجيل الخروج',
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _clearSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'ابحث عن منتج...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        onSubmitted: (query) => _fetchData(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _searchController.clear(),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.7,
              ),
              itemCount: 6, // Show 6 shimmer cards while loading
              itemBuilder: (context, index) => const ProductCardShimmer(),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد إعلانات لعرضها حالياً.'));
          }

          final products = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.7, // Adjust this ratio to fit your card's new design
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة إعلان جديد',
      ),
    );
  }
}
