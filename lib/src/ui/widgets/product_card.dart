import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/screens/product_detail_screen.dart';
import 'package:smart_iraq/src/ui/screens/auction/auction_detail_screen.dart';
import 'dart:ui';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showControls;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onFeature;

  const ProductCard({
    super.key,
    required this.product,
    this.showControls = false,
    this.onDelete,
    this.onEdit,
    this.onFeature,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAuction = product.listing_type == 'auction';
    final theme = CupertinoTheme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => isAuction
                ? AuctionDetailScreen(product: product)
                : ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Stack(
          children: [
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
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceTag(theme, isAuction),
                  _buildTitleAndCategory(theme),
                ],
              ),
            ),
            if (showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTag(CupertinoThemeData theme, bool isAuction) {
    String text;
    Color color;
    IconData? icon;

    if (isAuction) {
      text = '${product.highest_bid ?? product.start_price} د.ع';
      color = AppTheme.goldAccent;
      icon = CupertinoIcons.gavel;
    } else {
      text = '${product.price} د.ع';
      color = theme.primaryColor;
      icon = null;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 4)],
              Text(text, style: theme.textTheme.textStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndCategory(CupertinoThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: theme.textTheme.navTitleTextStyle.copyWith(color: Colors.white, shadows: [const Shadow(blurRadius: 2, color: Colors.black87)]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (product.category != null) ...[
          const SizedBox(height: 4.0),
          Text(
            product.category!,
            style: theme.textTheme.textStyle.copyWith(fontSize: 14, color: Colors.white.withOpacity(0.9), shadows: [const Shadow(blurRadius: 1, color: Colors.black54)]),
          ),
        ],
      ],
    );
  }

  Widget _buildControls() {
    final isFeatured = product.is_featured;
    return Positioned(
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.pencil, size: 18), SizedBox(width: 4), Text('تعديل')]),
                  onPressed: onEdit,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onFeature,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.star_fill, size: 18, color: isFeatured ? CupertinoColors.systemGrey : AppTheme.goldAccent),
                      const SizedBox(width: 4),
                      Text('تمييز', style: TextStyle(color: isFeatured ? CupertinoColors.systemGrey : AppTheme.goldAccent)),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.delete, size: 18, color: CupertinoColors.destructiveRed), SizedBox(width: 4), Text('حذف')]),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.darkSurface,
      child: const Icon(CupertinoIcons.photo, color: AppTheme.secondaryTextColor, size: 50),
    );
  }
}
