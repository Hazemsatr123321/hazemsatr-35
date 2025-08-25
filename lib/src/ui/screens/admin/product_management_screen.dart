import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart' as custom;
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late Future<List<Product>> _productsFuture;
  late SupabaseClient _supabase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      final data = await _supabase.from('products').select().order('created_at', ascending: false);
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all products: $e');
      rethrow;
    }
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _fetchProducts();
    });
  }

  Future<void> _deleteProduct(String productId) async {
    final shouldDelete = await showCupertinoDialog<bool>(
        context: context,
        builder: (c) => CupertinoAlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنتج نهائياً؟'),
              actions: [
                CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(false), child: const Text('إلغاء')),
                CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(true), isDestructiveAction: true, child: const Text('حذف')),
              ],
            ));
    if (shouldDelete == true) {
      try {
        await _supabase.from('products').delete().eq('id', productId);
        if (mounted) {
          final snackBar = SnackBar(content: Text('تم حذف المنتج بنجاح'), backgroundColor: CupertinoColors.activeGreen);
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        _refreshProducts();
      } catch (e) {
        if (mounted) {
          final snackBar = SnackBar(content: Text('خطأ في حذف المنتج: $e'), backgroundColor: CupertinoColors.destructiveRed);
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('إدارة كل المنتجات'),
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
            return const CustomLoadingIndicator();
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
              return custom.CupertinoListTile(
                title: Text(product.name),
                subtitle: Text('بواسطة: ${product.userId}'),
                leading: product.imageUrl != null
                    ? Image.network(product.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                    : Container(width: 56, height: 56, color: CupertinoColors.systemGrey5),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed),
                  onPressed: () => _deleteProduct(product.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
