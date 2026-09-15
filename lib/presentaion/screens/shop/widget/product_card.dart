import 'package:booking/presentaion/screens/shop/product_detail.dart';
import 'package:flutter/material.dart';

import 'package:booking/data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double? cardWidth;

  const ProductCard({super.key, required this.product, this.cardWidth});

  void _goToProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.productId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locationLabel = product.location?.district;

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _goToProduct(context),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Image + delivery badge ───────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        product.thumbnailUrl.isNotEmpty
                            ? product.thumbnailUrl
                            : (product.images.isNotEmpty
                                  ? product.images.first
                                  : ''),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: colors.surfaceContainerHighest),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return ColoredBox(
                            color: colors.surfaceContainerHighest,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (product.isDelivery)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E9E5B).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ─── Name ─────────────────────────────────────────
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),

              // ─── Price ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${product.currency} ${_formatPrice(product.price)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),

              // ─── Location meta ────────────────────────────────
              if (locationLabel != null && locationLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 11,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Constrain width when an explicit cardWidth is provided
    // (e.g. the horizontal trending row). In grids the parent sizes us.
    return cardWidth != null ? SizedBox(width: cardWidth, child: card) : card;
  }

  String _formatPrice(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final intPart = abs.truncate(); // int, not double
    final hasFraction = abs - intPart > 0;

    // Digit grouping on the integer part.
    final digits = intPart.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }

    final sign = isNegative ? '-' : '';
    if (!hasFraction) return '$sign$buf';

    final decimals = ((abs - intPart) * 100).round().toString().padLeft(2, '0');
    return '$sign$buf.$decimals';
  }
}
