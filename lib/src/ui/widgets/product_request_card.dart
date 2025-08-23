import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/product_request_model.dart';

class ProductRequestCard extends StatelessWidget {
  final ProductRequest request;

  const ProductRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: colorScheme.secondary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.help_outline, color: colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text("مطلوب", style: textTheme.bodyLarge?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
              ],
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requestedProductName,
                  style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (request.description != null)
                  Text(
                    request.description!,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            // Footer
            Text(
              'الكمية: ${request.quantityNeeded ?? 'غير محدد'}',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
