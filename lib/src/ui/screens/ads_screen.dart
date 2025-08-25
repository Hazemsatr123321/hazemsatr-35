import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/screens/rfq/browse_rfqs_screen.dart';
import 'package:smart_iraq/src/ui/screens/rfq/create_rfq_screen.dart';
import 'package:smart_iraq/src/ui/widgets/filter_modal.dart';
import 'package:smart_iraq/src/ui/widgets/notification_icon.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const NotificationIcon(),
        middle: CupertinoSegmentedControl<int>(
          groupValue: _selectedSegment,
          onValueChanged: (int newValue) {
            setState(() {
              _selectedSegment = newValue;
            });
          },
          children: const {
            0: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('الإعلانات')),
            1: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('الطلبات')),
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const CreateRfqScreen()),
            );
          },
        ),
      ),
      child: _selectedSegment == 0 ? const ProductGrid() : const BrowseRfqsScreen(),
    );
  }
}

class ProductGrid extends StatefulWidget {
  const ProductGrid({super.key});

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  FilterOptions _filterOptions = FilterOptions();
  Future<List<Product>>? _productsFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial fetch
    if (_productsFuture == null) {
      _fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text != _searchQuery) {
      setState(() {
        _searchQuery = _searchController.text;
        _fetchProducts();
      });
    }
  }

  void _fetchProducts() {
    final productRepository = context.read<ProductRepository>();
    setState(() {
      _productsFuture = productRepository.getProducts(
        query: _searchQuery,
        filters: _filterOptions,
      );
    });
  }

  void _showFilterModal() async {
    final newFilters = await showCupertinoModalPopup<FilterOptions>(
      context: context,
      builder: (context) => FilterModal(initialFilters: _filterOptions),
    );

    if (newFilters != null) {
      setState(() {
        _filterOptions = newFilters;
        _fetchProducts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'ابحث عن منتج...',
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: const Icon(CupertinoIcons.slider_horizontal_3),
                onPressed: _showFilterModal,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CustomLoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد إعلانات تطابق بحثك.'));
              }

              final products = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(12.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: products[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
