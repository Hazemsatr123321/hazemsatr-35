import 'package:smart_iraq/src/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_iraq/src/ui/widgets/filter_modal.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    String? query,
    FilterOptions? filters,
  });
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _supabase;

  SupabaseProductRepository(this._supabase);

  @override
  Future<List<Product>> getProducts({
    String? query,
    FilterOptions? filters,
  }) async {
    try {
      dynamic request = _supabase.from('products').select();

      if (query != null && query.isNotEmpty) {
        request = request.or('name.ilike.%$query%,description.ilike.%$query%');
      }

      if (filters != null) {
        if (filters.category != null && filters.category!.isNotEmpty) {
          request = request.eq('category', filters.category);
        }
        if (filters.condition != null && filters.condition!.isNotEmpty) {
          request = request.eq('condition', filters.condition);
        }
        if (filters.sortBy != null && filters.sortBy!.isNotEmpty) {
          request = request.order(
            filters.sortBy!,
            ascending: filters.sortAscending ?? false,
          );
        }
      }

      // Add a secondary sort by creation date to ensure consistent ordering, unless already sorting by it
      if (filters?.sortBy != 'created_at') {
        request = request.order('created_at', ascending: false);
      }

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
