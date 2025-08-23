import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/product_request_model.dart';

class ProductRequestCard extends StatelessWidget {
  final ProductRequest request;

  const ProductRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.secondary.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  Icon(Icons.search, color: colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text("مطلوب", style: textTheme.bodyLarge?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    request.requestedProductName,
                    style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (request.description != null && request.description!.isNotEmpty)
                    Text(
                      request.description!,
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              // Footer
              Align(
                alignment: Alignment.bottomCenter,
                child: Chip(
                  backgroundColor: colorScheme.secondary.withOpacity(0.2),
                  label: Text(
                    'الكمية: ${request.quantityNeeded ?? 'غير محددة'}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
