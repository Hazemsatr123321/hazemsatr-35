import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool? sortAscending,
  });
}

class SupabaseProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool? sortAscending,
  }) async {
    try {
      dynamic request = supabase.from('products').select();

      if (query != null && query.isNotEmpty) {
        request = request.ilike('title', '%$query%');
      }

      if (category != null && category.isNotEmpty) {
        request = request.eq('category', category);
      }

      if (sortAscending != null) {
        request = request.order('price', ascending: sortAscending);
      }

      // Add a secondary sort by creation date to ensure consistent ordering
      request = request.order('created_at', ascending: false);

      final data = await request;
      final products = (data as List).map((json) {
        return Product.fromJson(json);
      }).toList();
      return products;
    } catch (error) {
      // In a real app, log this error to a service
      rethrow;
    }
  }
}
