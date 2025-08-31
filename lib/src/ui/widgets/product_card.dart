import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showControls;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ProductCard({
    super.key,
    required this.product,
    this.showControls = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final priceFormat = NumberFormat.currency(
      locale: 'ar_IQ',
      symbol: 'د.ع',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Row(
          children: [
            // --- Image Section ---
            SizedBox(
              width: 120,
              height: 130,
              child: Hero(
                tag: 'product-image-${product.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    bottomLeft: Radius.circular(12.0),
                  ),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      );
                    },
                  ),
                ),
              ),
            ),
            // --- Text Content Section ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      priceFormat.format(product.price),
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    if (product.category != null)
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.category!,
                              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // --- Controls Section ---
            if (showControls)
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: colorScheme.secondary),
                      onPressed: onEdit,
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
                      onPressed: onDelete,
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
