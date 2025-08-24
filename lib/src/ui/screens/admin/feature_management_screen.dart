import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/product_model.dart';

class FeatureManagementScreen extends StatefulWidget {
  const FeatureManagementScreen({super.key});

  @override
  State<FeatureManagementScreen> createState() => _FeatureManagementScreenState();
}

class _FeatureManagementScreenState extends State<FeatureManagementScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      final data = await supabase.from('products').select().order('created_at', ascending: false);
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching products for admin: $e');
      rethrow;
    }
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _fetchProducts();
    });
  }

  Future<void> _updateFeatureStatus(String productId, bool newStatus) async {
    try {
      await supabase.from('products').update({'is_featured': newStatus}).eq('id', productId);
      // No need for a snackbar here to keep the UI clean, the switch provides immediate feedback.
      // We will refetch to ensure the state is consistent.
      _refreshProducts();
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث المنتج: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('تمييز الإعلانات'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _refreshProducts,
        ),
      ),
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المنتجات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد منتجات لعرضها.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Material(
                child: ListTile(
                  leading: product.imageUrl != null
                    ? Image.network(product.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(CupertinoIcons.photo)),
                  title: Text(product.name),
                  subtitle: Text('بواسطة: ${product.userId.substring(0, 8)}...'),
                  trailing: CupertinoSwitch(
                    value: product.is_featured,
                    onChanged: (value) {
                      _updateFeatureStatus(product.id, value);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
