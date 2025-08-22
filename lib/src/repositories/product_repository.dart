import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? query});
}

class SupabaseProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({String? query}) async {
    try {
      var request = supabase.from('products').select();

      if (query != null && query.isNotEmpty) {
        request = request.ilike('title', '%$query%');
      }

      final data = await request.order('created_at', ascending: false);
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
