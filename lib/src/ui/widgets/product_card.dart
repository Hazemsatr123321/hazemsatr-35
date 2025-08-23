import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/screens/product_detail_screen.dart';
import 'dart:ui';

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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ProductDetailScreen(productId: product.id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // --- Background Image ---
            Positioned.fill(
              child: Hero(
                tag: 'product-image-${product.id}',
                child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            // --- Gradient Overlay ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // --- Content ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Top right price tag
                  Align(
                    alignment: Alignment.topLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                             color: colorScheme.primary.withOpacity(0.7),
                             borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            '${product.price} د.ع',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom left details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: textTheme.titleLarge?.copyWith(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, shadows: [const Shadow(blurRadius: 2, color: Colors.black87)]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.category != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          product.category!,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9), shadows: [const Shadow(blurRadius: 1, color: Colors.black54)]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
             // --- Controls Section ---
            if (showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                            label: const Text('تعديل', style: TextStyle(color: Colors.white)),
                            onPressed: onEdit,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            label: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 50),
    );
  }
}
